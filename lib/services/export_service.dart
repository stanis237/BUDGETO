import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';

class ExportService {
  static const _textDark = PdfColor.fromInt(0xFF1E293B);
  static const _textMuted = PdfColor.fromInt(0xFF64748B);
  static const _primaryBlue = PdfColor.fromInt(0xFF2563EB);
  static const _incomeGreen = PdfColor.fromInt(0xFF166534);
  static const _expenseRed = PdfColor.fromInt(0xFF991B1B);
  static const _divider = PdfColor.fromInt(0xFFE2E8F0);
  static const _bgZebra = PdfColor.fromInt(0xFFF8FAFC);

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

  // ─── Lisible & Épuré PDF Export ─────────────────────────────────────────

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

    final sortedTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalIncome = sortedTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = sortedTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    final pdf = pw.Document(
      title: 'Relevé Stankap - $monthLabel',
      author: 'Stankap',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Column(
          crosspw: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'STANKAP',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
                pw.Text(
                  'RELEVÉ DE TRANSACTIONS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Titulaire : $userName',
                    style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
                pw.Text('Période : $monthLabel',
                    style: const pw.TextStyle(fontSize: 10, color: _textMuted)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _primaryBlue, thickness: 1.5),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: _textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} sur ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _textMuted),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // ── Synthèse des Montants (Tableau simple) ──────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: _divider, width: 0.8),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _bgZebra),
                children: [
                  _headerCell('Total Revenus', pw.Alignment.center),
                  _headerCell('Total Dépenses', pw.Alignment.center),
                  _headerCell('Solde Net', pw.Alignment.center),
                ],
              ),
              pw.TableRow(
                children: [
                  _valueCell(numFormat.format(totalIncome), _incomeGreen),
                  _valueCell(numFormat.format(totalExpense), _expenseRed),
                  _valueCell(
                    numFormat.format(balance),
                    balance >= 0 ? _incomeGreen : _expenseRed,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Tableau des Transactions ────────────────────────────────────
          pw.Text(
            'Détail des opérations (${sortedTransactions.length})',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textDark,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Type', 'Catégorie', 'Description', 'Montant'],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: _primaryBlue),
            cellHeight: 24,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 9, color: _textDark),
            oddRowDecoration: const pw.BoxDecoration(color: _bgZebra),
            data: sortedTransactions.map((tx) {
              final isIncome = tx.type == 'income';
              return [
                dateFormat.format(tx.date),
                isIncome ? 'Revenu' : 'Dépense',
                tx.categoryName ?? 'Autre',
                tx.description ?? '—',
                '${isIncome ? '+' : '-'}${numFormat.format(tx.amount)}',
              ];
            }).toList(),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
              bottom: pw.BorderSide(color: _divider, width: 1),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relevé_Stankap_$monthLabel',
    );
  }

  static pw.Widget _headerCell(String label, pw.Alignment align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _textMuted,
          ),
        ),
      ),
    );
  }

  static pw.Widget _valueCell(String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  static String _currencySymbol(String currency) {
    switch (currency) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'XAF':
      case 'XOF': return 'FCFA';
      default: return currency;
    }
  }
}
