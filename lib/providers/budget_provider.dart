import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repo = BudgetRepository();

  List<BudgetModel> _budgets = [];
  Map<String, double> _summary = {};
  bool _isLoading = false;
  DateTime _selectedMonth = DateTime.now();

  List<BudgetModel> get budgets => _budgets;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  double get totalBudget => _summary['total'] ?? 0;
  double get totalSpent => _summary['spent'] ?? 0;
  double get remaining => _summary['remaining'] ?? 0;
  double get percentage => totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0;

  Future<void> loadBudgets(String userId) async {
    _isLoading = true;
    notifyListeners();
    _budgets = await _repo.getBudgets(userId, _selectedMonth.month, _selectedMonth.year);
    _summary = await _repo.getBudgetSummary(userId, _selectedMonth.month, _selectedMonth.year);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> upsertBudget({
    required String userId,
    required String categoryId,
    required double amount,
  }) async {
    await _repo.upsertBudget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      month: _selectedMonth.month,
      year: _selectedMonth.year,
    );
    await loadBudgets(userId);
  }

  Future<void> deleteBudget(String id, String userId) async {
    await _repo.deleteBudget(id);
    await loadBudgets(userId);
  }

  void changeMonth(String userId, int delta) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    loadBudgets(userId);
  }
}
