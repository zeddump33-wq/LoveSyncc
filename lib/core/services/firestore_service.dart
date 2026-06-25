import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Couples ---
  static Future<Map<String, dynamic>?> getCoupleByInviteCode(String code) async {
    final snap = await _db
        .collection('couples')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    data['id'] = snap.docs.first.id;
    return data;
  }

  static Future<Map<String, dynamic>?> getCouple(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  static Future<void> createCouple(String id, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(id).set(data);
  }

  static Future<void> updateCouple(String id, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(id).update(data);
  }

  static Future<void> deleteCouple(String id) async {
    await _db.collection('couples').doc(id).delete();
  }

  // --- Users ---
  static Future<Map<String, dynamic>?> getUserByInviteCode(String code) async {
    final snap = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    data['id'] = snap.docs.first.id;
    return data;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    data['id'] = snap.docs.first.id;
    return data;
  }

  static Future<void> createUser(String id, Map<String, dynamic> data) async {
    await _db.collection('users').doc(id).set(data);
  }

  static Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _db.collection('users').doc(id).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Stream a user document for real-time updates (e.g., mood changes)
  static Stream<Map<String, dynamic>?> streamUserDoc(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      data['id'] = snap.id;
      return data;
    });
  }

  /// Update mood fields on a user document so partner can read them
  static Future<void> updateUserMood(String userId, Map<String, dynamic> moodData) async {
    await _db.collection('users').doc(userId).set({
      'lastMood': moodData['mood'],
      'lastMoodNote': moodData['note'],
      'lastMoodDate': moodData['date'],
      'lastMoodTimestamp': moodData['createdAt'],
    }, SetOptions(merge: true));
  }

  /// Find a user who joined a couple (has partnerId and coupleId set)
  static Future<Map<String, dynamic>?> getJoiningPartner(String coupleId, String partner1Id) async {
    final snap = await _db
        .collection('users')
        .where('coupleId', isEqualTo: coupleId)
        .where('partnerId', isEqualTo: partner1Id)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = snap.docs.first.data();
    data['id'] = snap.docs.first.id;
    return data;
  }

  // --- Messages ---
  static Stream<List<Map<String, dynamic>>> streamMessages(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> sendMessage(String coupleId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('messages').doc(data['id']).set(data);
    return data['id'];
  }
  // --- Memories ---
  static Stream<List<Map<String, dynamic>>> streamMemories(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('memories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addMemory(String coupleId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('memories').doc(data['id']).set(data);
    return data['id'];
  }

  static Future<void> deleteMemory(String coupleId, String memoryId) async {
    await _db.collection('couples').doc(coupleId).collection('memories').doc(memoryId).delete();
  }

  // --- Goals ---
  static Stream<List<Map<String, dynamic>>> streamGoals(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addGoal(String coupleId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('couples').doc(coupleId).collection('goals').add(data);
    return docRef.id;
  }

  static Future<void> updateGoal(String coupleId, String goalId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('goals').doc(goalId).update(data);
  }

  static Future<void> deleteGoal(String coupleId, String goalId) async {
    await _db.collection('couples').doc(coupleId).collection('goals').doc(goalId).delete();
  }

  // --- Love Notes ---
  static Stream<List<Map<String, dynamic>>> streamNotes(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addNote(String coupleId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('couples').doc(coupleId).collection('notes').add(data);
    return docRef.id;
  }

  static Future<void> updateNote(String coupleId, String noteId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('notes').doc(noteId).update(data);
  }

  static Future<void> deleteNote(String coupleId, String noteId) async {
    await _db.collection('couples').doc(coupleId).collection('notes').doc(noteId).delete();
  }

  // --- Calendar Events ---
  static Stream<List<Map<String, dynamic>>> streamEvents(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addEvent(String coupleId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('couples').doc(coupleId).collection('events').add(data);
    return docRef.id;
  }

  static Future<void> updateEvent(String coupleId, String eventId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('events').doc(eventId).update(data);
  }

  static Future<void> deleteEvent(String coupleId, String eventId) async {
    await _db.collection('couples').doc(coupleId).collection('events').doc(eventId).delete();
  }

  // --- Wishlist ---
  static Stream<List<Map<String, dynamic>>> streamWishlist(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('wishlist')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addWishlistItem(String coupleId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('couples').doc(coupleId).collection('wishlist').add(data);
    return docRef.id;
  }

  static Future<void> updateWishlistItem(String coupleId, String itemId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('wishlist').doc(itemId).update(data);
  }

  static Future<void> deleteWishlistItem(String coupleId, String itemId) async {
    await _db.collection('couples').doc(coupleId).collection('wishlist').doc(itemId).delete();
  }

  // --- Check-ins ---
  static Stream<List<Map<String, dynamic>>> streamCheckIns(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('checkins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<String?> addCheckIn(String coupleId, Map<String, dynamic> data) async {
    final docRef = await _db.collection('couples').doc(coupleId).collection('checkins').add(data);
    return docRef.id;
  }

  // --- Moods stored on user doc ---

  // --- Milestones ---
  static Stream<List<Map<String, dynamic>>> streamMilestones(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .collection('milestones')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  static Future<void> addMilestone(String coupleId, Map<String, dynamic> data) async {
    await _db.collection('couples').doc(coupleId).collection('milestones').add(data);
  }
}
