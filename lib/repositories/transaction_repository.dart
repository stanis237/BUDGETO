import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<List<TransactionModel>> getTransactions(String userId, {int? limit}) async {
    final results = await _db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ?
      ORDER BY t.date DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''', [userId]);
    return results.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      String userId, int month, int year) async {
    final results = await _db.rawQuery('''
      SELECT t.*, c.name as category_name, c.icon as category_icon, c.color as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ?
        AND strftime('%m', t.date) = ? AND strftime('%Y', t.date) = ?
      ORDER BY t.date DESC
    ''', [userId, month.toString().padLeft(2, '0'), year.toString()]);
    return results.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<Map<String, double>> getMonthlySummary(
      String userId, int month, int year) async {
    final results = await _db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE user_id = ?
        AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
      GROUP BY type
    ''', [userId, month.toString().padLeft(2, '0'), year.toString()]);

    double income = 0, expense = 0;
    for (final r in results) {
      if (r['type'] == 'income') income = (r['total'] as num).toDouble();
      if (r['type'] == 'expense') expense = (r['total'] as num).toDouble();
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory(
      String userId, int month, int year) async {
    return _db.rawQuery('''
      SELECT c.id, c.name, c.icon, c.color, SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.type = 'expense'
        AND strftime('%m', t.date) = ? AND strftime('%Y', t.date) = ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [userId, month.toString().padLeft(2, '0'), year.toString()]);
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
      String userId, String type, int month, int year) async {
    return _db.rawQuery('''
      SELECT strftime('%d', date) as day, SUM(amount) as total
      FROM transactions
      WHERE user_id = ? AND type = ?
        AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
      GROUP BY strftime('%d', date)
      ORDER BY day ASC
    ''', [userId, type, month.toString().padLeft(2, '0'), year.toString()]);
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals(
      String userId, String type, int month, int year) async {
    return _db.rawQuery('''
      SELECT strftime('%W', date) as week, SUM(amount) as total
      FROM transactions
      WHERE user_id = ? AND type = ?
        AND strftime('%m', date) = ? AND strftime('%Y', date) = ?
      GROUP BY strftime('%W', date)
      ORDER BY week ASC
    ''', [userId, type, month.toString().padLeft(2, '0'), year.toString()]);
  }

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final results = await _db.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
    );
    return results.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<TransactionModel> addTransaction({
    required String userId,
    required double amount,
    required String type,
    required String categoryId,
    String? description,
    required DateTime date,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(),
      userId: userId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      date: date,
      createdAt: DateTime.now(),
    );
    await _db.insert('transactions', tx.toMap());
    return tx;
  }

  Future<void> deleteTransaction(String id) async {
    await _db.delete('transactions', 'id = ?', [id]);
  }
}
