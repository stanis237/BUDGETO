import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();r 
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final currency = auth.currency;
    final userId = auth.currentUser?.id ?? 'guest';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Statistiques',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Dépenses'), Tab(text: 'Revenus')],
        ),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => txProvider.changeMonth(userId, -1),
                  icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
                ),
                Text(DateFormatter.formatMonthYear(txProvider.selectedMonth),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                IconButton(
                  onPressed: () => txProvider.changeMonth(userId, 1),
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContent(txProvider, currency, 'expense', userId),
                _buildContent(txProvider, currency, 'income', userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(TransactionProvider txProvider, String currency,
      String type, String userId) {
    final total = type == 'expense' ? txProvider.totalExpense : txProvider.totalIncome;
    final color = type == 'expense' ? AppTheme.expense : AppTheme.income;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: txProvider.getDailyTotals(userId, type),
      builder: (ctx, snap) {
        final data = snap.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      type == 'expense'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: color, size: 28,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type == 'expense' ? 'Total dépenses' : 'Total revenus',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          CurrencyFormatter.format(total, currency),
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.w800, color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bar chart
              Text('Évolution journalière',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              if (data.isEmpty)
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 40, color: AppTheme.textHint),
                        const SizedBox(height: 8),
                        Text('Aucune donnée',
                            style: GoogleFonts.poppins(color: AppTheme.textHint)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: data.fold(0.0, (max, e) {
                        final v = (e['total'] as num).toDouble();
                        return v > max ? v : max;
                      }) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              CurrencyFormatter.format(rod.toY, currency),
                              GoogleFonts.poppins(color: Colors.white, fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < data.length) {
                                return Text(data[idx]['day'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 9,
                                        color: AppTheme.textSecondary));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppTheme.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['total'] as num).toDouble(),
                              color: color,
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: data.fold(0.0, (max, e) {
                                  final v = (e['total'] as num).toDouble();
                                  return v > max ? v : max;
                                }) * 1.2,
                                color: color.withOpacity(0.06),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Category breakdown
              Text('Répartition par catégorie',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              if (txProvider.expenseByCategory.isEmpty && type == 'expense')
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Aucune dépense ce mois-ci',
                        style: GoogleFonts.poppins(color: AppTheme.textHint)),
                  ),
                )
              else
                ...txProvider.expenseByCategory.map((e) {
                  final catColor = Color(int.parse(e['color']));
                  final amount = (e['total'] as num).toDouble();
                  final pct = total > 0 ? amount / total : 0.0;
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
                          width: 10, height: 40,
                          decoration: BoxDecoration(
                            color: catColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['name'] ?? '',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct.toDouble(),
                                  backgroundColor: catColor.withOpacity(0.1),
                                  color: catColor,
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(CurrencyFormatter.format(amount, currency),
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('${(pct * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
