// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'enum_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B5E20); // Deep forest green
  static const Color primaryLight = Color(0xFF4CAF50); // Vibrant green
  static const Color primaryDark = Color(0xFF0A3D11);
  static const Color secondary = Color(0xFFFF6F00); // Warm amber
  static const Color secondaryLight = Color(0xFFFFB300);
  static const Color surface = Color(0xFFF9F6F0); // Warm off-white
  static const Color background = Color(0xFFF4F1EB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF555555);
  static const Color textLight = Color(0xFF888888);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color divider = Color(0xFFE0D9CC);

  static const Map<EventCategoryDisplay, Color> categoryColors = {};

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32, fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w700, color: textDark),
        headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w400, color: textMedium),
        bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w400, color: textMedium),
        labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: textLight, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: textLight, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: divider),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

enum EventCategoryDisplay {
  environment,
  education,
  health,
  community,
  animals,
  elderly,
  children,
  disaster
}

class CategoryHelper {
  static String getName(dynamic category) {
    final map = {
      'environment': 'Environment',
      'education': 'Education',
      'health': 'Health',
      'community': 'Community',
      'animals': 'Animals',
      'elderly': 'Elderly',
      'children': 'Children',
      'disaster': 'Disaster Relief',
    };
    return map[enumValueName(category)] ?? enumValueName(category);
  }

  static Color getColor(dynamic category) {
    final map = {
      'environment': const Color(0xFF2E7D32),
      'education': const Color(0xFF1565C0),
      'health': const Color(0xFFC62828),
      'community': const Color(0xFF6A1B9A),
      'animals': const Color(0xFFE65100),
      'elderly': const Color(0xFF00695C),
      'children': const Color(0xFFAD1457),
      'disaster': const Color(0xFF4E342E),
    };
    return map[enumValueName(category)] ?? Colors.grey;
  }

  static IconData getIcon(dynamic category) {
    final map = {
      'environment': Icons.eco,
      'education': Icons.school,
      'health': Icons.favorite,
      'community': Icons.people,
      'animals': Icons.pets,
      'elderly': Icons.elderly,
      'children': Icons.child_care,
      'disaster': Icons.emergency,
    };
    return map[enumValueName(category)] ?? Icons.category;
  }
}
