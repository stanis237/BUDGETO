import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/monthly_plan_provider.dart';

class MonthlyPlanScreen extends StatefulWidget {
  const MonthlyPlanScreen({super.key});

  @override
  State<MonthlyPlanScreen> createState() => _MonthlyPlanScreenState();
}

class _MonthlyPlanScreenState extends State<MonthlyPlanScreen> {
  final _needsController = TextEditingController();
  final _expectationsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlan();
    });
  }

  void _loadPlan() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    await context.read<MonthlyPlanProvider>().loadPlan(userId, _selectedDate);
    final plan = context.read<MonthlyPlanProvider>().currentPlan;
    if (plan != null) {
      _needsController.text = plan.needs.toStringAsFixed(2);
      _expectationsController.text = plan.expectations.toStringAsFixed(2);
    } else {
      _needsController.text = '';
      _expectationsController.text = '';
    }
  }

  void _savePlan() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final needs = double.tryParse(_needsController.text) ?? 0;
    final expectations = double.tryParse(_expectationsController.text) ?? 0;

    await context.read<MonthlyPlanProvider>().savePlan(userId, _selectedDate, needs, expectations);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planification sauvegardée !', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primary,
        )
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    });
    _loadPlan();
  }

  String _monthName(int month) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<AuthProvider>().currency;
    final currencySymbol = CurrencyFormatter.symbol(currency);
    final isLoading = context.watch<MonthlyPlanProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Planification Mensuelle', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Text('Définissez vos objectifs pour ce mois afin que nous puissions suivre vos progrès intelligemment.',
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Needs input
            Text('Vos besoins (Dépenses incompressibles)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _needsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ex: 1200.00',
                suffixText: currencySymbol,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Expectations input
            Text('Vos attentes (Objectif d\'épargne ou reste à vivre)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _expectationsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ex: 300.00',
                suffixText: currencySymbol,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Enregistrer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
