import '../core/api/api_client.dart';
import '../models/recurring_transaction.dart';
import 'package:intl/intl.dart';

class RecurringTransactionRepository {
  final ApiClient _api = ApiClient();

  Future<List<RecurringTransactionModel>> getRecurringTransactions(String userId) async {
    try {
      final response = await _api.dio.get('/recurring-transactions/');
      final data = response.data is Map ? response.data['results'] as List : response.data as List;
      return data.map((e) => RecurringTransactionModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<RecurringTransactionModel> addRecurringTransaction({
    required String userId,
    required double amount,
    required String type,
    required String categoryId,
    required String accountId,
    String? description,
    required String period,
    required DateTime startDate,
  }) async {
    final response = await _api.dio.post('/recurring-transactions/', data: {
      'amount': amount,
      'type': type,
      'category': categoryId,
      'account': accountId,
      'description': description,
      'period': period,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
    });
    return RecurringTransactionModel.fromMap(response.data);
  }

  Future<void> updateNextDate(String id, DateTime newNextDate) async {
    // Actually the processing handles nextDate automatically. 
    // If we need to manually update, we use PATCH
    await _api.dio.patch('/recurring-transactions/$id/', data: {
      'next_date': DateFormat('yyyy-MM-dd').format(newNextDate),
    });
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _api.dio.delete('/recurring-transactions/$id/');
  }
}
