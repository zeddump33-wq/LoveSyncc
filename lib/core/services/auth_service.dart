import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import '../utils/encryption_utils.dart';
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

  static Future<bool> createLocalAccount(String name) async {
    try {
      // Sign in anonymously so Firestore security rules pass
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
          return true;
        }
      }

      // Use Firebase UID so Firestore security rules (auth.uid checks) pass
      final id = _auth.currentUser?.uid ?? EncryptionUtils.generateId();
      final now = DateTime.now().toIso8601String();
      final user = UserModel(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseService.insert('users', user.toMap());
      _currentUser = user;
      _saveUserToStorage();
      await StorageService.setString('current_user_id', id);

      await _autoCreateCouple(id, now);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _autoCreateCouple(String userId, String now) async {
    final coupleId = EncryptionUtils.generateId();
    final inviteCode = EncryptionUtils.generateInviteCode();
    final coupleData = {
      'id': coupleId,
      'partner1Id': userId,
      'partner2Id': null,
      'anniversaryDate': DateTime.now().toIso8601String().split('T')[0],
      'status': 'solo',
      'inviteCode': inviteCode,
      'createdAt': now,
      'updatedAt': now,
    };
    try {
      await FirestoreService.createCouple(coupleId, coupleData);
    } catch (e) {
      print('Firestore createCouple in _autoCreateCouple failed: $e');
    }
    await DatabaseService.insert('couples', coupleData);
    await DatabaseService.update('users', {'coupleId': coupleId, 'inviteCode': inviteCode, 'updatedAt': now}, userId);
    try {
      await FirestoreService.updateUser(userId, {
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'partner1Id': userId,
        'anniversaryDate': DateTime.now().toIso8601String().split('T')[0],
        'coupleStatus': 'solo',
        'createdAt': now,
        'updatedAt': now,
      });
    } catch (e) {
      print('Firestore updateUser in _autoCreateCouple failed: $e');
    }
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

  static Future<bool> loginWithEmail(String email, String password) async {
    try {
      // Authenticate with Firebase so Firestore rules pass
      try {
        await _auth.signInWithEmailAndPassword(
          email: email.toLowerCase().trim(),
          password: password,
        );
      } catch (e) {
        print('Firebase Auth email login failed (non-fatal): $e');
      }

      final firebaseUid = _auth.currentUser?.uid;
      final now = DateTime.now().toIso8601String();

      final users = await DatabaseService.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );
      if (users.isEmpty) {
        // Use Firebase UID so Firestore security rules pass
        final id = firebaseUid ?? EncryptionUtils.generateId();
        final user = UserModel(
          id: id,
          name: email.split('@').first,
          email: email.toLowerCase().trim(),
          createdAt: now,
          updatedAt: now,
        );
        await DatabaseService.insert('users', user.toMap());
        await StorageService.setString('current_user_id', id);
        _currentUser = user;
        _saveUserToStorage();
        await _autoCreateCouple(id, now);
        return true;
      }
      _currentUser = UserModel.fromMap(users.first);
      _saveUserToStorage();
      await StorageService.setString('current_user_id', _currentUser!.id);
      if (_currentUser!.coupleId == null) {
        await _autoCreateCouple(_currentUser!.id, now);
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
        // Web: use Firebase Auth's built-in Google provider (no OAuth client ID needed)
        final googleProvider = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(googleProvider);
        final user = result.user;
        if (user == null) return false;
        firebaseUid = user.uid;
        email = user.email ?? '';
        displayName = user.displayName;
        photoUrl = user.photoURL;
      } else {
        // Native: use google_sign_in package
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        firebaseUid = _auth.currentUser!.uid;
        email = googleUser.email;
        displayName = googleUser.displayName;
        photoUrl = googleUser.photoUrl;
      }

      // First check local DB (has latest profile updates)
      final localUsers = await DatabaseService.query('users',
          where: 'email = ?', whereArgs: [email.toLowerCase().trim()]);
      Map<String, dynamic>? firestoreData;
      try {
        firestoreData = await FirestoreService.getUser(firebaseUid);
      } catch (_) {}

      Map<String, dynamic> sourceData;
      if (localUsers.isNotEmpty && firestoreData != null) {
        // Use whichever was updated more recently
        final localUpdated = localUsers.first['updatedAt'] as String? ?? '';
        final remoteUpdated = firestoreData['updatedAt'] as String? ?? '';
        sourceData = localUpdated.compareTo(remoteUpdated) >= 0
            ? localUsers.first
            : firestoreData;
      } else if (localUsers.isNotEmpty) {
        sourceData = localUsers.first;
      } else if (firestoreData != null) {
        sourceData = firestoreData;
      } else {
        sourceData = {};
      }

      if (sourceData.isNotEmpty) {
        _currentUser = UserModel.fromMap(sourceData);
        _saveUserToStorage();
        await StorageService.setString('current_user_id', _currentUser!.id);
        // Sync whichever source is newer to the other
        await DatabaseService.insert('users', _currentUser!.toMap());
        try {
          await FirestoreService.updateUser(firebaseUid, {
            'name': _currentUser!.name,
            'photoPath': _currentUser!.photoPath,
            'updatedAt': _currentUser!.updatedAt ?? DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Firestore updateUser (sign-in sync) failed: $e');
        }
        if (_currentUser!.coupleId == null) {
          await _autoCreateCouple(_currentUser!.id, DateTime.now().toIso8601String());
        }
        return true;
      }

      final now = DateTime.now().toIso8601String();
      final user = UserModel(
        id: firebaseUid,
        name: displayName ?? 'Partner',
        email: email,
        photoPath: photoUrl,
        createdAt: now,
        updatedAt: now,
      );
      try {
        await FirestoreService.createUser(firebaseUid, user.toMap());
      } catch (e) {
        print('Firestore createUser failed: $e');
      }
      await DatabaseService.insert('users', user.toMap());
      _currentUser = user;
      _saveUserToStorage();
      await StorageService.setString('current_user_id', firebaseUid);
      await _autoCreateCouple(firebaseUid, now);
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
      if (_currentUser!.coupleId == null) {
        await _autoCreateCouple(_currentUser!.id, DateTime.now().toIso8601String());
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
    _currentUser = null;
    // Keep current_user_id in storage so account persists across sign-out
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
