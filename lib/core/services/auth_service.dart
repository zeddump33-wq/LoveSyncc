import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import '../utils/encryption_utils.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class AuthService {
  static UserModel? _currentUser;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static UserModel? get currentUser => _currentUser;
  static String? get firebaseUid => _auth.currentUser?.uid;

  static void _saveUserToStorage() {
    if (_currentUser == null) return;
    StorageService.setString('user_json', jsonEncode(_currentUser!.toMap()));
  }

  static UserModel? _loadUserFromStorage() {
    final json = StorageService.getString('user_json');
    if (json == null) return null;
    return UserModel.fromMap(jsonDecode(json));
  }

  static Future<void> _storeCurrentUser(UserModel user) async {
    _currentUser = user;
    await DatabaseService.insert('users', user.toMap());
    await StorageService.setString('current_user_id', user.id);
    _saveUserToStorage();
  }

  static Future<void> _createOrRefreshCouple(String userId, String now) async {
    final coupleId = EncryptionUtils.generateId();
    final inviteCode = EncryptionUtils.generateInviteCode();
    final anniversary = DateTime.now().toIso8601String().split('T')[0];
    final coupleData = {
      'id': coupleId,
      'partner1Id': userId,
      'partner2Id': null,
      'anniversaryDate': anniversary,
      'status': 'solo',
      'inviteCode': inviteCode,
      'createdAt': now,
      'updatedAt': now,
    };

    try {
      await FirestoreService.createCouple(coupleId, coupleData);
    } catch (e) {
      print('Firestore createCouple failed: $e');
    }

    await DatabaseService.insert('couples', coupleData);
    await DatabaseService.update('users', {
      'coupleId': coupleId,
      'inviteCode': inviteCode,
      'updatedAt': now,
    }, userId);

    try {
      await FirestoreService.updateUser(userId, {
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'partner1Id': userId,
        'anniversaryDate': anniversary,
        'coupleStatus': 'solo',
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e) {
      print('Firestore updateUser in _createOrRefreshCouple failed: $e');
    }

    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        photoPath: _currentUser!.photoPath,
        partnerId: _currentUser!.partnerId,
        coupleId: coupleId,
        inviteCode: inviteCode,
        createdAt: _currentUser!.createdAt,
        updatedAt: now,
      );
      _saveUserToStorage();
    }
  }

  static Future<bool> createLocalAccount(String name) async {
    try {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        print('Anonymous auth failed (non-fatal): $e');
      }

      final existingId = StorageService.getString('current_user_id');
      if (existingId != null) {
        final existing = await DatabaseService.getById('users', existingId);
        if (existing != null) {
          _currentUser = UserModel.fromMap(existing);
          _saveUserToStorage();
          return true;
        }
      }

      final id = _auth.currentUser?.uid ?? EncryptionUtils.generateId();
      final now = DateTime.now().toIso8601String();
      final user = UserModel(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      await _storeCurrentUser(user);
      await _createOrRefreshCouple(id, now);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> registerWithEmail(String name, String email, String password) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return false;

      final now = DateTime.now().toIso8601String();
      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: normalizedEmail,
        photoPath: firebaseUser.photoURL,
        createdAt: now,
        updatedAt: now,
      );

      await FirestoreService.createUser(user.id, user.toMap());
      await _storeCurrentUser(user);
      await _createOrRefreshCouple(user.id, now);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> loginWithEmail(String email, String password) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) return false;

      final now = DateTime.now().toIso8601String();
      final localUsers = await DatabaseService.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );

      Map<String, dynamic>? remoteUser;
      try {
        remoteUser = await FirestoreService.getUser(firebaseUser.uid);
      } catch (_) {}

      Map<String, dynamic> chosen = {
        'id': firebaseUser.uid,
        'name': firebaseUser.displayName ?? normalizedEmail.split('@').first,
        'email': normalizedEmail,
        'photoPath': firebaseUser.photoURL,
        'createdAt': now,
        'updatedAt': now,
      };

      if (localUsers.isNotEmpty && remoteUser != null) {
        final localUpdated = localUsers.first['updatedAt'] as String? ?? '';
        final remoteUpdated = remoteUser['updatedAt'] as String? ?? '';
        chosen = localUpdated.compareTo(remoteUpdated) >= 0 ? localUsers.first : remoteUser;
      } else if (localUsers.isNotEmpty) {
        chosen = localUsers.first;
      } else if (remoteUser != null) {
        chosen = remoteUser;
      }

      chosen['id'] = firebaseUser.uid;
      chosen['email'] = normalizedEmail;
      chosen['photoPath'] = chosen['photoPath'] ?? firebaseUser.photoURL;
      chosen['updatedAt'] = now;

      final user = UserModel.fromMap(chosen);
      await _storeCurrentUser(user);

      try {
        await FirestoreService.updateUser(user.id, user.toMap());
      } catch (e) {
        print('Firestore updateUser (login sync) failed: $e');
      }

      if (user.coupleId == null) {
        await _createOrRefreshCouple(user.id, now);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> loginWithGoogle() async {
    try {
      String email;
      String? displayName;
      String? photoUrl;
      String firebaseUid;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(googleProvider);
        final user = result.user;
        if (user == null) return false;
        firebaseUid = user.uid;
        email = user.email ?? '';
        displayName = user.displayName;
        photoUrl = user.photoURL;
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return false;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        final user = result.user;
        if (user == null) return false;
        firebaseUid = user.uid;
        email = googleUser.email;
        displayName = googleUser.displayName;
        photoUrl = googleUser.photoUrl;
      }

      final normalizedEmail = email.toLowerCase().trim();
      final now = DateTime.now().toIso8601String();
      final localUsers = await DatabaseService.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
      );

      Map<String, dynamic>? remoteUser;
      try {
        remoteUser = await FirestoreService.getUser(firebaseUid);
      } catch (_) {}

      Map<String, dynamic> chosen = {
        'id': firebaseUid,
        'name': displayName ?? normalizedEmail.split('@').first,
        'email': normalizedEmail,
        'photoPath': photoUrl,
        'createdAt': now,
        'updatedAt': now,
      };

      if (localUsers.isNotEmpty && remoteUser != null) {
        final localUpdated = localUsers.first['updatedAt'] as String? ?? '';
        final remoteUpdated = remoteUser['updatedAt'] as String? ?? '';
        chosen = localUpdated.compareTo(remoteUpdated) >= 0 ? localUsers.first : remoteUser;
      } else if (localUsers.isNotEmpty) {
        chosen = localUsers.first;
      } else if (remoteUser != null) {
        chosen = remoteUser;
      }

      chosen['id'] = firebaseUid;
      chosen['email'] = normalizedEmail;
      chosen['photoPath'] = chosen['photoPath'] ?? photoUrl;
      chosen['updatedAt'] = now;

      final user = UserModel.fromMap(chosen);
      await _storeCurrentUser(user);

      try {
        await FirestoreService.updateUser(user.id, user.toMap());
      } catch (e) {
        print('Firestore updateUser (google login sync) failed: $e');
      }

      if (user.coupleId == null) {
        await _createOrRefreshCouple(user.id, now);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restoreSession() async {
    try {
      final userId = StorageService.getString('current_user_id');
      if (userId == null) return false;

      Map<String, dynamic>? userData;
      try {
        userData = await DatabaseService.getById('users', userId);
      } catch (_) {}

      if (userData == null) {
        final stored = _loadUserFromStorage();
        if (stored == null) return false;
        _currentUser = stored;
      } else {
        _currentUser = UserModel.fromMap(userData);
      }

      _saveUserToStorage();

      if (_currentUser!.email != null) {
        try {
          final remote = await FirestoreService.getUser(_currentUser!.id);
          if (remote != null) {
            final remoteUser = UserModel.fromMap({
              ...remote,
              'id': _currentUser!.id,
              'email': _currentUser!.email,
            });
            _currentUser = remoteUser;
            _saveUserToStorage();
            await DatabaseService.insert('users', remoteUser.toMap());
          }
        } catch (_) {}
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print('Google sign-out failed: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      print('Firebase sign-out failed: $e');
    }

    await clearSession();
    _currentUser = null;
  }

  static Future<void> clearSession() async {
    _currentUser = null;
    await StorageService.remove('current_user_id');
    await StorageService.remove('user_json');
  }

  static Future<void> updateProfile(String name, {String? photoPath}) async {
    if (_currentUser == null) return;

    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'name': name,
      'updatedAt': now,
    };
    if (photoPath != null) updates['photoPath'] = photoPath;

    await DatabaseService.update('users', updates, _currentUser!.id);
    try {
      await FirestoreService.updateUser(_currentUser!.id, updates);
    } catch (e) {
      print('Firestore updateUser (profile) failed: $e');
    }

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: name,
      email: _currentUser!.email,
      photoPath: photoPath ?? _currentUser!.photoPath,
      partnerId: _currentUser!.partnerId,
      coupleId: _currentUser!.coupleId,
      inviteCode: _currentUser!.inviteCode,
      createdAt: _currentUser!.createdAt,
      updatedAt: now,
    );
    _saveUserToStorage();
  }

  static void updateCurrentUser({String? coupleId, String? partnerId, String? inviteCode}) {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      photoPath: _currentUser!.photoPath,
      partnerId: partnerId ?? _currentUser!.partnerId,
      coupleId: coupleId ?? _currentUser!.coupleId,
      inviteCode: inviteCode ?? _currentUser!.inviteCode,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    _saveUserToStorage();
  }

  static Future<UserModel?> getUserById(String id) async {
    final data = await DatabaseService.getById('users', id);
    if (data == null) return null;
    return UserModel.fromMap(data);
  }
}
