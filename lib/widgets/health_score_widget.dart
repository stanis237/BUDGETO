import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../services/financial_health_service.dart';

/// Premium animated Financial Health Score Widget for the Stankap dashboard.
class HealthScoreWidget extends StatefulWidget {
  final FinancialHealthResult result;
  final String currency;

  const HealthScoreWidget({
    super.key,
    required this.result,
    required this.currency,
  });

  @override
  State<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends State<HealthScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scoreAnim;
  bool _showInsights = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: widget.result.healthScore / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    switch (widget.result.level) {
      case HealthLevel.excellent: return const Color(0xFF10B981);
      case HealthLevel.good: return const Color(0xFF38BDF8);
      case HealthLevel.warning: return const Color(0xFFF59E0B);
      case HealthLevel.danger: return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainCard(),
        if (_showInsights) ...[
          const SizedBox(height: 12),
          _buildInsightsCard(),
        ],
      ],
    );
  }

  Widget _buildMainCard() {
    return GestureDetector(
      onTap: () => setState(() => _showInsights = !_showInsights),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Santé Financière',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.result.levelLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Animated arc score
                AnimatedBuilder(
                  animation: _scoreAnim,
                  builder: (_, __) => SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _ScoreArcPainter(
                        progress: _scoreAnim.value,
                        color: _scoreColor,
                        score: (widget.result.healthScore * _scoreAnim.value).round(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metricRow(
                        icon: Icons.savings_outlined,
                        label: 'Taux d\'épargne',
                        value: '${(widget.result.savingsRatio * 100).toStringAsFixed(1)}%',
                        color: widget.result.savingsRatio >= 0.1
                            ? AppTheme.income
                            : AppTheme.expense,
                      ),
                      const SizedBox(height: 10),
                      _metricRow(
                        icon: Icons.eco_outlined,
                        label: 'Éco-Score',
                        value: '${widget.result.ecoScore.toStringAsFixed(0)}/100',
                        color: widget.result.ecoScore >= 60
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 10),
                      _velocityRow(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tap indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showInsights
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  _showInsights ? 'Masquer les conseils' : 'Voir les conseils IA',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _velocityRow() {
    final v = widget.result.velocity;
    final vColor = v > 1.2
        ? AppTheme.expense
        : v < 0.8
            ? AppTheme.income
            : AppTheme.warning;
    final vIcon = v > 1.2
        ? Icons.speed_rounded
        : v < 0.8
            ? Icons.check_circle_outline_rounded
            : Icons.trending_flat_rounded;
    final vLabel = v > 1.2 ? 'Trop rapide' : v < 0.8 ? 'Bonne allure' : 'Sur la bonne voie';
    return _metricRow(
      icon: vIcon,
      label: 'Vélocité',
      value: vLabel,
      color: vColor,
    );
  }

  Widget _buildInsightsCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Conseils personnalisés',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.result.insights.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the animated arc score gauge.
class _ScoreArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final int score;

  _ScoreArcPainter({
    required this.progress,
    required this.color,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Progress arc (with gradient effect via stops)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi * 0.75,
        math.pi * 1.5 * progress,
        false,
        progressPaint,
      );
    }

    // Score text in center
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 + 4),
    );

    // "/100" subtext
    final subPainter = TextPainter(
      text: const TextSpan(
        text: '/100',
        style: TextStyle(
          fontSize: 10,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas,
      center + Offset(-subPainter.width / 2, 16),
    );
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.progress != progress || old.color != color;
}
