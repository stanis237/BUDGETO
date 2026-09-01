import '../models/transaction.dart';
import '../models/budget.dart';

/// Financial Health Service — Stankap Innovation Engine
///
/// Calculates:
/// - [healthScore] 0-100: overall financial wellness
/// - [ecoScore] 0-100: environmental spending impact
/// - [velocityPercent] 0-1+: spending pace vs ideal
/// - [insights]: AI-style personalized recommendations
class FinancialHealthService {
  // Eco-impact weights per category (lower = more eco-friendly)
  static const Map<String, double> _ecoImpact = {
    'cat_transport': 0.8,   // high impact
    'cat_food': 0.4,        // medium
    'cat_home': 0.5,        // medium
    'cat_leisure': 0.2,     // low
    'cat_health': 0.1,      // very low
    'cat_other_exp': 0.3,
    'cat_salary': 0.0,
    'cat_freelance': 0.0,
    'cat_invest': 0.0,
    'cat_other_inc': 0.0,
  };

  /// Computes the financial health score and related metrics.
  FinancialHealthResult compute({
    required double totalIncome,
    required double totalExpense,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime month,
  }) {
    final now = DateTime.now();
    final daysInMonth = _daysInMonth(month.year, month.month);
    final daysPassed = (month.month == now.month && month.year == now.year)
        ? now.day
        : daysInMonth;

    // ── 1. Savings Ratio Score (40 pts) ──────────────────────────────────
    double savingsScore = 0;
    if (totalIncome > 0) {
      final ratio = (totalIncome - totalExpense) / totalIncome;
      // Ideal: save 20%+ = full score
      savingsScore = (ratio.clamp(0.0, 0.5) / 0.5 * 40).clamp(0.0, 40.0);
    }

    // ── 2. Budget Compliance Score (30 pts) ──────────────────────────────
    double budgetScore = 30; // start full, deduct per overage
    if (budgets.isNotEmpty) {
      int overBudget = budgets.where((b) => b.percentage >= 1.0).length;
      budgetScore = ((budgets.length - overBudget) / budgets.length * 30)
          .clamp(0.0, 30.0);
    }

    // ── 3. Spending Regularity Score (20 pts) ────────────────────────────
    double regularityScore = 10; // base
    if (transactions.isNotEmpty) {
      // Bonus if user records transactions regularly (at least 1 every 3 days)
      final expDays = transactions
          .where((t) => t.type == 'expense')
          .map((t) => t.date.day)
          .toSet()
          .length;
      final coverage = expDays / (daysPassed / 3).ceil();
      regularityScore = (coverage * 20).clamp(0.0, 20.0);
    }

    // ── 4. Income Coverage Score (10 pts) ────────────────────────────────
    final incomeScore = totalIncome > 0 ? 10.0 : 0.0;

    final health = (savingsScore + budgetScore + regularityScore + incomeScore)
        .clamp(0.0, 100.0);

    // ── Eco Score ─────────────────────────────────────────────────────────
    double ecoScore = 100;
    if (transactions.isNotEmpty && totalExpense > 0) {
      double weightedImpact = 0;
      double totalWeight = 0;
      for (final t in transactions.where((tx) => tx.type == 'expense')) {
        final impact = _ecoImpact[t.categoryId] ?? 0.3;
        weightedImpact += impact * t.amount;
        totalWeight += t.amount;
      }
      if (totalWeight > 0) {
        ecoScore = ((1 - (weightedImpact / totalWeight)) * 100).clamp(0.0, 100.0);
      }
    }

    // ── Velocity (spending pace) ──────────────────────────────────────────
    double velocity = 0;
    if (daysPassed > 0 && daysInMonth > 0 && totalIncome > 0) {
      final idealDailySpend = totalIncome / daysInMonth;
      final actualDailySpend = totalExpense / daysPassed;
      velocity = (actualDailySpend / idealDailySpend).clamp(0.0, 2.0);
    }

    // ── Insights ──────────────────────────────────────────────────────────
    final insights = _generateInsights(
      healthScore: health,
      savingsScore: savingsScore,
      budgetScore: budgetScore,
      velocity: velocity,
      ecoScore: ecoScore,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      budgets: budgets,
    );

    return FinancialHealthResult(
      healthScore: health,
      ecoScore: ecoScore,
      velocity: velocity,
      level: _level(health),
      insights: insights,
      savingsRatio: totalIncome > 0
          ? ((totalIncome - totalExpense) / totalIncome).clamp(-1.0, 1.0)
          : 0.0,
    );
  }

  HealthLevel _level(double score) {
    if (score >= 80) return HealthLevel.excellent;
    if (score >= 60) return HealthLevel.good;
    if (score >= 40) return HealthLevel.warning;
    return HealthLevel.danger;
  }

  List<String> _generateInsights({
    required double healthScore,
    required double savingsScore,
    required double budgetScore,
    required double velocity,
    required double ecoScore,
    required double totalIncome,
    required double totalExpense,
    required List<BudgetModel> budgets,
  }) {
    final tips = <String>[];

    if (savingsScore < 20) {
      tips.add("💡 Essayez d'épargner au moins 10% de vos revenus chaque mois.");
    } else if (savingsScore >= 36) {
      tips.add("🎉 Excellent ! Vous épargnez plus de 20% de vos revenus.");
    }

    if (budgetScore < 20 && budgets.isNotEmpty) {
      final overBudget = budgets.where((b) => b.percentage >= 1.0).toList();
      if (overBudget.isNotEmpty) {
        tips.add(
            "⚠️ Budget dépassé dans ${overBudget.length} catégorie(s). Réduisez vos dépenses en ${overBudget.first.categoryName ?? 'cette catégorie'}.");
      }
    }

    if (velocity > 1.2) {
      tips.add("🔥 Vous dépensez 20% plus vite que prévu. Ralentissez en fin de mois !");
    } else if (velocity < 0.7 && velocity > 0) {
      tips.add("✨ Bonne cadence ! Vous êtes en avance sur votre plan mensuel.");
    }

    if (ecoScore >= 75) {
      tips.add("🌿 Vos dépenses sont éco-responsables. Continuez comme ça !");
    } else if (ecoScore < 50) {
      tips.add("🌍 Réduisez vos dépenses en transport pour un meilleur éco-score.");
    }

    if (totalIncome == 0) {
      tips.add("📥 Aucun revenu enregistré ce mois-ci. N'oubliez pas de les saisir !");
    }

    if (tips.isEmpty) {
      tips.add("👍 Votre situation financière est bien maîtrisée ce mois-ci.");
    }

    return tips;
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}

enum HealthLevel { excellent, good, warning, danger }

class FinancialHealthResult {
  final double healthScore;   // 0-100
  final double ecoScore;      // 0-100
  final double velocity;      // 0-2+ (1 = ideal pace)
  final HealthLevel level;
  final List<String> insights;
  final double savingsRatio;  // -1 to 1

  const FinancialHealthResult({
    required this.healthScore,
    required this.ecoScore,
    required this.velocity,
    required this.level,
    required this.insights,
    required this.savingsRatio,
  });

  String get levelLabel {
    switch (level) {
      case HealthLevel.excellent: return 'Excellent 🏆';
      case HealthLevel.good: return 'Bon 👍';
      case HealthLevel.warning: return 'Attention ⚠️';
      case HealthLevel.danger: return 'Danger 🔴';
    }
  }
}
