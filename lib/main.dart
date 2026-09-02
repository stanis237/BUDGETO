import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/account_provider.dart';
import 'providers/recurring_transaction_provider.dart';
import 'providers/monthly_plan_provider.dart';
import 'providers/project_provider.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

// Removed database init imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  await initializeDateFormatting('fr_FR', null);
  runApp(const StankapApp());
}

class StankapApp extends StatelessWidget {
  const StankapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => RecurringTransactionProvider()),
        ChangeNotifierProvider(create: (_) => MonthlyPlanProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'Stankap',
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
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final auth = context.read<AuthProvider>();
    // Wait a brief moment for auth to init from SharedPreferences
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      if (auth.isLoggedIn && auth.currentUser != null) {
        final security = SecurityService();
        final needsBio = await security.isBiometricEnabled();
        
        if (needsBio) {
          final success = await security.authenticate();
          if (!success) {
            // If failed, we might want to stay on a lock screen or allow retry
            // For now, we'll just set initialized but not authenticated
            setState(() {
              _initialized = true;
              _authenticated = false;
            });
            return;
          }
        }
        
        _authenticated = true;
        await context.read<RecurringTransactionProvider>()
            .checkAndProcessRecurringTransactions(auth.currentUser!.id);
        await context.read<TransactionProvider>().loadAll(auth.currentUser!.id);
      }
      setState(() => _initialized = true);
    }
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
      if (!_authenticated) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppTheme.primary),
                const SizedBox(height: 24),
                const Text('Application Verrouillée', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _initApp,
                  child: const Text('Déverrouiller'),
                ),
              ],
            ),
          ),
        );
      }
      return const HomeScreen();
    }
    return const WelcomeScreen();
  }
}
