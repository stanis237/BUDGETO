import '../core/api/api_client.dart';
import '../models/account.dart';

class AccountRepository {
  final ApiClient _api = ApiClient();

  Future<List<AccountModel>> getAccounts() async {
    try {
      final response = await _api.dio.get('/accounts/');
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => AccountModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    final response = await _api.dio.post('/accounts/', data: {
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'icon': account.icon,
      'color': account.color,
    });
    return AccountModel.fromMap(response.data);
  }

  Future<void> updateAccount(AccountModel account) async {
    await _api.dio.patch('/accounts/${account.id}/', data: {
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'icon': account.icon,
      'color': account.color,
    });
  }

  Future<void> deleteAccount(String id) async {
    await _api.dio.delete('/accounts/$id/');
  }
}
