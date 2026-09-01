import '../core/api/api_client.dart';

class HouseholdService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>?> getHousehold() async {
    try {
      final response = await _api.dio.get('/households/');
      final data = response.data as List;
      if (data.isEmpty) return null;
      return data.first;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createHousehold(String name) async {
    try {
      final response = await _api.dio.post('/households/', data: {
        'name': name,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinHousehold(String householdId) async {
    try {
      final response = await _api.dio.post('/households/join/', data: {
        'household_id': householdId,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> leaveHousehold() async {
    try {
      await _api.dio.post('/households/leave/');
      return true;
    } catch (e) {
      return false;
    }
  }
}
