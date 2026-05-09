import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/budgets_screen.dart';
import '../profile/profile_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../../services/notification_service.dart';
import '../../providers/monthly_plan_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest';
    await context.read<TransactionProvider>().loadAll(userId);
    context.read<BudgetProvider>().loadBudgets(userId);
    context.read<GoalProvider>().loadGoals(userId);
    
    // Load monthly plan and schedule notification
    if (userId != 'guest' && mounted) {
      final now = DateTime.now();
      await context.read<MonthlyPlanProvider>().loadPlan(userId, now);
      _scheduleIntelligentNotification();
    }
  }

  void _scheduleIntelligentNotification() {
    if (!mounted) return;
    final plan = context.read<MonthlyPlanProvider>().currentPlan;
    final transactions = context.read<TransactionProvider>().transactions;
    
    // Calculate spent this week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    double spentThisWeek = 0;
    for (var t in transactions) {
      if (t.type == 'expense' && t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        spentThisWeek += t.amount;
      }
    }
    
    NotificationService().scheduleIntelligentWeeklyNotification(
      spentThisWeek: spentThisWeek,
      needs: plan?.needs ?? 0,
      expectations: plan?.expectations ?? 0,
    );
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _openAddTransaction();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionScreen(),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: [
          const DashboardScreen(),
          const TransactionsScreen(),
          const SizedBox(),
          const BudgetsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppTheme.floatingShadow,
        ),
        child: FloatingActionButton(
          onPressed: _openAddTransaction,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Accueil'),
              _navItem(1, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Transactions'),
              const SizedBox(width: 56),
              _navItem(3, Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'Budgets'),
              _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppTheme.primary : AppTheme.textHint, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppTheme.primary : AppTheme.textHint,
                )),
          ],
        ),
      ),
    );
  }
}
