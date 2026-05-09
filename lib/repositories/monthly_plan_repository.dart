import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/monthly_plan.dart';

class MonthlyPlanRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  Future<MonthlyPlan?> getPlan(String userId, int month, int year) async {
    final results = await _db.query(
      'monthly_plans',
      where: 'user_id = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year],
    );

    if (results.isEmpty) return null;
    return MonthlyPlan.fromMap(results.first);
  }

  Future<MonthlyPlan> savePlan(String userId, int month, int year, double needs, double expectations) async {
    final existingPlan = await getPlan(userId, month, year);

    if (existingPlan != null) {
      final updatedPlan = MonthlyPlan(
        id: existingPlan.id,
        userId: userId,
        month: month,
        year: year,
        needs: needs,
        expectations: expectations,
        createdAt: existingPlan.createdAt,
      );
      await _db.update(
        'monthly_plans',
        updatedPlan.toMap(),
        'id = ?',
        [existingPlan.id],
      );
      return updatedPlan;
    } else {
      final newPlan = MonthlyPlan(
        id: _uuid.v4(),
        userId: userId,
        month: month,
        year: year,
        needs: needs,
        expectations: expectations,
        createdAt: DateTime.now(),
      );
      await _db.insert('monthly_plans', newPlan.toMap());
      return newPlan;
    }
  }
}
