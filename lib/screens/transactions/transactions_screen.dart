import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filtered = [];
  bool _isSearching = false;
  String _filterType = 'all'; // all, income, expense

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text;
    if (q.isEmpty) {
      setState(() => _filtered = _applyFilter(_allTransactions));
    } else {
      final results = _allTransactions.where((t) {
        return (t.description?.toLowerCase().contains(q.toLowerCase()) ?? false) ||
            (t.categoryName?.toLowerCase().contains(q.toLowerCase()) ?? false);
      }).toList();
      setState(() => _filtered = _applyFilter(results));
    }
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> list) {
    if (_filterType == 'all') return list;
    return list.where((t) => t.type == _filterType).toList();
  }

  void _setFilter(String type) {
    setState(() {
      _filterType = type;
      _filtered = _applyFilter(_allTransactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final currency = auth.currency;
    final transactions = txProvider.transactions;

    if (transactions != _allTransactions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _allTransactions = transactions;
          _filtered = _applyFilter(transactions);
        });
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Transactions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _filtered = _applyFilter(_allTransactions);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher une transaction...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

          // Month selector + filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Row(
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
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filterChip('all', 'Tous'),
                    const SizedBox(width: 8),
                    _filterChip('income', 'Revenus'),
                    const SizedBox(width: 8),
                    _filterChip('expense', 'Dépenses'),
                  ],
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _buildItem(_filtered[i], currency, auth),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String type, String label) {
    final isActive = _filterType == type;
    Color chipColor;
    switch (type) {
      case 'income': chipColor = AppTheme.income; break;
      case 'expense': chipColor = AppTheme.expense; break;
      default: chipColor = AppTheme.primary;
    }
    return GestureDetector(
      onTap: () => _setFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? chipColor : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildItem(TransactionModel t, String currency, AuthProvider auth) {
    final isIncome = t.type == 'income';
    final color = isIncome ? AppTheme.income : AppTheme.expense;
    final catColor = t.categoryColor != null
        ? Color(int.parse(t.categoryColor!))
        : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: Key(t.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Supprimer ?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Text('Cette transaction sera supprimée définitivement.',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false),
                          child: Text('Annuler', style: GoogleFonts.poppins())),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        child: Text('Supprimer', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!context.mounted) return;
                  await context.read<TransactionProvider>()
                      .deleteTransaction(t.id, auth.currentUser?.id ?? 'guest');
                }
              },
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Suppr.',
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
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
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (t.description != null && t.description!.isNotEmpty)
                      Text(t.description!,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    Text(DateFormatter.format(t.date),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount, currency)}',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14, color: color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isIncome ? 'Revenu' : 'Dépense',
                        style: GoogleFonts.poppins(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textHint),
        const SizedBox(height: 16),
        Text('Aucune transaction', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Ajoutez votre première transaction',
            style: GoogleFonts.poppins(color: AppTheme.textHint, fontSize: 13)),
      ],
    ),
  );

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
