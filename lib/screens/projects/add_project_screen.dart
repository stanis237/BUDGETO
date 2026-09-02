import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});
  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _selectedIcon = 'rocket_launch';
  String _selectedColor = '0xFF2563EB';
  bool _isLoading = false;

  final _iconOptions = [
    {'name': 'rocket_launch', 'icon': Icons.rocket_launch_rounded, 'label': 'Fusée'},
    {'name': 'home', 'icon': Icons.home_rounded, 'label': 'Maison'},
    {'name': 'school', 'icon': Icons.school_rounded, 'label': 'Études'},
    {'name': 'directions_car', 'icon': Icons.directions_car_rounded, 'label': 'Voiture'},
    {'name': 'flight', 'icon': Icons.flight_rounded, 'label': 'Voyage'},
    {'name': 'business', 'icon': Icons.business_rounded, 'label': 'Business'},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded, 'label': 'Shopping'},
    {'name': 'devices', 'icon': Icons.devices_rounded, 'label': 'Tech'},
    {'name': 'favorite', 'icon': Icons.favorite_rounded, 'label': 'Personnel'},
    {'name': 'savings', 'icon': Icons.savings_rounded, 'label': 'Épargne'},
    {'name': 'build', 'icon': Icons.build_rounded, 'label': 'Travaux'},
    {'name': 'celebration', 'icon': Icons.celebration_rounded, 'label': 'Événement'},
  ];

  final _colorOptions = [
    '0xFF2563EB', // Royal Blue
    '0xFF10B981', // Emerald
    '0xFFEF4444', // Red
    '0xFFF59E0B', // Amber
    '0xFF8B5CF6', // Purple
    '0xFFEC4899', // Pink
    '0xFF0284C7', // Sky Blue
    '0xFF14B8A6', // Teal
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nouveau Projet',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title field
                  _sectionLabel('Titre du projet'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Achat d\'un appartement',
                      prefixIcon: Icon(Icons.edit_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Titre requis' : null,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _sectionLabel('Description (optionnel)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez votre projet...',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Target amount
                  _sectionLabel('Montant cible'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.euro_rounded),
                      suffixText: '€',
                    ),
                    validator: (v) {
                      final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (val == null || val <= 0) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Dates
                  _sectionLabel('Période'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _dateSelector('Début', _startDate, (d) => setState(() => _startDate = d))),
                      const SizedBox(width: 12),
                      Expanded(child: _dateSelector('Fin', _endDate, (d) => setState(() => _endDate = d))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Icon selection
                  _sectionLabel('Icône'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _iconOptions.map((opt) {
                      final isSelected = _selectedIcon == opt['name'];
                      final color = Color(int.parse(_selectedColor));
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = opt['name'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.1) : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : AppTheme.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(opt['icon'] as IconData, color: isSelected ? color : AppTheme.textHint, size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Color selection
                  _sectionLabel('Couleur'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _colorOptions.map((c) {
                      final isSelected = _selectedColor == c;
                      final color = Color(int.parse(c));
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(int.parse(_selectedColor)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Créer le projet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _dateSelector(String label, DateTime? date, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd/MM/yyyy').format(date) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? AppTheme.textPrimary : AppTheme.textHint,
                  fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().currentUser?.id ?? 'guest';
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      await context.read<ProjectProvider>().addProject(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        targetAmount: amount,
        startDate: _startDate,
        endDate: _endDate,
        color: _selectedColor,
        icon: _selectedIcon,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
