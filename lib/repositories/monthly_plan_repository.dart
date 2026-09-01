import '../core/api/api_client.dart';
import '../models/monthly_plan.dart';

class MonthlyPlanRepository {
  final ApiClient _api = ApiClient();

  Future<MonthlyPlan?> getPlan(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/monthly-plans/', queryParameters: {
        'month': month,
        'year': year,
      });
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      if (data.isEmpty) return null;
      return MonthlyPlan.fromMap(data.first);
    } catch (e) {
      return null;
    }
  }

  Future<MonthlyPlan> savePlan(String userId, int month, int year, double needs, double expectations) async {
    final response = await _api.dio.post('/monthly-plans/', data: {
      'month': month,
      'year': year,
      'needs': needs,
      'expectations': expectations,
    });
    return MonthlyPlan.fromMap(response.data);
  }
}
