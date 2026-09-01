import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/gamification_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _challenges = [];
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final challenges = await GamificationService().getChallenges();
    
    int points = 0;
    for (var c in challenges) {
      if (c['is_completed'] == true) {
        points += (c['points'] as num).toInt();
      }
    }

    if (mounted) {
      setState(() {
        _challenges = challenges;
        _totalPoints = points;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Réussites', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primary,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildScoreHeader(),
                const SizedBox(height: 32),
                Text('Défis & Badges', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                ..._challenges.map((c) => _buildChallengeCard(c)),
              ],
            ),
          ),
    );
  }

  Widget _buildScoreHeader() {
    int level = (_totalPoints / 50).floor() + 1;
    double progress = (_totalPoints % 50) / 50.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7043).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Niveau $level',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            '$_totalPoints Points d\'économie',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${50 - (_totalPoints % 50)} points restants avant le niveau ${level + 1}',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    bool isCompleted = challenge['is_completed'] == true;
    Color iconColor = Color(int.parse(challenge['color'].toString().replaceAll('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.surface : AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? AppTheme.success.withOpacity(0.5) : AppTheme.divider,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: isCompleted ? AppTheme.cardShadow : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCompleted ? iconColor.withOpacity(0.15) : AppTheme.divider,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(challenge['icon']),
              color: isCompleted ? iconColor : AppTheme.textHint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  challenge['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '+${challenge['points']}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isCompleted ? AppTheme.success : AppTheme.textHint,
                ),
              ),
              Text('pts', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textHint)),
            ],
          )
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    switch(name) {
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'weekend': return Icons.weekend_rounded;
      case 'visibility': return Icons.visibility_rounded;
      default: return Icons.stars_rounded;
    }
  }
}
