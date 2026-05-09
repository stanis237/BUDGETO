import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/goal.dart';

class GoalRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<List<GoalModel>> getGoals(String userId) async {
    final results = await _db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => GoalModel.fromMap(e)).toList();
  }

  Future<GoalModel> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String? imageKey,
  }) async {
    final goal = GoalModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      imageKey: imageKey,
      createdAt: DateTime.now(),
    );
    await _db.insert('goals', goal.toMap());
    return goal;
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _db.update('goals', goal.toMap(), 'id = ?', [goal.id]);
  }

  Future<void> addContribution(String goalId, double amount) async {
    final results = await _db.query('goals', where: 'id = ?', whereArgs: [goalId]);
    if (results.isEmpty) return;
    final goal = GoalModel.fromMap(results.first);
    final newAmount = (goal.currentAmount + amount).clamp(0, goal.targetAmount).toDouble();
    await _db.update('goals', {'current_amount': newAmount}, 'id = ?', [goalId]);
  }

  Future<void> deleteGoal(String id) async {
    await _db.delete('goals', 'id = ?', [id]);
  }
}
