import 'package:flutter/foundation.dart';
import '../models/monthly_plan.dart';
import '../repositories/monthly_plan_repository.dart';

class MonthlyPlanProvider with ChangeNotifier {
  final MonthlyPlanRepository _repository = MonthlyPlanRepository();

  MonthlyPlan? _currentPlan;
  bool _isLoading = false;

  MonthlyPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;

  Future<void> loadPlan(String userId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    _currentPlan = await _repository.getPlan(userId, date.month, date.year);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePlan(String userId, DateTime date, double needs, double expectations) async {
    _currentPlan = await _repository.savePlan(userId, date.month, date.year, needs, expectations);
    notifyListeners();
  }
}
