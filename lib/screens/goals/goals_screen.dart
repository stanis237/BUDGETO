import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../models/goal.dart';

// Built-in goal images mapped to keys
const Map<String, String> goalImages = {
  'travel': '✈️',
  'car': '🚗',
  'house': '🏠',
  'emergency': '🛡️',
  'education': '🎓',
  'wedding': '💍',
  'business': '💼',
  'tech': '💻',
  'health': '🏥',
  'vacation': '🏖️',
  'savings': '💰',
  'other': '🎯',
};

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final auth = context.watch<AuthProvider>();
    final currency = auth.currency;
    final userId = auth.currentUser?.id ?? 'guest';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Objectifs', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
            onPressed: () => _showAddGoalDialog(context, userId, currency),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => goalProvider.loadGoals(userId),
        child: goalProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : goalProvider.goals.isEmpty
                ? _buildEmpty(context, userId, currency)
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Summary header
                            _buildSummary(goalProvider, currency),
                            const SizedBox(height: 24),
                            Text('Mes objectifs',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            ...goalProvider.goals.map((g) =>
                                _buildGoalCard(context, g, currency, userId)),
                            const SizedBox(height: 80),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummary(GoalProvider provider, String currency) {
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
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              '${provider.goals.length}',
              'Objectifs',
              Icons.flag_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _statItem(
              '${provider.completed}',
              'Complétés',
              Icons.check_circle_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _statItem(
              CurrencyFormatter.format(provider.totalSaved, currency),
              'Épargné',
              Icons.savings_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) => Column(
    children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          overflow: TextOverflow.ellipsis),
      Text(label,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10)),
    ],
  );

  Widget _buildGoalCard(
      BuildContext context, GoalModel g, String currency, String userId) {
    final emoji = goalImages[g.imageKey ?? 'other'] ?? '🎯';
    final isCompleted = g.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji background
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [AppTheme.primary.withOpacity(0.8), AppTheme.primary]
                    : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 48)),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success, size: 14),
                          const SizedBox(width: 4),
                          Text('Complété',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: AppTheme.success,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 12, left: 12,
                  child: Row(
                    children: [
                      if (g.deadline != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(DateFormatter.format(g.deadline!),
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(g.title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'contribute') _showContribute(context, g, currency, userId);
                        if (v == 'delete') context.read<GoalProvider>().deleteGoal(g.id, userId);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'contribute',
                            child: Text('Ajouter épargne', style: GoogleFonts.poppins(fontSize: 13))),
                        PopupMenuItem(value: 'delete',
                            child: Text('Supprimer',
                                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.error))),
                      ],
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Épargné',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text(CurrencyFormatter.format(g.currentAmount, currency),
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                      ],
                    ),
                    CircularPercentIndicator(
                      radius: 32,
                      lineWidth: 6,
                      percent: g.percentage,
                      center: Text('${(g.percentage * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700)),
                      progressColor: isCompleted ? AppTheme.success : AppTheme.primary,
                      backgroundColor: AppTheme.divider,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Objectif',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        Text(CurrencyFormatter.format(g.targetAmount, currency),
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: g.percentage,
                  backgroundColor: AppTheme.divider,
                  color: isCompleted ? AppTheme.success : AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Il reste ${CurrencyFormatter.format(g.remaining, currency)} à épargner',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String userId, String currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Aucun objectif',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Définissez vos objectifs financiers\net suivez votre progression',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddGoalDialog(context, userId, currency),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer un objectif'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContribute(
      BuildContext context, GoalModel g, String currency, String userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ajouter une épargne',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Montant (${CurrencyFormatter.symbol(currency)})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) {
                context.read<GoalProvider>().addContribution(g.id, v, userId);
                Navigator.pop(context);
              }
            },
            child: Text('Ajouter', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, String userId, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(userId: userId, currency: currency),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final String userId;
  final String currency;
  const _AddGoalSheet({required this.userId, required this.currency});
  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  String _selectedImageKey = 'savings';
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nouvel objectif',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Image picker
            Text('Icône', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: goalImages.entries.map((e) {
                final isSelected = _selectedImageKey == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageKey = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 2),
                    ),
                    child: Center(
                      child: Text(e.value, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _label('Titre de l\'objectif'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Voyage à Bali'),
            ),
            const SizedBox(height: 16),

            _label('Montant cible (${CurrencyFormatter.symbol(widget.currency)})'),
            const SizedBox(height: 8),
            TextField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '5 000'),
            ),
            const SizedBox(height: 16),

            _label('Épargne actuelle (${CurrencyFormatter.symbol(widget.currency)})'),
            const SizedBox(height: 8),
            TextField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0'),
            ),
            const SizedBox(height: 16),

            _label('Date limite (optionnel)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primary),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEF0F5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _deadline != null
                          ? DateFormatter.format(_deadline!)
                          : 'Sélectionner une date',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _deadline != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint),
                    ),
                    if (_deadline != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppTheme.textHint, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
                  final current = double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
                  if (title.isNotEmpty && target != null && target > 0) {
                    context.read<GoalProvider>().addGoal(
                      userId: widget.userId,
                      title: title,
                      targetAmount: target,
                      currentAmount: current,
                      deadline: _deadline,
                      imageKey: _selectedImageKey,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Créer l\'objectif',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
}
