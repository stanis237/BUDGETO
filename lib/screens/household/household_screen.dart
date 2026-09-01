import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/household_service.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final HouseholdService _service = HouseholdService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = true;
  Map<String, dynamic>? _household;

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  Future<void> _loadHousehold() async {
    final h = await _service.getHousehold();
    if (mounted) {
      setState(() {
        _household = h;
        _isLoading = false;
      });
    }
  }

  void _createHousehold() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await _service.createHousehold(name);
    _nameController.clear();
    _loadHousehold();
  }

  void _joinHousehold() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    await _service.joinHousehold(code);
    _codeController.clear();
    _loadHousehold();
  }

  void _leaveHousehold() async {
    setState(() => _isLoading = true);
    await _service.leaveHousehold();
    _loadHousehold();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Foyer Partagé', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _household == null
              ? _buildNoHouseholdView()
              : _buildHouseholdDetailView(),
    );
  }

  Widget _buildNoHouseholdView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.group_add_rounded, size: 80, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            'Partager votre budget',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez un foyer partagé ou rejoignez-en un existant pour synchroniser vos comptes et transactions avec votre famille.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          
          // Create Section
          _buildCard(
            title: 'Créer un foyer',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du foyer (ex: Maison)',
                    hintText: 'Entrez un nom...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createHousehold,
                    child: const Text('Créer'),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Join Section
          _buildCard(
            title: 'Rejoindre un foyer',
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code de foyer (UUID)',
                    hintText: 'Coller le code reçu...',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _joinHousehold,
                    child: const Text('Rejoindre'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdDetailView() {
    final code = _household!['id'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.home_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  _household!['name'],
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text('Foyer actif', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Inviter des membres', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Partagez ce code unique avec les membres de votre famille pour qu\'ils rejoignent votre foyer partagé.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié dans le presse-papiers !')),
                    );
                  },
                )
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _leaveHousehold,
              icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.error),
              label: Text('Quitter le foyer', style: GoogleFonts.poppins(color: AppTheme.error, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
