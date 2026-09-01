import '../core/api/api_client.dart';
import '../models/user.dart';

class UserRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>?> register(String name, String email, String password) async {
    try {
      final response = await _api.dio.post('/auth/register/', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      return {
        'user': UserModel.fromMap(response.data['user']),
        'tokens': response.data['tokens'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _api.dio.post('/auth/login/', data: {
        'email': email,
        'password': password,
      });
      return {
        'user': UserModel.fromMap(response.data['user']),
        'tokens': response.data['tokens'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _api.dio.get('/auth/me/');
      return UserModel.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateCurrency(String currency) async {
    try {
      await _api.dio.patch('/auth/me/', data: {
        'currency': currency,
      });
    } catch (e) {
      print('Error updating currency: $e');
    }
  }
}
