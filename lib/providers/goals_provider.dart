import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/database_service.dart';
import '../core/services/firestore_service.dart';
import '../models/goal_model.dart';

class GoalsProvider extends ChangeNotifier {
  List<GoalModel> _goals = [];
  bool _isLoading = false;
  StreamSubscription? _goalsSubscription;

  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;

  void clear() {
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
    _goals = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadGoals(String coupleId) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseService.query(
      'goals',
      where: 'coupleId = ?',
      whereArgs: [coupleId],
      orderBy: 'createdAt DESC',
    );
    _goals = data.map((g) => GoalModel.fromMap(g)).toList();

    _isLoading = false;
    notifyListeners();

    // Listen for real-time updates from Firestore
    _goalsSubscription?.cancel();
    try {
      _goalsSubscription = FirestoreService.streamGoals(coupleId).listen((data) {
        final firestoreGoals = data.map((g) => GoalModel.fromMap(g)).toList();
        final firestoreIds = firestoreGoals.map((g) => g.id).toSet();
        _goals = [
          ..._goals.where((g) => !firestoreIds.contains(g.id)),
          ...firestoreGoals,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }, onError: (_) {});
    } catch (e) {
      print('Firestore streamGoals failed: $e');
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    String? firestoreId;
    try {
      firestoreId = await FirestoreService.addGoal(goal.coupleId, goal.toMap());
    } catch (e) {
      print('Firestore addGoal failed: $e');
    }
    final model = GoalModel(
      id: firestoreId ?? goal.id,
      coupleId: goal.coupleId,
      title: goal.title,
      description: goal.description,
      type: goal.type,
      targetValue: goal.targetValue,
      currentValue: goal.currentValue,
      targetDate: goal.targetDate,
      isCompleted: goal.isCompleted,
      createdAt: goal.createdAt,
      createdBy: goal.createdBy,
    );
    await DatabaseService.insert('goals', model.toMap());
    _goals.insert(0, model);
    notifyListeners();
  }

  Future<void> updateProgress(String goalId, double value) async {
    await DatabaseService.update('goals', {'currentValue': value}, goalId);
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      _goals[index] = GoalModel(
        id: _goals[index].id,
        coupleId: _goals[index].coupleId,
        title: _goals[index].title,
        description: _goals[index].description,
        type: _goals[index].type,
        targetValue: _goals[index].targetValue,
        currentValue: value,
        targetDate: _goals[index].targetDate,
        isCompleted: _goals[index].isCompleted,
        createdAt: _goals[index].createdAt,
        createdBy: _goals[index].createdBy,
      );
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final newValue = _goals[index].isCompleted == 0 ? 1 : 0;
      await DatabaseService.update('goals', {'isCompleted': newValue}, goalId);
      _goals[index] = GoalModel(
        id: _goals[index].id,
        coupleId: _goals[index].coupleId,
        title: _goals[index].title,
        description: _goals[index].description,
        type: _goals[index].type,
        targetValue: _goals[index].targetValue,
        currentValue: _goals[index].currentValue,
        targetDate: _goals[index].targetDate,
        isCompleted: newValue,
        createdAt: _goals[index].createdAt,
        createdBy: _goals[index].createdBy,
      );
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    await DatabaseService.delete('goals', id);
    _goals.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> addStep(GoalStepModel step) async {
    await DatabaseService.insert('goal_steps', step.toMap());
    notifyListeners();
  }

  Future<void> toggleStep(String stepId) async {
    await DatabaseService.rawQuery(
      'UPDATE goal_steps SET isCompleted = CASE WHEN isCompleted = 0 THEN 1 ELSE 0 END WHERE id = ?',
      [stepId],
    );
    notifyListeners();
  }

  List<GoalModel> get savingsGoals => _goals.where((g) => g.type == 'savings').toList();
  List<GoalModel> get travelGoals => _goals.where((g) => g.type == 'travel').toList();
  List<GoalModel> get completedGoals => _goals.where((g) => g.isCompleted == 1).toList();

  int get completedCount => completedGoals.length;
}
