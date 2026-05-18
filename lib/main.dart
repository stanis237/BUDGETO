import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'providers/monthly_plan_provider.dart';
import 'services/notification_service.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

import 'core/database/database_init_stub.dart'
    if (dart.library.io) 'core/database/database_init_io.dart'
    if (dart.library.html) 'core/database/database_init_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  initDatabaseFactory();
  
  await initializeDateFormatting('fr_FR', null);
  runApp(const BudgetoApp());
}

class BudgetoApp extends StatelessWidget {
  const BudgetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => MonthlyPlanProvider()),
      ],
      child: MaterialApp(
        title: 'sansnkap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      // Wait a brief moment for auth to init from SharedPreferences
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        if (auth.isLoggedIn && auth.currentUser != null) {
          await context.read<RecurringTransactionProvider>()
              .checkAndProcessRecurringTransactions(auth.currentUser!.id);
          // Actualiser les transactions après génération potentielle
          await context.read<TransactionProvider>().loadAll(auth.currentUser!.id);
        }
        setState(() => _initialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) {
      return const HomeScreen();
    }
    return const WelcomeScreen();
  }
}
