import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  Map<String, double> _monthlySummary = {};
  List<Map<String, dynamic>> _expenseByCategory = [];
  bool _isLoading = false;

  DateTime _selectedMonth = DateTime.now();

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  Map<String, double> get monthlySummary => _monthlySummary;
  List<Map<String, dynamic>> get expenseByCategory => _expenseByCategory;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  double get totalIncome => _monthlySummary['income'] ?? 0;
  double get totalExpense => _monthlySummary['expense'] ?? 0;
  double get balance => _monthlySummary['balance'] ?? 0;

  Future<void> loadAll(String userId) async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _loadTransactions(userId),
      _loadCategories(),
      _loadSummary(userId),
      _loadExpenseByCategory(userId),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTransactions(String userId) async {
    _transactions = await _repo.getTransactionsByMonth(
        userId, _selectedMonth.month, _selectedMonth.year);
  }

  Future<void> _loadCategories() async {
    _categories = await _repo.getCategories();
  }

  Future<void> _loadSummary(String userId) async {
    _monthlySummary = await _repo.getMonthlySummary(
        userId, _selectedMonth.month, _selectedMonth.year);
  }

  Future<void> _loadExpenseByCategory(String userId) async {
    _expenseByCategory = await _repo.getExpenseByCategory(
        userId, _selectedMonth.month, _selectedMonth.year);
  }

  Future<List<TransactionModel>> getRecent(String userId, {int limit = 5}) {
    return _repo.getTransactions(userId, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
      String userId, String type) {
    return _repo.getDailyTotals(
        userId, type, _selectedMonth.month, _selectedMonth.year);
  }

  Future<List<CategoryModel>> getCategoriesByType(String type) {
    return _repo.getCategories(type: type);
  }

  Future<void> addTransaction({
    required String userId,
    required double amount,
    required String type,
    required String categoryId,
    String? description,
    required DateTime date,
  }) async {
    await _repo.addTransaction(
      userId: userId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      date: date,
    );
    await loadAll(userId);
  }

  Future<void> deleteTransaction(String id, String userId) async {
    await _repo.deleteTransaction(id);
    await loadAll(userId);
  }

  void changeMonth(String userId, int delta) {
    _selectedMonth = DateTime(
        _selectedMonth.year, _selectedMonth.month + delta);
    loadAll(userId);
  }

  Future<List<TransactionModel>> searchTransactions(
      String userId, String query) async {
    final all = await _repo.getTransactions(userId);
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((t) {
      return (t.description?.toLowerCase().contains(q) ?? false) ||
          (t.categoryName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
