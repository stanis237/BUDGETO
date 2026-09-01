import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/analytics_service.dart';
import '../../core/utils/currency_formatter.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _subscriptions = [];
  double _totalEstimated = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final data = await AnalyticsService().getDetectedSubscriptions();
    if (mounted) {
      setState(() {
        if (data != null) {
          _subscriptions = data['detected_subscriptions'] ?? [];
          _totalEstimated = (data['total_monthly_estimated'] as num?)?.toDouble() ?? 0.0;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Abonnements Détectés', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success),
          const SizedBox(height: 16),
          Text(
            "Aucun abonnement fantôme détecté !",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Vos finances sont impeccables.",
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.primary, size: 32),
              const SizedBox(height: 12),
              Text(
                "L'IA a détecté des paiements récurrents qui pourraient être des abonnements.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 16),
              Text(
                "Total estimé par mois: ${CurrencyFormatter.format(_totalEstimated, 'EUR')}",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._subscriptions.map((sub) => _buildSubscriptionCard(sub)),
      ],
    );
  }

  Widget _buildSubscriptionCard(dynamic sub) {
    final desc = sub['description'] ?? 'Inconnu';
    final amount = (sub['amount'] as num).toDouble();
    final count = sub['count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.expense.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.autorenew_rounded, color: AppTheme.expense),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                Text(
                  "Détecté $count fois récemment",
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textHint),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount, 'EUR'),
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.expense),
          ),
        ],
      ),
    );
  }
}
