import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../onboarding/welcome_screen.dart';
import '../transactions/recurring_transactions_screen.dart';
import '../planning/monthly_plan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final currency = auth.currency;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'B',
                      style: GoogleFonts.poppins(
                          fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Invité',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        if (user?.email.isNotEmpty == true)
                          Text(user!.email,
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${CurrencyFormatter.symbol(currency)} $currency',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editName(context, auth),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings section
            _sectionTitle('Paramètres'),
            const SizedBox(height: 12),
            _buildCard([
              _settingsItem(
                icon: Icons.currency_exchange_rounded,
                color: AppTheme.primary,
                label: 'Devise',
                subtitle: '${CurrencyFormatter.symbol(currency)} $currency',
                onTap: () => _showCurrencyPicker(context, auth),
              ),
              const Divider(height: 1, indent: 56),
              _settingsItem(
                icon: Icons.autorenew_rounded,
                color: const Color(0xFFF57C00),
                label: 'Abonnements & Récurrents',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringTransactionsScreen())),
              ),
              const Divider(height: 1, indent: 56),
              _settingsItem(
                icon: Icons.track_changes_rounded,
                color: const Color(0xFF8E24AA),
                label: 'Planification Mensuelle',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyPlanScreen())),
              ),
            ]),
            const SizedBox(height: 16),

            // Account section
            _sectionTitle('Compte'),
            const SizedBox(height: 12),
            _buildCard([
              if (user?.id != 'guest') ...[
                _settingsItem(
                  icon: Icons.group_rounded,
                  color: const Color(0xFF667EEA),
                  label: 'Changer de compte',
                  onTap: () => _showUserSwitcher(context, auth),
                ),
                const Divider(height: 1, indent: 56),
              ],
              _settingsItem(
                icon: Icons.info_outline_rounded,
                color: const Color(0xFF45B7D1),
                label: 'À propos',
                onTap: () => _showAbout(context),
              ),
              const Divider(height: 1, indent: 56),
              _settingsItem(
                icon: Icons.logout_rounded,
                color: AppTheme.error,
                label: 'Déconnexion',
                labelColor: AppTheme.error,
                onTap: () => _logout(context, auth),
              ),
            ]),

            const SizedBox(height: 24),
            Center(
              child: Text('Budgeto v1.0.0',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textHint)),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary));

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Column(children: children),
  );

  Widget _settingsItem({
    required IconData icon,
    required Color color,
    required String label,
    String? subtitle,
    Color? labelColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: labelColor ?? AppTheme.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController(text: auth.currentUser?.name ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifier le nom',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                auth.updateName(ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text('Enregistrer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
            Text('Choisir la devise',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...CurrencyFormatter.availableCurrencies.map((c) {
              final isSelected = auth.currency == c['code'];
              return InkWell(
                onTap: () {
                  auth.updateCurrency(c['code']!);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.08)
                        : AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']!,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            Text('${c['symbol']} (${c['code']})',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primary, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showUserSwitcher(BuildContext context, AuthProvider auth) async {
    final users = await auth.getAllUsers();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
            Text('Changer de compte',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...users.map((u) {
              final isCurrent = auth.currentUser?.id == u.id;
              return InkWell(
                onTap: () {
                  if (!isCurrent) {
                    auth.switchUser(u);
                    // reload data
                    context.read<TransactionProvider>().loadAll(u.id);
                    context.read<BudgetProvider>().loadBudgets(u.id);
                    context.read<GoalProvider>().loadGoals(u.id);
                    Navigator.pop(context);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(u.name[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                                color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            Text(u.email,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primary, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Budgeto',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white, size: 30),
      ),
      children: [
        Text('Application de gestion de budget personnelle.',
            style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }

  void _logout(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déconnexion', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Déconnexion', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await auth.logout();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
    }
  }
}
