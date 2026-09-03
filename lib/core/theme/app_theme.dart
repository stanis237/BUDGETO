import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stankap Premium Colors (Blue & White Fintech Style)
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFF60A5FA); // Ice/Soft Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Navy Accent
  static const Color secondary = Color(0xFF38BDF8); // Sky Blue Accent
  static const Color accent = Color(0xFF10B981); // Emerald Green
  
  static const Color income = Color(0xFF10B981); // Vibrant Emerald Green
  static const Color expense = Color(0xFFEF4444); // Coral Red

  // Crisp Light Background & Surface (Blue & White Theme)
  static const Color background = Color(0xFFF8FAFC); // Ultra-clean Light Background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color cardBg = Color(0xFFFFFFFF);
  
  static const Color textPrimary = Color(0xFF0F172A); // High contrast dark slate
  static const Color textSecondary = Color(0xFF64748B); // Muted slate text
  static const Color textHint = Color(0xFF94A3B8); // Soft grey hint
  static const Color divider = Color(0xFFE2E8F0); // Subtle light divider
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Category colors for Stankap
  static const Map<String, Color> categoryColors = {
    'cat_food': Color(0xFFF59E0B),
    'cat_transport': Color(0xFF0284C7),
    'cat_home': Color(0xFF2563EB),
    'cat_leisure': Color(0xFFEC4899),
    'cat_health': Color(0xFF10B981),
    'cat_other_exp': Color(0xFF64748B),
    'cat_salary': Color(0xFF10B981),
    'cat_freelance': Color(0xFF84CC16),
    'cat_invest': Color(0xFF8B5CF6),
    'cat_other_inc': Color(0xFF14B8A6),
  };

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: GoogleFonts.outfit(color: textPrimary),
        bodyMedium: GoogleFonts.outfit(color: textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.outfit(color: textHint, fontSize: 14),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
      ),
    );
  }

  // Soft Glass / Elevation Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: primary.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
