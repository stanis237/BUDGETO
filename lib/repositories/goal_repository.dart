import '../core/api/api_client.dart';
import '../models/goal.dart';
import 'package:intl/intl.dart';

class GoalRepository {
  final ApiClient _api = ApiClient();

  Future<List<GoalModel>> getGoals(String userId) async {
    try {
      final response = await _api.dio.get('/goals/');
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => GoalModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<GoalModel> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String? imageKey,
  }) async {
    final response = await _api.dio.post('/goals/', data: {
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline != null ? DateFormat('yyyy-MM-dd').format(deadline) : null,
      'image_key': imageKey,
    });
    return GoalModel.fromMap(response.data);
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _api.dio.patch('/goals/${goal.id}/', data: {
      'title': goal.title,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'deadline': goal.deadline != null ? DateFormat('yyyy-MM-dd').format(goal.deadline!) : null,
      'image_key': goal.imageKey,
    });
  }

  Future<void> addContribution(String goalId, double amount) async {
    await _api.dio.post('/goals/$goalId/contribute/', data: {
      'amount': amount,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _api.dio.delete('/goals/$id/');
  }
}
