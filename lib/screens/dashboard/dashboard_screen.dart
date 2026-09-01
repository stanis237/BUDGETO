import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';
import '../transactions/add_transaction_screen.dart';
import '../statistics/statistics_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/export_service.dart';
import '../analytics/subscriptions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TransactionModel> _recent = [];
  bool _loadingRecent = true;
  Map<String, dynamic>? _forecast;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest';
    final txProvider = context.read<TransactionProvider>();
    final data = await txProvider.getRecent(userId, limit: 5);
    
    // Load forecast
    final now = txProvider.selectedMonth;
    final forecast = await AnalyticsService().getBudgetForecast(now.month, now.year);

    if (mounted) {
      setState(() { 
        _recent = data; 
        _loadingRecent = false; 
        _forecast = forecast;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final currency = auth.currency;
    final now = txProvider.selectedMonth;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          final userId = auth.currentUser?.id ?? 'guest';
          await txProvider.loadAll(userId);
          await _loadRecent();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(auth, txProvider, currency, now),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  onPressed: () async {
                    final txProvider = context.read<TransactionProvider>();
                    if (txProvider.transactions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucune transaction à exporter')),
                      );
                      return;
                    }
                    final exportService = ExportService();
                    await exportService.exportToPdf(txProvider.transactions);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Month selector
                  _buildMonthSelector(txProvider, auth),
                  const SizedBox(height: 20),
                  // Income / Expense cards
                  _buildSummaryCards(txProvider, currency),
                  const SizedBox(height: 24),
                  // Forecast Card (Phase 5)
                  if (_forecast != null) ...[
                    _buildForecastCard(_forecast!, currency),
                    const SizedBox(height: 24),
                  ],
                  // Pie chart
                  if (txProvider.expenseByCategory.isNotEmpty) ...[
                    _sectionTitle('Répartition des dépenses', ''),
                    const SizedBox(height: 12),
                    _buildPieChart(txProvider, currency),
                    const SizedBox(height: 24),
                  ],
                  // Recent transactions
                  _sectionTitle('Transactions récentes', 'Voir tout'),
                  const SizedBox(height: 12),
                  if (_loadingRecent)
                    const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  else if (_recent.isEmpty)
                    _buildEmptyState()
                  else
                    ..._recent.map((t) => _buildTransactionItem(t, currency)),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, TransactionProvider txProvider,
      String currency, DateTime now) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bienvenue 👋',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                      Text(auth.currentUser?.name ?? 'Invité',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (auth.currentUser?.name.isNotEmpty == true)
                          ? auth.currentUser!.name[0].toUpperCase()
                          : 'B',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Solde total',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              Text(
                CurrencyFormatter.format(txProvider.balance, currency),
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
              ),
              Text(DateFormatter.formatMonthYear(now),
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(TransactionProvider txProvider, AuthProvider auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => txProvider.changeMonth(auth.currentUser?.id ?? 'guest', -1),
          icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
        ),
        Text(
          DateFormatter.formatMonthYear(txProvider.selectedMonth),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        IconButton(
          onPressed: () => txProvider.changeMonth(auth.currentUser?.id ?? 'guest', 1),
          icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(TransactionProvider txProvider, String currency) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: 'Revenus',
            amount: txProvider.totalIncome,
            currency: currency,
            icon: Icons.arrow_downward_rounded,
            color: AppTheme.income,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _summaryCard(
            label: 'Dépenses',
            amount: txProvider.totalExpense,
            currency: currency,
            icon: Icons.arrow_upward_rounded,
            color: AppTheme.expense,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required double amount,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  CurrencyFormatter.format(amount, currency),
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> forecast, String currency) {
    final projected = forecast['projected_end_of_month'] as num? ?? 0;
    final daily = forecast['daily_average'] as num? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2575FC).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('Prévision IA (Fin du mois)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dépense estimée', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  Text(CurrencyFormatter.format(projected.toDouble(), currency), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Moy. journalière', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  Text(CurrencyFormatter.format(daily.toDouble(), currency), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Détecter les abonnements cachés'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPieChart(TransactionProvider txProvider, String currency) {
    final data = txProvider.expenseByCategory;
    final total = data.fold(0.0, (s, e) => s + (e['total'] as num).toDouble());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: data.asMap().entries.map((entry) {
                  final e = entry.value;
                  final color = Color(int.parse(e['color']));
                  final pct = total > 0 ? (e['total'] as num) / total * 100 : 0.0;
                  return PieChartSectionData(
                    value: (e['total'] as num).toDouble(),
                    color: color,
                    radius: 30,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: GoogleFonts.poppins(
                        fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.take(4).map((e) {
                final color = Color(int.parse(e['color']));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e['name'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        CurrencyFormatter.format((e['total'] as num).toDouble(), currency),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t, String currency) {
    final isIncome = t.type == 'income';
    final color = isIncome ? AppTheme.income : AppTheme.expense;
    final catColor = t.categoryColor != null
        ? Color(int.parse(t.categoryColor!))
        : AppTheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFromKey(t.categoryIcon), color: catColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.categoryName ?? 'Autre',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(DateFormatter.format(t.date),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount, currency)}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
          const SizedBox(height: 12),
          Text('Aucune transaction ce mois-ci',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddTransactionScreen(),
                  ).then((_) => _loadRecent());
                },
                icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
                label: Text('Ajouter',
                    style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // Navigate to AI Assistant instead of local OCR
                  Navigator.pushNamed(context, '/ai-assistant'); // or push
                },
                icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                label: Text('Assistant IA',
                    style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        if (action.isNotEmpty)
          TextButton(
            onPressed: () {},
            child: Text(action,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  IconData _iconFromKey(String? key) {
    switch (key) {
      case 'food': return Icons.restaurant_rounded;
      case 'transport': return Icons.directions_car_rounded;
      case 'home': return Icons.home_rounded;
      case 'leisure': return Icons.sports_esports_rounded;
      case 'health': return Icons.favorite_rounded;
      case 'salary': return Icons.account_balance_wallet_rounded;
      case 'freelance': return Icons.laptop_mac_rounded;
      case 'invest': return Icons.trending_up_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}
