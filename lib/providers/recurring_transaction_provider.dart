import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../repositories/recurring_transaction_repository.dart';
import '../repositories/transaction_repository.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final RecurringTransactionRepository _repo = RecurringTransactionRepository();
  final TransactionRepository _txRepo = TransactionRepository();

  List<RecurringTransactionModel> _recurringTransactions = [];
  bool _isLoading = false;

  List<RecurringTransactionModel> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;

  Future<void> loadRecurringTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();
    _recurringTransactions = await _repo.getRecurringTransactions(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecurringTransaction({
    required String userId,
    required double amount,
    required String type,
    required String categoryId,
    String? description,
    required String period,
    required DateTime startDate,
  }) async {
    await _repo.addRecurringTransaction(
      userId: userId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      period: period,
      startDate: startDate,
    );
    await loadRecurringTransactions(userId);
  }

  Future<void> deleteRecurringTransaction(String id, String userId) async {
    await _repo.deleteRecurringTransaction(id);
    await loadRecurringTransactions(userId);
  }

  /// Vérifie s'il y a des transactions récurrentes échues, les génère et met à jour leur date
  Future<void> checkAndProcessRecurringTransactions(String userId) async {
    final recurringTxs = await _repo.getRecurringTransactions(userId);
    final now = DateTime.now();

    bool hasGenerated = false;

    for (var rt in recurringTxs) {
      DateTime currentDateToProcess = rt.nextDate;

      // Tant que la date de la prochaine exécution est passée ou aujourd'hui
      while (currentDateToProcess.isBefore(now) || isSameDay(currentDateToProcess, now)) {
        // Générer une transaction standard
        await _txRepo.addTransaction(
          userId: userId,
          amount: rt.amount,
          type: rt.type,
          categoryId: rt.categoryId,
          description: rt.description ?? 'Abonnement/Récurrent',
          date: currentDateToProcess,
        );
        hasGenerated = true;

        // Calculer la prochaine date en fonction de la période
        currentDateToProcess = _calculateNextDate(currentDateToProcess, rt.period);
      }

      // Mettre à jour la date en base si on a généré au moins une transaction
      if (currentDateToProcess != rt.nextDate) {
        await _repo.updateNextDate(rt.id, currentDateToProcess);
      }
    }

    if (hasGenerated) {
      // Recharger pour que l'UI affiche les nouvelles données si besoin
      await loadRecurringTransactions(userId);
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
