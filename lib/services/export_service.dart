import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/financial_health_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ExportService {
  // ─── Stankap Brand Colors (PDF) ──────────────────────────────────────────
  static const _primaryBlue = PdfColor.fromInt(0xFF2563EB);
  static const _darkBlue = PdfColor.fromInt(0xFF1D4ED8);
  static const _lightBlue = PdfColor.fromInt(0xFFEFF6FF);
  static const _incomeGreen = PdfColor.fromInt(0xFF10B981);
  static const _expenseRed = PdfColor.fromInt(0xFFEF4444);
  static const _textDark = PdfColor.fromInt(0xFF0F172A);
  static const _textMuted = PdfColor.fromInt(0xFF64748B);
  static const _divider = PdfColor.fromInt(0xFFE2E8F0);
  static const _white = PdfColors.white;
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC);
  static const _warningOrange = PdfColor.fromInt(0xFFF59E0B);
  static const _ecoGreen = PdfColor.fromInt(0xFF059669);

  // ─── CSV Export ──────────────────────────────────────────────────────────

  Future<String> exportToCsv(List<TransactionModel> transactions) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    List<List<dynamic>> rows = [
      ['Date', 'Type', 'Catégorie', 'Description', 'Montant'],
    ];
    for (var tx in transactions) {
      rows.add([
        dateFormat.format(tx.date),
        tx.type == 'income' ? 'Revenu' : 'Dépense',
        tx.categoryName ?? 'Autre',
        tx.description ?? '',
        tx.amount,
      ]);
    }
    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/stankap_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);
    return file.path;
  }

  // ─── PDF Premium Export ───────────────────────────────────────────────────

  Future<void> exportToPdf(
    List<TransactionModel> transactions, {
    List<BudgetModel> budgets = const [],
    String userName = 'Utilisateur',
    String currency = 'EUR',
    DateTime? month,
  }) async {
    final now = month ?? DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: _currencySymbol(currency),
      decimalDigits: 2,
    );

    // Compute financial health
    final healthService = FinancialHealthService();
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    final incomes = transactions.where((t) => t.type == 'income').toList();
    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalIncome = incomes.fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    final health = healthService.compute(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: transactions,
      budgets: budgets,
      month: now,
    );

    // Category breakdown
    final Map<String, _CategoryStat> catStats = {};
    for (final t in expenses) {
      final key = t.categoryId;
      catStats.putIfAbsent(
        key,
        () => _CategoryStat(
          name: t.categoryName ?? 'Autre',
          color: t.categoryColor,
        ),
      );
      catStats[key]!.amount += t.amount;
      catStats[key]!.count++;
    }
    final sortedCats = catStats.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Weekly breakdown
    final Map<int, double> weekExpense = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final Map<int, double> weekIncome = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final t in transactions) {
      final week = ((t.date.day - 1) ~/ 7) + 1;
      if (t.type == 'expense') weekExpense[week] = (weekExpense[week] ?? 0) + t.amount;
      if (t.type == 'income') weekIncome[week] = (weekIncome[week] ?? 0) + t.amount;
    }

    // Build PDF
    final pdf = pw.Document(
      title: 'Rapport Stankap - $monthLabel',
      author: 'Stankap',
      creator: 'Stankap App',
    );

    // ── Page 1: Cover ─────────────────────────────────────────────────────
    pdf.addPage(_buildCoverPage(
      userName: userName,
      monthLabel: monthLabel,
      health: health,
      numFormat: numFormat,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
    ));

    // ── Page 2: Executive Summary + Weekly Chart ──────────────────────────
    pdf.addPage(_buildSummaryPage(
      monthLabel: monthLabel,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      numFormat: numFormat,
      weekExpense: weekExpense,
      weekIncome: weekIncome,
      transactions: transactions,
      health: health,
    ));

    // ── Page 3: Category Breakdown ────────────────────────────────────────
    if (sortedCats.isNotEmpty) {
      pdf.addPage(_buildCategoryPage(
        monthLabel: monthLabel,
        categories: sortedCats,
        totalExpense: totalExpense,
        budgets: budgets,
        numFormat: numFormat,
      ));
    }

    // ── Page 4: Transactions Table ────────────────────────────────────────
    if (transactions.isNotEmpty) {
      pdf.addPage(_buildTransactionsPage(
        monthLabel: monthLabel,
        transactions: transactions,
        dateFormat: dateFormat,
        numFormat: numFormat,
      ));
    }

    // ── Page 5: Insights & Recommendations ───────────────────────────────
    pdf.addPage(_buildInsightsPage(
      monthLabel: monthLabel,
      health: health,
      numFormat: numFormat,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    ));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Stankap_$monthLabel',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  pw.Page _buildCoverPage({
    required String userName,
    required String monthLabel,
    required FinancialHealthResult health,
    required NumberFormat numFormat,
    required double totalIncome,
    required double totalExpense,
    required double balance,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        children: [
          // Header gradient band
          pw.Container(
            width: double.infinity,
            height: 280,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_darkBlue, _primaryBlue],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            padding: const pw.EdgeInsets.all(36),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 48,
                      height: 48,
                      decoration: pw.BoxDecoration(
                        color: _white.withOpacity(0.2),
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Center(
                        child: pw.Text('S',
                            style: pw.TextStyle(
                              color: _white,
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                            )),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text('Stankap',
                        style: pw.TextStyle(
                          color: _white,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ],
                ),
                pw.Spacer(),
                pw.Text('Rapport Financier',
                    style: pw.TextStyle(
                        color: _white.withOpacity(0.8), fontSize: 14)),
                pw.Text(monthLabel.toUpperCase(),
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 8),
                pw.Text('Préparé pour $userName',
                    style: pw.TextStyle(
                        color: _white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 32),

          // Score badge
          _buildScoreBadge(health),
          pw.SizedBox(height: 32),

          // KPI row
          pw.Row(
            children: [
              _kpiCard('Revenus', numFormat.format(totalIncome), _incomeGreen),
              pw.SizedBox(width: 12),
              _kpiCard('Dépenses', numFormat.format(totalExpense), _expenseRed),
              pw.SizedBox(width: 12),
              _kpiCard(
                'Balance',
                numFormat.format(balance),
                balance >= 0 ? _incomeGreen : _expenseRed,
              ),
            ],
          ),
          pw.Spacer(),

          // Footer
          pw.Divider(color: _divider, thickness: 0.5),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(color: _textMuted, fontSize: 9),
              ),
              pw.Text('stankap.app',
                  style: pw.TextStyle(
                    color: _primaryBlue,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  pw.Page _buildSummaryPage({
    required String monthLabel,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required NumberFormat numFormat,
    required Map<int, double> weekExpense,
    required Map<int, double> weekIncome,
    required List<TransactionModel> transactions,
    required FinancialHealthResult health,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('Résumé Exécutif', monthLabel),
          pw.SizedBox(height: 24),

          // Summary stats
          pw.Row(
            children: [
              _summaryStatCard('Total Revenus', numFormat.format(totalIncome),
                  _incomeGreen, '+'),
              pw.SizedBox(width: 12),
              _summaryStatCard('Total Dépenses', numFormat.format(totalExpense),
                  _expenseRed, '-'),
              pw.SizedBox(width: 12),
              _summaryStatCard(
                  'Solde Net',
                  numFormat.format(balance),
                  balance >= 0 ? _incomeGreen : _expenseRed,
                  balance >= 0 ? '+' : ''),
            ],
          ),
          pw.SizedBox(height: 28),

          // Weekly bar chart
          pw.Text('Évolution hebdomadaire',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark)),
          pw.SizedBox(height: 12),
          _buildWeeklyChart(weekExpense, weekIncome, numFormat),
          pw.SizedBox(height: 28),

          // Metrics grid
          pw.Text('Indicateurs Clés',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark)),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _metricTile(
                'Nb. Transactions',
                '${transactions.length}',
                icon: '📊',
              ),
              pw.SizedBox(width: 8),
              _metricTile(
                'Taux d\'épargne',
                '${(health.savingsRatio * 100).toStringAsFixed(1)}%',
                icon: '💰',
              ),
              pw.SizedBox(width: 8),
              _metricTile(
                'Éco-Score',
                '${health.ecoScore.toStringAsFixed(0)}/100',
                icon: '🌱',
              ),
              pw.SizedBox(width: 8),
              _metricTile(
                'Score Santé',
                '${health.healthScore.toStringAsFixed(0)}/100',
                icon: '❤️',
              ),
            ],
          ),
          pw.Spacer(),
          _pageFooter(2),
        ],
      ),
    );
  }

  pw.Page _buildCategoryPage({
    required String monthLabel,
    required List<_CategoryStat> categories,
    required double totalExpense,
    required List<BudgetModel> budgets,
    required NumberFormat numFormat,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('Détail par Catégorie', monthLabel),
          pw.SizedBox(height: 20),

          // Category table
          pw.TableHelper.fromTextArray(
            headers: ['Catégorie', 'Montant', '% Total', 'Transactions', 'Budget'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _white,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: _primaryBlue),
            cellHeight: 32,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            cellStyle: pw.TextStyle(fontSize: 10, color: _textDark),
            oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
            data: categories.asMap().entries.map((entry) {
              final cat = entry.value;
              final pct = totalExpense > 0 ? (cat.amount / totalExpense * 100) : 0;
              // Find matching budget
              final budget = budgets.where((b) =>
                  b.categoryName?.toLowerCase() == cat.name.toLowerCase()).firstOrNull;
              final budgetStr = budget != null
                  ? (budget.percentage >= 1.0
                      ? '⚠️ Dépassé'
                      : '${(budget.percentage * 100).toStringAsFixed(0)}%')
                  : '—';

              return [
                cat.name,
                numFormat.format(cat.amount),
                '${pct.toStringAsFixed(1)}%',
                '${cat.count}',
                budgetStr,
              ];
            }).toList(),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
            ),
          ),

          pw.SizedBox(height: 28),

          // Mini horizontal bars
          pw.Text('Proportion des dépenses',
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark)),
          pw.SizedBox(height: 12),
          ...categories.take(6).map((cat) {
            final pct = totalExpense > 0 ? cat.amount / totalExpense : 0.0;
            return _buildCategoryBar(cat.name, pct, numFormat.format(cat.amount));
          }),

          pw.Spacer(),
          _pageFooter(3),
        ],
      ),
    );
  }

  pw.Page _buildTransactionsPage({
    required String monthLabel,
    required List<TransactionModel> transactions,
    required DateFormat dateFormat,
    required NumberFormat numFormat,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (ctx) => _pageHeader('Détail des Transactions', monthLabel),
      footer: (ctx) => _pageFooter(4),
      build: (ctx) => [
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Type', 'Catégorie', 'Description', 'Montant'],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: _white,
            fontSize: 9,
          ),
          headerDecoration: const pw.BoxDecoration(color: _primaryBlue),
          cellHeight: 28,
          cellAlignments: {
            0: pw.Alignment.center,
            1: pw.Alignment.center,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerRight,
          },
          cellStyle: pw.TextStyle(fontSize: 9, color: _textDark),
          oddRowDecoration: const pw.BoxDecoration(color: _bgLight),
          data: transactions.map((tx) {
            final isIncome = tx.type == 'income';
            return [
              dateFormat.format(tx.date),
              isIncome ? '▲ Revenu' : '▼ Dépense',
              tx.categoryName ?? 'Autre',
              tx.description ?? '—',
              '${isIncome ? '+' : '-'}${numFormat.format(tx.amount)}',
            ];
          }).toList(),
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
          ),
        ),
      ],
    );
  }

  pw.Page _buildInsightsPage({
    required String monthLabel,
    required FinancialHealthResult health,
    required NumberFormat numFormat,
    required double totalIncome,
    required double totalExpense,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader('Conseils & Perspectives', monthLabel),
          pw.SizedBox(height: 24),

          // Health score summary
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [_darkBlue, _primaryBlue],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Score de Santé Financière',
                        style: pw.TextStyle(
                            color: _white.withOpacity(0.8), fontSize: 11)),
                    pw.Text('${health.healthScore.toStringAsFixed(0)} / 100',
                        style: pw.TextStyle(
                          color: _white,
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.SizedBox(height: 4),
                    pw.Text(_healthLevelText(health.level),
                        style: pw.TextStyle(
                            color: _white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Éco-Score',
                        style: pw.TextStyle(
                            color: _white.withOpacity(0.8), fontSize: 10)),
                    pw.Text('${health.ecoScore.toStringAsFixed(0)}/100',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Épargne',
                        style: pw.TextStyle(
                            color: _white.withOpacity(0.8), fontSize: 10)),
                    pw.Text(
                        '${(health.savingsRatio * 100).toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                            color: _white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text('Recommandations Personnalisées',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark)),
          pw.SizedBox(height: 12),

          // Insights as cards
          ...health.insights.asMap().entries.map((e) {
            return pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: e.key.isEven ? _lightBlue : _bgLight,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: _divider, width: 0.5),
              ),
              child: pw.Text(
                e.value,
                style: pw.TextStyle(fontSize: 11, color: _textDark, lineSpacing: 3),
              ),
            );
          }),

          pw.Spacer(),

          // Closing note
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _ecoGreen.withOpacity(0.06),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: _ecoGreen.withOpacity(0.3), width: 0.5),
            ),
            child: pw.Text(
              '🌿 Ce rapport a été généré automatiquement par Stankap. '
              'Continuez à suivre vos finances pour améliorer votre score et atteindre vos objectifs.',
              style: pw.TextStyle(
                  fontSize: 10, color: _textMuted, lineSpacing: 3),
            ),
          ),

          pw.SizedBox(height: 12),
          _pageFooter(5),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REUSABLE PDF COMPONENTS
  // ─────────────────────────────────────────────────────────────────────────

  pw.Widget _pageHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _primaryBlue,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('Stankap',
                  style: pw.TextStyle(
                      color: _white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(width: 10),
            pw.Text(title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                )),
            pw.Spacer(),
            pw.Text(subtitle,
                style: pw.TextStyle(fontSize: 10, color: _textMuted)),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _divider, thickness: 1),
      ],
    );
  }

  pw.Widget _pageFooter(int pageNum) {
    return pw.Column(
      children: [
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Stankap — Rapport Confidentiel',
                style: pw.TextStyle(fontSize: 8, color: _textMuted)),
            pw.Text('Page $pageNum',
                style: pw.TextStyle(fontSize: 8, color: _textMuted)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildScoreBadge(FinancialHealthResult health) {
    final color = _healthLevelColor(health.level);
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: pw.BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: pw.BorderRadius.circular(16),
          border: pw.Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Column(
              children: [
                pw.Text('${health.healthScore.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    )),
                pw.Text('/100',
                    style: pw.TextStyle(fontSize: 12, color: _textMuted)),
              ],
            ),
            pw.SizedBox(width: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Score de Santé',
                    style: pw.TextStyle(fontSize: 11, color: _textMuted)),
                pw.Text('Financière',
                    style: pw.TextStyle(fontSize: 11, color: _textMuted)),
                pw.SizedBox(height: 4),
                pw.Text(_healthLevelText(health.level),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _kpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 10, color: _textMuted)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  pw.Widget _summaryStatCard(
      String label, String value, PdfColor color, String prefix) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _white,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: _divider, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9, color: _textMuted)),
            pw.SizedBox(height: 6),
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildWeeklyChart(
    Map<int, double> weekExpense,
    Map<int, double> weekIncome,
    NumberFormat numFormat,
  ) {
    final maxVal = [
      ...weekExpense.values,
      ...weekIncome.values,
    ].fold(0.0, math.max);
    const chartH = 80.0;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _divider, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final w = i + 1;
              final exp = weekExpense[w] ?? 0;
              final inc = weekIncome[w] ?? 0;
              final expH = maxVal > 0 ? (exp / maxVal * chartH) : 0.0;
              final incH = maxVal > 0 ? (inc / maxVal * chartH) : 0.0;
              return pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 12,
                          height: incH.clamp(2.0, chartH),
                          color: _incomeGreen.withOpacity(0.8),
                        ),
                        pw.SizedBox(width: 2),
                        pw.Container(
                          width: 12,
                          height: expH.clamp(2.0, chartH),
                          color: _expenseRed.withOpacity(0.8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('S$w',
                        style: pw.TextStyle(fontSize: 8, color: _textMuted)),
                  ],
                ),
              );
            }),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Container(width: 10, height: 10, color: _incomeGreen.withOpacity(0.8)),
              pw.SizedBox(width: 4),
              pw.Text('Revenus', style: pw.TextStyle(fontSize: 8, color: _textMuted)),
              pw.SizedBox(width: 16),
              pw.Container(width: 10, height: 10, color: _expenseRed.withOpacity(0.8)),
              pw.SizedBox(width: 4),
              pw.Text('Dépenses', style: pw.TextStyle(fontSize: 8, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryBar(String name, double pct, String amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(name,
                  style: pw.TextStyle(fontSize: 10, color: _textDark)),
              pw.Text('${(pct * 100).toStringAsFixed(1)}% — $amount',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: _textMuted,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Stack(children: [
            pw.Container(
              width: double.infinity,
              height: 6,
              decoration: pw.BoxDecoration(
                color: _divider,
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: pw.Container(
                height: 6,
                decoration: pw.BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  pw.Widget _metricTile(String label, String value, {String icon = '📈'}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _lightBlue,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _primaryBlue.withOpacity(0.2), width: 0.5),
        ),
        child: pw.Column(
          children: [
            pw.Text(icon, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryBlue)),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: _textMuted),
                textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }

  PdfColor _healthLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent: return _incomeGreen;
      case HealthLevel.good: return _primaryBlue;
      case HealthLevel.warning: return _warningOrange;
      case HealthLevel.danger: return _expenseRed;
    }
  }

  String _healthLevelText(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent: return 'Excellent 🏆';
      case HealthLevel.good: return 'Bon 👍';
      case HealthLevel.warning: return 'Attention ⚠️';
      case HealthLevel.danger: return 'Danger 🔴';
    }
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'XAF': return 'FCFA';
      case 'XOF': return 'FCFA';
      case 'MAD': return 'MAD';
      default: return code;
    }
  }
}

class _CategoryStat {
  final String name;
  final String? color;
  double amount = 0;
  int count = 0;

  _CategoryStat({required this.name, this.color});
}
