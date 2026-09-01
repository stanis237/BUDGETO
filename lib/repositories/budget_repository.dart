import '../core/api/api_client.dart';
import '../models/budget.dart';

class BudgetRepository {
  final ApiClient _api = ApiClient();

  Future<List<BudgetModel>> getBudgets(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/budgets/', queryParameters: {
        'month': month,
        'year': year,
      });
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => BudgetModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>> getBudgetSummary(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/budgets/summary/', queryParameters: {
        'month': month,
        'year': year,
      });
      return {
        'total': (response.data['total'] as num).toDouble(),
        'spent': (response.data['spent'] as num).toDouble(),
        'remaining': (response.data['remaining'] as num).toDouble(),
      };
    } catch (e) {
      return {'total': 0, 'spent': 0, 'remaining': 0};
    }
  }

  Future<void> upsertBudget({
    required String userId,
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    await _api.dio.post('/budgets/', data: {
      'category': categoryId,
      'amount': amount,
      'month': month,
      'year': year,
    });
  }

  Future<void> deleteBudget(String id) async {
    await _api.dio.delete('/budgets/$id/');
  }
}
