import '../../models/couple_model.dart';
import '../../models/user_model.dart';
import '../utils/encryption_utils.dart';
import 'database_service.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class PartnerService {
  static Future<CoupleModel?> createCouple(String anniversaryDate) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final now = DateTime.now().toIso8601String();
      final inviteCode = EncryptionUtils.generateInviteCode();

      // Reuse existing coupleId so messages are preserved
      final coupleId = user.coupleId ?? EncryptionUtils.generateId();
      final existingCouple = user.coupleId != null ? await getCouple(user.coupleId!) : null;

      if (existingCouple != null) {
        // Update existing couple with new invite code & anniversary
        try {
          await FirestoreService.updateCouple(existingCouple.id, {
            'inviteCode': inviteCode,
            'anniversaryDate': anniversaryDate,
            'status': 'pending',
            'updatedAt': now,
          });
        } catch (e) {
          print('Firestore updateCouple failed, trying create: $e');
          try {
            await FirestoreService.createCouple(existingCouple.id, {
              'id': existingCouple.id,
              'partner1Id': existingCouple.partner1Id,
              'partner2Id': existingCouple.partner2Id,
              'inviteCode': inviteCode,
              'anniversaryDate': anniversaryDate,
              'status': 'pending',
              'createdAt': existingCouple.createdAt,
              'updatedAt': now,
            });
          } catch (e2) {
            print('Firestore createCouple on fallback also failed: $e2');
          }
        }
        await DatabaseService.update('couples', {
          'inviteCode': inviteCode,
          'anniversaryDate': anniversaryDate,
          'status': 'pending',
          'updatedAt': now,
        }, existingCouple.id);

        await DatabaseService.update('users', {
          'inviteCode': inviteCode,
          'updatedAt': now,
        }, user.id);

        try {
          await FirestoreService.updateUser(user.id, {
            'inviteCode': inviteCode,
            'coupleId': existingCouple.id,
            'partner1Id': existingCouple.partner1Id,
            'anniversaryDate': anniversaryDate,
            'coupleStatus': 'pending',
            'createdAt': existingCouple.createdAt,
            'updatedAt': now,
          });
        } catch (e) {
          print('Firestore updateUser (createCouple existing) failed: $e');
        }

        AuthService.updateCurrentUser(inviteCode: inviteCode);

        return CoupleModel(
          id: existingCouple.id,
          partner1Id: existingCouple.partner1Id,
          partner2Id: existingCouple.partner2Id,
          anniversaryDate: anniversaryDate,
          status: 'pending',
          inviteCode: inviteCode,
          createdAt: existingCouple.createdAt,
          updatedAt: now,
        );
      }

      // No existing couple - create new one
      final couple = CoupleModel(
        id: coupleId,
        partner1Id: user.id,
        inviteCode: inviteCode,
        anniversaryDate: anniversaryDate,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      try {
        await FirestoreService.createCouple(coupleId, couple.toMap());
      } catch (e) {
        print('Firestore createCouple failed: $e');
      }
      await DatabaseService.insert('couples', couple.toMap());
      await DatabaseService.update('users', {
        'coupleId': coupleId,
        'inviteCode': inviteCode,
        'updatedAt': now,
      }, user.id);

      try {
        await FirestoreService.updateUser(user.id, {
          'inviteCode': inviteCode,
          'coupleId': coupleId,
          'partner1Id': user.id,
          'anniversaryDate': anniversaryDate,
          'coupleStatus': 'pending',
          'createdAt': now,
          'updatedAt': now,
        });
      } catch (e) {
        print('Firestore updateUser (createCouple new) failed: $e');
      }

      AuthService.updateCurrentUser(coupleId: coupleId, inviteCode: inviteCode);

      return couple;
    } catch (e) {
      return null;
    }
  }

  static Future<CoupleModel?> joinCouple(String inviteCode) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final code = inviteCode.toUpperCase();

      // Look up invite code via users collection (readable by any authenticated user)
      Map<String, dynamic>? sourceData;
      try {
        final userDoc = await FirestoreService.getUserByInviteCode(code);
        if (userDoc != null) {
          final foundCoupleId = userDoc['coupleId'] as String?;
          final coupleStatus = userDoc['coupleStatus'] as String?;
          if (foundCoupleId != null && (coupleStatus == 'pending' || coupleStatus == 'solo')) {
            // Try local DB first
            sourceData = await DatabaseService.getById('couples', foundCoupleId);
            if (sourceData == null) {
              // Try reading couple doc from Firestore (may fail if not member)
              try {
                sourceData = await FirestoreService.getCouple(foundCoupleId);
              } catch (e) {
                print('Firestore getCouple failed: $e');
              }
            }
            // Construct from user doc if couple doc is not readable
            if (sourceData == null) {
              sourceData = {
                'id': foundCoupleId,
                'partner1Id': userDoc['partner1Id'] ?? userDoc['id'],
                'partner2Id': null,
                'anniversaryDate': userDoc['anniversaryDate'],
                'status': 'pending',
                'inviteCode': code,
                'createdAt': userDoc['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': userDoc['updatedAt'] ?? DateTime.now().toIso8601String(),
              };
            }
          }
        }
      } catch (e) {
        print('User-based invite lookup failed: $e');
      }

      // Fallback: try couples collection directly (if rules allow)
      if (sourceData == null) {
        try {
          sourceData = await FirestoreService.getCoupleByInviteCode(code);
        } catch (e) {
          print('Couple-based invite lookup failed: $e');
        }
      }

      // Final fallback: local DB (same-device testing)
      if (sourceData == null) {
        sourceData = await DatabaseService.getByField('couples', 'inviteCode', code);
      }

      if (sourceData == null) return null;

      final couple = CoupleModel.fromMap(sourceData);
      if (couple.status != 'pending' && couple.status != 'solo') return null;

      final now = DateTime.now().toIso8601String();

      // Update local DB
      await DatabaseService.update('couples', {
        'partner2Id': user.id,
        'status': 'active',
        'updatedAt': now,
      }, couple.id);

      await DatabaseService.update('users', {
        'coupleId': couple.id,
        'partnerId': couple.partner1Id,
        'updatedAt': now,
      }, user.id);

      // Update the joining user's Firestore doc (own doc, always allowed)
      try {
        await FirestoreService.updateUser(user.id, {
          'coupleId': couple.id,
          'partnerId': couple.partner1Id,
          'updatedAt': now,
        });
      } catch (e) {
        print('Firestore updateUser (join) failed: $e');
      }

      // Try to update the couple in Firestore (may fail if not yet member)
      try {
        await FirestoreService.updateCouple(couple.id, {
          'partner2Id': user.id,
          'status': 'active',
          'updatedAt': now,
        });
      } catch (e) {
        print('Firestore couple update deferred (creator will update): $e');
      }

      // Try to update partner1's Firestore doc
      try {
        await FirestoreService.updateUser(couple.partner1Id, {
          'partnerId': user.id,
          'updatedAt': now,
        });
      } catch (e) {
        print('Firestore updateUser (partner1) deferred: $e');
      }
      await DatabaseService.update('users', {
        'partnerId': user.id,
        'updatedAt': now,
      }, couple.partner1Id);

      AuthService.updateCurrentUser(coupleId: couple.id, partnerId: couple.partner1Id);

      return CoupleModel(
        id: couple.id,
        partner1Id: couple.partner1Id,
        partner2Id: user.id,
        anniversaryDate: couple.anniversaryDate,
        status: 'active',
        inviteCode: couple.inviteCode,
        createdAt: couple.createdAt,
        updatedAt: now,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<CoupleModel?> getCouple(String coupleId) async {
    // Try Firestore first, fall back to local
    Map<String, dynamic>? data;
    try {
      data = await FirestoreService.getCouple(coupleId);
    } catch (e) {
      print('Firestore getCouple failed: $e');
    }
    if (data == null) {
      data = await DatabaseService.getById('couples', coupleId);
    }
    if (data == null) return null;

    // If couple doc has no partner2, check users collection for a join
    if (data['partner2Id'] == null || data['status'] == 'pending' || data['status'] == 'solo') {
      try {
        final partner1Id = data['partner1Id'] as String?;
        if (partner1Id != null) {
          final joined = await FirestoreService.getJoiningPartner(coupleId, partner1Id);
          if (joined != null) {
            data['partner2Id'] = joined['id'];
            data['status'] = 'active';
            return CoupleModel.fromMap(data);
          }
        }
      } catch (_) {}
    }

    return CoupleModel.fromMap(data);
  }

  static Future<CoupleModel?> getCurrentCouple() async {
    final user = AuthService.currentUser;
    if (user?.coupleId == null) return null;
    return getCouple(user!.coupleId!);
  }

  static Future<void> updateAnniversary(String coupleId, String date) async {
    final now = DateTime.now().toIso8601String();
    try {
      await FirestoreService.updateCouple(coupleId, {
        'anniversaryDate': date,
        'updatedAt': now,
      });
    } catch (e) {
      print('Firestore updateAnniversary failed: $e');
    }
    await DatabaseService.update('couples', {
      'anniversaryDate': date,
      'updatedAt': now,
    }, coupleId);
  }

  static Future<List<UserModel>> getCoupleMembers(String coupleId) async {
    final couple = await getCouple(coupleId);
    if (couple == null) return [];

    final members = <UserModel>[];
    final p1 = await AuthService.getUserById(couple.partner1Id);
    if (p1 != null) members.add(p1);
    if (couple.partner2Id != null) {
      final p2 = await AuthService.getUserById(couple.partner2Id!);
      if (p2 != null) members.add(p2);
    }
    return members;
  }

  static Future<void> unlinkPartner() async {
    final user = AuthService.currentUser;
    if (user?.coupleId == null) return;

    final couple = await getCouple(user!.coupleId!);
    if (couple == null) return;

    final partnerId = user.id == couple.partner1Id ? couple.partner2Id : couple.partner1Id;

    final now = DateTime.now().toIso8601String();

    if (partnerId != null) {
      await DatabaseService.update('users', {
        'partnerId': null,
        'coupleId': null,
        'inviteCode': null,
        'updatedAt': now,
      }, partnerId);
    }

    await DatabaseService.update('users', {
      'partnerId': null,
      'coupleId': null,
      'inviteCode': null,
      'updatedAt': now,
    }, user.id);

    AuthService.updateCurrentUser(coupleId: null, partnerId: null, inviteCode: null);

    try {
      await FirestoreService.deleteCouple(couple.id);
    } catch (e) {
      print('Firestore deleteCouple failed: $e');
    }
    await DatabaseService.delete('couples', couple.id);
  }

}
