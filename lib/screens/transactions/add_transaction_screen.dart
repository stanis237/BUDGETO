import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_transaction_provider.dart';
import '../../models/category.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'expense';
  String _period = 'none';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<TransactionProvider>().getCategoriesByType(_type);
    if (mounted) {
      setState(() {
        _categories = cats;
        _categoriesLoading = false;
      });
    }
  }

  Future<void> _changeType(String type) async {
    setState(() { _type = type; _selectedCategoryId = null; _categoriesLoading = true; });
    final cats = await context.read<TransactionProvider>().getCategoriesByType(type);
    if (mounted) setState(() { _categories = cats; _categoriesLoading = false; });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez sélectionner une catégorie',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest';
    await context.read<TransactionProvider>().addTransaction(
      userId: userId,
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
      type: _type,
      categoryId: _selectedCategoryId!,
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      date: _selectedDate,
    );

    if (_period != 'none') {
      await context.read<RecurringTransactionProvider>().addRecurringTransaction(
        userId: userId,
        amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        type: _type,
        categoryId: _selectedCategoryId!,
        description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
        period: _period,
        startDate: _selectedDate,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction ajoutée avec succès', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.read<AuthProvider>().currency;
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text('Ajouter une transaction',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, mediaQuery.viewInsets.bottom + 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _typeBtn('expense', 'Dépense', Icons.arrow_upward_rounded),
                          _typeBtn('income', 'Revenu', Icons.arrow_downward_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    _label('Montant (${CurrencyFormatter.symbol(currency)})'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0,00',
                        prefixText: '${CurrencyFormatter.symbol(currency)} ',
                        prefixStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Montant requis';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Montant invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Categories
                    _label('Catégorie'),
                    const SizedBox(height: 10),
                    if (_categoriesLoading)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategoryId = cat.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.colorValue.withOpacity(0.15)
                                    : AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? cat.colorValue : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.iconData, color: cat.colorValue, size: 18),
                                  const SizedBox(width: 6),
                                  Text(cat.name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? cat.colorValue
                                              : AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // Description
                    _label('Description (optionnel)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Courses au supermarché',
                        prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date
                    _label('Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEF0F5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: GoogleFonts.poppins(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Récurrence
                    _label('Récurrence'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEF0F5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _period,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                          style: GoogleFonts.poppins(fontSize: 15, color: AppTheme.textPrimary),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _period = newValue);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'none', child: Text('Jamais')),
                            DropdownMenuItem(value: 'daily', child: Text('Tous les jours')),
                            DropdownMenuItem(value: 'weekly', child: Text('Toutes les semaines')),
                            DropdownMenuItem(value: 'monthly', child: Text('Tous les mois')),
                            DropdownMenuItem(value: 'yearly', child: Text('Tous les ans')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == 'expense'
                              ? AppTheme.expense
                              : AppTheme.income,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Enregistrer',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String type, String label, IconData icon) {
    final isActive = _type == type;
    final color = type == 'expense' ? AppTheme.expense : AppTheme.income;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? Colors.white : AppTheme.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}
