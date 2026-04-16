import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const brand = Color(0xFF00236F);
    const primaryContainer = Color(0xFF1E3A8A);
    const tertiaryFixed = Color(0xFF71F8E4);
    const background = Color(0xFFF7F9FB);
    const surface = Color(0xFFFFFFFF);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: brand,
      primary: brand,
      secondary: const Color(0xFF00687A),
      tertiary: const Color(0xFF004941),
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: brand,
        elevation: 0,
      ),
      dividerColor: const Color(0xFFE6E8EA),
      cardColor: surface,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tertiaryFixed.withValues(alpha: 0.18),
        selectedColor: brand,
        labelStyle: const TextStyle(
          color: Color(0xFF005048),
        ),
      ),
    );
  }
}
