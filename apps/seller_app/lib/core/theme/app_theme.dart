import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF0F172A);
    const accent = Color(0xFF10B981);
    const background = Color(0xFFF8FAFC);
    const surface = Color(0xFFFFFFFF);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      dividerColor: const Color(0xFFE6E8EA),
      cardColor: surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: accent.withOpacity(0.1),
        selectedColor: primary,
        labelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
