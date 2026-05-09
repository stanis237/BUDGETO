import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/recurring_transaction.dart';

class RecurringTransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<List<RecurringTransactionModel>> getRecurringTransactions(String userId) async {
    final results = await _db.rawQuery('''
      SELECT rt.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM recurring_transactions rt
      LEFT JOIN categories c ON rt.category_id = c.id
      WHERE rt.user_id = ?
      ORDER BY rt.next_date ASC
    ''', [userId]);
    return results.map((e) => RecurringTransactionModel.fromMap(e)).toList();
  }

  Future<RecurringTransactionModel> addRecurringTransaction({
    required String userId,
    required double amount,
    required String type,
    required String categoryId,
    String? description,
    required String period,
    required DateTime startDate,
  }) async {
    final id = _uuid.v4();
    final nextDate = _calculateNextDate(startDate, period);
    
    final rt = RecurringTransactionModel(
      id: id,
      userId: userId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      period: period,
      startDate: startDate,
      nextDate: nextDate,
      createdAt: DateTime.now(),
    );
    await _db.insert('recurring_transactions', rt.toMap());
    return rt;
  }

  Future<void> updateNextDate(String id, DateTime newNextDate) async {
    await _db.rawQuery(
      'UPDATE recurring_transactions SET next_date = ? WHERE id = ?',
      [newNextDate.toIso8601String(), id],
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _db.delete('recurring_transactions', 'id = ?', [id]);
  }

  DateTime _calculateNextDate(DateTime from, String period) {
    switch (period) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from;
    }
  }
}
