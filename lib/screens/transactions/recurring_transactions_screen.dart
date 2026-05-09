import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recurring_transaction_provider.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<RecurringTransactionProvider>().loadRecurringTransactions(userId);
      }
    });
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'daily': return 'Quotidien';
      case 'weekly': return 'Hebdomadaire';
      case 'monthly': return 'Mensuel';
      case 'yearly': return 'Annuel';
      default: return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringTransactionProvider>();
    final currency = context.read<AuthProvider>().currency;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Abonnements & Récurrents',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : provider.recurringTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: provider.recurringTransactions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final rt = provider.recurringTransactions[index];
                    final isIncome = rt.type == 'income';
                    final color = Color(int.parse(rt.categoryColor ?? '0xFF9E9E9E'));

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getIconData(rt.categoryIcon),
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rt.description ?? rt.categoryName ?? 'Transaction',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prochain : ${DateFormat('dd MMM yyyy', 'fr_FR').format(rt.nextDate)} • ${_getPeriodLabel(rt.period)}',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(rt.amount, currency)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: isIncome ? AppTheme.income : AppTheme.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, rt.id),
                                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.autorenew_rounded, size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune transaction récurrente',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un abonnement ou un salaire\nrécurrent lors de l\'ajout d\'une transaction.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment annuler cette récurrence ? Les transactions déjà créées ne seront pas supprimées.',
            style: GoogleFonts.poppins(fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        await context.read<RecurringTransactionProvider>().deleteRecurringTransaction(id, userId);
      }
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'home': return Icons.home_rounded;
      case 'leisure': return Icons.sports_esports_rounded;
      case 'health': return Icons.favorite_rounded;
      case 'salary': return Icons.account_balance_wallet_rounded;
      case 'freelance': return Icons.computer_rounded;
      case 'invest': return Icons.trending_up_rounded;
      case 'other': return Icons.category_rounded;
      default: return Icons.category_rounded;
    }
  }
}
