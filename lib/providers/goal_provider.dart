import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';

class GoalProvider extends ChangeNotifier {
  final GoalRepository _repo = GoalRepository();

  List<GoalModel> _goals = [];
  bool _isLoading = false;

  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  int get completed => _goals.where((g) => g.isCompleted).length;
  double get totalSaved => _goals.fold(0, (s, g) => s + g.currentAmount);
  double get totalTarget => _goals.fold(0, (s, g) => s + g.targetAmount);

  Future<void> loadGoals(String userId) async {
    _isLoading = true;
    notifyListeners();
    _goals = await _repo.getGoals(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String? imageKey,
  }) async {
    await _repo.addGoal(
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      imageKey: imageKey,
    );
    await loadGoals(userId);
  }

  Future<void> addContribution(String goalId, double amount, String userId) async {
    await _repo.addContribution(goalId, amount);
    await loadGoals(userId);
  }

  Future<void> deleteGoal(String id, String userId) async {
    await _repo.deleteGoal(id);
    await loadGoals(userId);
  }

  Future<void> updateGoal(GoalModel goal, String userId) async {
    await _repo.updateGoal(goal);
    await loadGoals(userId);
  }
}
