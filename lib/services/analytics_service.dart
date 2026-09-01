import '../core/api/api_client.dart';

class AnalyticsService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>?> getBudgetForecast(int month, int year) async {
    try {
      final response = await _api.dio.get('/analytics/forecast/', queryParameters: {
        'month': month,
        'year': year,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDetectedSubscriptions() async {
    try {
      final response = await _api.dio.get('/analytics/subscriptions/');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
