import 'package:flutter/material.dart';
import '../core/services/database_service.dart';

class StatisticsProvider extends ChangeNotifier {
  int _daysTogether = 0;
  int _goalsCompleted = 0;
  int _memoriesSaved = 0;
  int _currentStreak = 0;
  int _totalMessages = 0;
  int _moodEntries = 0;
  bool _isLoading = false;

  int get daysTogether => _daysTogether;
  int get goalsCompleted => _goalsCompleted;
  int get memoriesSaved => _memoriesSaved;
  int get currentStreak => _currentStreak;
  int get totalMessages => _totalMessages;
  int get moodEntries => _moodEntries;
  bool get isLoading => _isLoading;

  void clear() {
    _daysTogether = 0;
    _goalsCompleted = 0;
    _memoriesSaved = 0;
    _currentStreak = 0;
    _totalMessages = 0;
    _moodEntries = 0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics(String coupleId, String userId) async {
    _isLoading = true;
    notifyListeners();

    _daysTogether = await DatabaseService.getCount('milestones', where: 'coupleId = ?', whereArgs: [coupleId]);
    _goalsCompleted = await DatabaseService.getCount('goals', where: 'coupleId = ? AND isCompleted = 1', whereArgs: [coupleId]);
    _memoriesSaved = await DatabaseService.getCount('memories', where: 'coupleId = ?', whereArgs: [coupleId]);
    _totalMessages = await DatabaseService.getCount('messages', where: 'coupleId = ?', whereArgs: [coupleId]);
    _moodEntries = await DatabaseService.getCount('moods', where: 'userId = ?', whereArgs: [userId]);

    await _calculateStreak(userId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _calculateStreak(String userId) async {
    final moods = await DatabaseService.query(
      'moods',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    if (moods.isEmpty) {
      _currentStreak = 0;
      return;
    }

    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (moods.any((m) => m['date'] == dateStr)) {
        streak++;
      } else {
        break;
      }
    }
    _currentStreak = streak;
  }
}
