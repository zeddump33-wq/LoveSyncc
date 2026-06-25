import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/constants/app_constants.dart';
import '../models/game_model.dart';

class GamesProvider extends ChangeNotifier {
  List<GameModel> _games = [];
  bool _isLoading = false;

  List<GameModel> get games => _games;
  bool get isLoading => _isLoading;

  void clear() {
    _games = [];
    _isLoading = false;
    _currentQuestion = '';
    _currentIndex = 0;
    _questions = [];
    notifyListeners();
  }

  // Game state for current session
  String _currentQuestion = '';
  int _currentIndex = 0;
  List<String> _questions = [];

  String get currentQuestion => _currentQuestion;
  int get currentIndex => _currentIndex;

  Future<void> loadGames(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'games',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _games = data.map((g) => GameModel.fromMap(g)).toList();

    _isLoading = false;
    notifyListeners();
  }

  void startTruthOrDare() {
    _questions = [];
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 10; i++) {
      if (random % 2 == 0) {
        _questions.add(AppConstants.truthQuestions[i % AppConstants.truthQuestions.length]);
      } else {
        _questions.add(AppConstants.dareChallenges[i % AppConstants.dareChallenges.length]);
      }
    }
    _questions.shuffle();
    _currentIndex = 0;
    _currentQuestion = _questions.isNotEmpty ? _questions[0] : '';
    notifyListeners();
  }

  void startLoveQuiz() {
    _questions = [
      'What is your partner\'s favorite color?',
      'What is your partner\'s love language?',
      'Where was your first date?',
      'What is your partner\'s biggest dream?',
      'What makes your partner feel loved?',
      'What is your partner\'s favorite food?',
      'What is your partner\'s hobby?',
      'What was the best gift you gave your partner?',
    ];
    _questions.shuffle();
    _currentIndex = 0;
    _currentQuestion = _questions.isNotEmpty ? _questions[0] : '';
    notifyListeners();
  }

  void startWouldYouRather() {
    _questions = List.from(AppConstants.wouldYouRather);
    _questions.shuffle();
    _currentIndex = 0;
    _currentQuestion = _questions.isNotEmpty ? _questions[0] : '';
    notifyListeners();
  }

  void nextQuestion() {
    _currentIndex++;
    if (_currentIndex < _questions.length) {
      _currentQuestion = _questions[_currentIndex];
    } else {
      _currentQuestion = '';
    }
    notifyListeners();
  }

  bool get hasMoreQuestions => _currentIndex < _questions.length - 1;

  Future<void> saveGame(GameModel game) async {
    await DatabaseService.insert('games', game.toMap());
    _games.insert(0, game);
    notifyListeners();
  }

  Future<void> startDailyChallenge(String coupleId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing = await DatabaseService.query(
      'games',
      where: 'coupleId = ? AND gameType = ? AND createdAt LIKE ?',
      whereArgs: [coupleId, 'daily_challenge', '$today%'],
    );
    if (existing.isEmpty) {
      _questions = [
        'Send a sweet text to your partner right now!',
        'Share your favorite memory together.',
        'Tell your partner 3 things you love about them.',
        'Plan a surprise for your partner this week.',
        'Write a short love note.',
      ];
      _questions.shuffle();
      _currentIndex = 0;
      _currentQuestion = _questions.isNotEmpty ? _questions[0] : '';
      notifyListeners();
    }
  }
}
