import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/date_utils.dart';
import '../models/mood_model.dart';
import '../core/constants/app_constants.dart';
import '../core/services/auth_service.dart';

class CheckInProvider extends ChangeNotifier {
  List<MoodModel> _moods = [];
  List<CheckInModel> _checkIns = [];
  bool _isLoading = false;
  String _todayQuestion = '';
  String? _partnerTodayMood;
  StreamSubscription? _partnerMoodSubscription;

  List<MoodModel> get moods => _moods;
  List<CheckInModel> get checkIns => _checkIns;
  bool get isLoading => _isLoading;
  String get todayQuestion => _todayQuestion;
  String? get partnerTodayMood => _partnerTodayMood;

  void clear() {
    _partnerMoodSubscription?.cancel();
    _partnerMoodSubscription = null;
    _moods = [];
    _checkIns = [];
    _isLoading = false;
    _todayQuestion = '';
    _partnerTodayMood = null;
    notifyListeners();
  }

  /// Set up partner mood listener (call when partnerId becomes available after initial load)
  void setPartnerId(String partnerId) {
    _listenPartnerMood(partnerId);
  }

  Future<void> loadData(String coupleId, String userId) async {
    _isLoading = true;
    notifyListeners();

    final moodData = await DatabaseService.query(
      'moods',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 30,
    );
    _moods = moodData.map((m) => MoodModel.fromMap(m)).toList();

    if (coupleId.isNotEmpty) {
      final checkInData = await DatabaseService.query(
        'check_ins',
        where: 'coupleId = ?',
        whereArgs: [coupleId],
        orderBy: 'date DESC',
        limit: 30,
      );
      _checkIns = checkInData.map((c) => CheckInModel.fromMap(c)).toList();
      _ensurePartnerListener(userId);
    }

    _setTodayQuestion();

    _isLoading = false;
    notifyListeners();
  }

  void _ensurePartnerListener(String userId) {
    final partnerId = AuthService.currentUser?.partnerId;
    if (partnerId != null && partnerId != userId) {
      _listenPartnerMood(partnerId);
    }
  }

  void _listenPartnerMood(String partnerId) {
    _partnerMoodSubscription?.cancel();
    try {
      _partnerMoodSubscription = FirestoreService.streamUserDoc(partnerId).listen((data) {
        if (data == null) return;
        final today = DateFormatUtils.formatDate(DateTime.now());
        final moodDate = data['lastMoodDate'] as String?;
        _partnerTodayMood = (moodDate == today)
            ? data['lastMood'] as String?
            : null;
        notifyListeners();
      }, onError: (e) {
        print('Firestore streamUserDoc (partner mood) failed: $e');
      });
    } catch (e) {
      print('Firestore streamUserDoc setup failed: $e');
    }
  }

  void _setTodayQuestion() {
    final day = DateTime.now().day;
    final questions = AppConstants.dailyQuestions;
    _todayQuestion = questions[day % questions.length];
  }

  Future<void> saveMood(String mood, {String? note}) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final today = DateFormatUtils.formatDate(DateTime.now());
    final existing = _moods.where((m) => m.date == today).toList();

    if (existing.isNotEmpty) {
      await DatabaseService.update('moods', {
        'mood': mood,
        'note': note,
      }, existing.first.id);
      final index = _moods.indexWhere((m) => m.id == existing.first.id);
      if (index != -1) {
        _moods[index] = MoodModel(
          id: existing.first.id,
          userId: user.id,
          mood: mood,
          note: note,
          date: today,
          createdAt: existing.first.createdAt,
        );
      }
    } else {
      final moodModel = MoodModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        mood: mood,
        note: note,
        date: today,
        createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
      );
      await DatabaseService.insert('moods', moodModel.toMap());
      _moods.insert(0, moodModel);
    }
    // Sync mood to Firestore so partner can see it (write to own user doc fields)
    try {
      await FirestoreService.updateUserMood(user.id, {
        'mood': mood,
        'note': note,
        'date': today,
        'createdAt': DateFormatUtils.formatDateTime(DateTime.now()),
      });
    } catch (e) {
      print('Firestore updateUserMood failed: $e');
    }
    notifyListeners();
  }

  Future<void> saveCheckIn(String answer) async {
    final user = AuthService.currentUser;
    if (user?.coupleId == null) return;

    final today = DateFormatUtils.formatDate(DateTime.now());
    final checkIn = CheckInModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coupleId: user!.coupleId!,
      question: _todayQuestion,
      answer: answer,
      userId: user.id,
      date: today,
      createdAt: DateFormatUtils.formatDateTime(DateTime.now()),
    );

    String? firestoreId;
    try {
      firestoreId = await FirestoreService.addCheckIn(user.coupleId!, checkIn.toMap());
    } catch (e) {
      print('Firestore addCheckIn failed: $e');
    }
    final finalCheckIn = CheckInModel(
      id: firestoreId ?? checkIn.id,
      coupleId: checkIn.coupleId,
      question: checkIn.question,
      answer: checkIn.answer,
      userId: checkIn.userId,
      date: checkIn.date,
      createdAt: checkIn.createdAt,
    );
    await DatabaseService.insert('check_ins', finalCheckIn.toMap());
    _checkIns.insert(0, finalCheckIn);
    notifyListeners();
  }

  String? get todayMood {
    final today = DateFormatUtils.formatDate(DateTime.now());
    final mood = _moods.where((m) => m.date == today).toList();
    return mood.isNotEmpty ? mood.first.mood : null;
  }

  bool get hasCheckedInToday {
    final today = DateFormatUtils.formatDate(DateTime.now());
    final user = AuthService.currentUser;
    if (user == null) return false;
    return _checkIns.any((c) => c.date == today && c.userId == user.id);
  }

  int get currentStreak {
    if (_moods.isEmpty) return 0;
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = DateFormatUtils.formatDate(today.subtract(Duration(days: i)));
      if (_moods.any((m) => m.date == date)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
