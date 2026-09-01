import '../core/api/api_client.dart';

class GamificationService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getChallenges() async {
    try {
      final response = await _api.dio.get('/gamification/challenges/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final response = await _api.dio.get('/gamification/badges/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }
}
