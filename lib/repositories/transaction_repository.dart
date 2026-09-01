import '../core/api/api_client.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';

class TransactionRepository {
  final ApiClient _api = ApiClient();

  Future<List<TransactionModel>> getTransactions(String userId, {int? limit}) async {
    try {
      final response = await _api.dio.get('/transactions/');
      final data = response.data['results'] as List; // Pagination wrapper
      return data.map((e) => TransactionModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<TransactionModel>> getTransactionsByMonth(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/transactions/', queryParameters: {
        'month': month,
        'year': year,
      });
      // Handle pagination or straight list
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => TransactionModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>> getMonthlySummary(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/transactions/summary/', queryParameters: {
        'month': month,
        'year': year,
      });
      return {
        'income': (response.data['income'] as num).toDouble(),
        'expense': (response.data['expense'] as num).toDouble(),
        'balance': (response.data['balance'] as num).toDouble(),
      };
    } catch (e) {
      return {'income': 0, 'expense': 0, 'balance': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory(String userId, int month, int year) async {
    try {
      final response = await _api.dio.get('/transactions/by-category/', queryParameters: {
        'month': month,
        'year': year,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(String userId, String type, int month, int year) async {
    try {
      final response = await _api.dio.get('/transactions/daily-totals/', queryParameters: {
        'type': type,
        'month': month,
        'year': year,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals(String userId, String type, int month, int year) async {
    try {
      final response = await _api.dio.get('/transactions/weekly-totals/', queryParameters: {
        'type': type,
        'month': month,
        'year': year,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final params = type != null ? {'type': type} : null;
      final response = await _api.dio.get('/categories/', queryParameters: params);
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => CategoryModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<TransactionModel> addTransaction({
    required String userId, // No longer strictly needed for API request
    required double amount,
    required String type,
    required String categoryId,
    required String accountId,
    String? description,
    required DateTime date,
  }) async {
    final response = await _api.dio.post('/transactions/', data: {
      'amount': amount,
      'type': type,
      'category': categoryId,
      'account': accountId,
      'description': description,
      'date': DateFormat('yyyy-MM-dd').format(date),
    });
    return TransactionModel.fromMap(response.data);
  }

  Future<void> deleteTransaction(String id) async {
    await _api.dio.delete('/transactions/$id/');
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final response = await _api.dio.get('/transactions/$id/');
      return TransactionModel.fromMap(response.data);
    } catch (e) {
      return null;
    }
  }
}
