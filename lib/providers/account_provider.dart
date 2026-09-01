import 'package:flutter/material.dart';
import '../models/account.dart';
import '../core/api/api_client.dart';

class AccountProvider with ChangeNotifier {
  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  final ApiClient _api = ApiClient();

  List<AccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;

  double get totalBalance => _accounts.fold(0, (sum, account) => sum + account.balance);

  Future<void> loadAccounts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/accounts/');
      final dynamic responseData = response.data;
      final List data = responseData is Map ? responseData['results'] as List : responseData as List;
      _accounts = data.map((e) => AccountModel.fromMap(e)).toList();
      
      // If no accounts, create a default one
      if (_accounts.isEmpty) {
        await createDefaultAccount(userId);
      }
    } catch (e) {
      print('Error loading accounts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createDefaultAccount(String userId) async {
    try {
      final response = await _api.dio.post('/accounts/', data: {
        'name': 'Espèces',
        'type': 'cash',
        'balance': 0,
        'icon': 'account_balance_wallet',
        'color': '0xFF4CAF50',
      });
      _accounts.add(AccountModel.fromMap(response.data));
    } catch (e) {
      print('Error creating default account: $e');
    }
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      final response = await _api.dio.post('/accounts/', data: {
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'icon': account.icon,
        'color': account.color,
      });
      _accounts.add(AccountModel.fromMap(response.data));
      notifyListeners();
    } catch (e) {
      print('Error adding account: $e');
    }
  }

  Future<void> updateBalance(String accountId, double amount, String type) async {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      double newBalance = _accounts[index].balance;
      if (type == 'income') {
        newBalance += amount;
      } else {
        newBalance -= amount;
      }

      try {
        final response = await _api.dio.patch('/accounts/$accountId/', data: {
          'balance': newBalance,
        });
        _accounts[index] = AccountModel.fromMap(response.data);
        notifyListeners();
      } catch (e) {
        print('Error updating balance: $e');
      }
    }
  }
}
