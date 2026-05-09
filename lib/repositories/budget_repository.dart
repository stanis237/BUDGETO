import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<List<BudgetModel>> getBudgets(String userId, int month, int year) async {
    final results = await _db.rawQuery('''
      SELECT b.*, c.name as category_name, c.icon as category_icon, c.color as category_color,
        COALESCE((
          SELECT SUM(t.amount) FROM transactions t
          WHERE t.user_id = b.user_id AND t.category_id = b.category_id
            AND strftime('%m', t.date) = ? AND strftime('%Y', t.date) = ?
            AND t.type = 'expense'
        ), 0) as spent
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.user_id = ? AND b.month = ? AND b.year = ?
      ORDER BY c.name ASC
    ''', [
      month.toString().padLeft(2, '0'),
      year.toString(),
      userId,
      month,
      year,
    ]);
    return results.map((e) => BudgetModel.fromMap(e)).toList();
  }

  Future<Map<String, double>> getBudgetSummary(String userId, int month, int year) async {
    final budgets = await getBudgets(userId, month, year);
    final totalBudget = budgets.fold(0.0, (sum, b) => sum + b.amount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spent);
    return {'total': totalBudget, 'spent': totalSpent, 'remaining': totalBudget - totalSpent};
  }

  Future<void> upsertBudget({
    required String userId,
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final existing = await _db.query(
      'budgets',
      where: 'user_id = ? AND category_id = ? AND month = ? AND year = ?',
      whereArgs: [userId, categoryId, month, year],
    );
    if (existing.isNotEmpty) {
      await _db.update('budgets', {'amount': amount},
          'user_id = ? AND category_id = ? AND month = ? AND year = ?',
          [userId, categoryId, month, year]);
    } else {
      await _db.insert('budgets', {
        'id': _uuid.v4(),
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
      });
    }
  }

  Future<void> deleteBudget(String id) async {
    await _db.delete('budgets', 'id = ?', [id]);
  }
}
