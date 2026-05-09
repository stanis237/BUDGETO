import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/budget.dart';
import '../../models/category.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final auth = context.watch<AuthProvider>();
    final currency = auth.currency;
    final userId = auth.currentUser?.id ?? 'guest';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Budgets', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _showAddBudgetDialog(context, userId, currency),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => budgetProvider.loadBudgets(userId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector
              _buildMonthSelector(budgetProvider, userId),
              const SizedBox(height: 20),

              // Global summary
              _buildGlobalSummary(budgetProvider, currency),
              const SizedBox(height: 24),

              // Budget list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Par catégorie',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _showAddBudgetDialog(context, userId, currency),
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppTheme.primary),
                    label: Text('Ajouter',
                        style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (budgetProvider.isLoading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              else if (budgetProvider.budgets.isEmpty)
                _buildEmpty(context, userId, currency)
              else
                ...budgetProvider.budgets.map((b) => _buildBudgetCard(b, currency, userId)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BudgetProvider provider, String userId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => provider.changeMonth(userId, -1),
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
        ),
        Text(
          DateFormatter.formatMonthYear(provider.selectedMonth),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        IconButton(
          onPressed: () => provider.changeMonth(userId, 1),
          icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildGlobalSummary(BudgetProvider provider, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget mensuel total',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.format(provider.totalBudget, currency),
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryInfo(
                  'Dépensé',
                  CurrencyFormatter.format(provider.totalSpent, currency),
                  AppTheme.expense,
                ),
              ),
              Expanded(
                child: _summaryInfo(
                  'Restant',
                  CurrencyFormatter.format(provider.remaining, currency),
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: provider.percentage,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: provider.percentage > 0.8
                  ? AppTheme.expense
                  : Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('${(provider.percentage * 100).toStringAsFixed(0)}% du budget utilisé',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _summaryInfo(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
      Text(value,
          style: GoogleFonts.poppins(
              color: color, fontSize: 15, fontWeight: FontWeight.w700)),
    ],
  );

  Widget _buildBudgetCard(BudgetModel b, String currency, String userId) {
    final catColor = b.categoryColor != null
        ? Color(int.parse(b.categoryColor!))
        : AppTheme.primary;
    final isOverBudget = b.spent > b.amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFromKey(b.categoryIcon), color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.categoryName ?? 'Catégorie',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      '${CurrencyFormatter.format(b.spent, currency)} / ${CurrencyFormatter.format(b.amount, currency)}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(b.percentage * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isOverBudget ? AppTheme.error : AppTheme.textPrimary),
                  ),
                  Text(
                    isOverBudget ? 'Dépassé!' : 'Restant: ${CurrencyFormatter.format(b.remaining, currency)}',
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: isOverBudget ? AppTheme.error : AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _showEditBudgetDialog(context, b, currency, userId);
                  if (v == 'delete') context.read<BudgetProvider>().deleteBudget(b.id, userId);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit',
                      child: Text('Modifier', style: GoogleFonts.poppins(fontSize: 13))),
                  PopupMenuItem(value: 'delete',
                      child: Text('Supprimer',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.error))),
                ],
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textHint, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: b.percentage,
            backgroundColor: AppTheme.divider,
            progressColor: isOverBudget ? AppTheme.error : catColor,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String userId, String currency) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline_rounded, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text('Aucun budget défini',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAddBudgetDialog(context, userId, currency),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un budget'),
          ),
        ],
      ),
    ),
  );

  Future<void> _showAddBudgetDialog(
      BuildContext context, String userId, String currency) async {
    final categories = await context.read<TransactionProvider>()
        .getCategoriesByType('expense');
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetFormSheet(
          categories: categories, userId: userId, currency: currency),
    );
  }

  Future<void> _showEditBudgetDialog(
      BuildContext context, BudgetModel b, String currency, String userId) async {
    final ctrl = TextEditingController(text: b.amount.toStringAsFixed(2));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifier le budget', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Montant (${CurrencyFormatter.symbol(currency)})',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (amount != null && amount > 0) {
                context.read<BudgetProvider>().upsertBudget(
                    userId: userId, categoryId: b.categoryId, amount: amount);
                Navigator.pop(context);
              }
            },
            child: Text('Enregistrer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  IconData _iconFromKey(String? key) {
    switch (key) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'home': return Icons.home_rounded;
      case 'leisure': return Icons.sports_esports_rounded;
      case 'health': return Icons.favorite_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}

class _BudgetFormSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String userId;
  final String currency;
  const _BudgetFormSheet(
      {required this.categories, required this.userId, required this.currency});
  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  String? _selectedCategoryId;
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Nouveau budget',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text('Catégorie',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: widget.categories.map((cat) {
              final isSelected = _selectedCategoryId == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryId = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? cat.colorValue.withOpacity(0.15) : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? cat.colorValue : Colors.transparent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.iconData, color: cat.colorValue, size: 16),
                      const SizedBox(width: 6),
                      Text(cat.name,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected ? cat.colorValue : AppTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Montant (${CurrencyFormatter.symbol(widget.currency)})',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixText: '${CurrencyFormatter.symbol(widget.currency)} ',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
                if (_selectedCategoryId != null && amount != null && amount > 0) {
                  context.read<BudgetProvider>().upsertBudget(
                      userId: widget.userId,
                      categoryId: _selectedCategoryId!,
                      amount: amount);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('Enregistrer',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
