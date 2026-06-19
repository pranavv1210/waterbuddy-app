import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF0095F6); // Primary Blue
    const accent = Color(0xFF3BA8FF); // Secondary Blue
    const background = Color(0xFFFFFFFF); // Background
    const ink = Color(0xFF08111F); // Text Primary
    const border = Color(0xFFE2E8F0);

    final textTheme = GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        color: ink,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        color: ink,
        letterSpacing: -1,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        color: ink,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        color: ink,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleSmall: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w400,
        color: ink,
      ),
      labelLarge: GoogleFonts.outfit(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: GoogleFonts.outfit(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: background,
        surfaceContainerHighest: Color(0xFFEEF7FF), // Very Light Blue
        onSurface: ink,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          minimumSize: const Size.fromHeight(54),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withValues(alpha: 0.72)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border.withValues(alpha: 0.72)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: GoogleFonts.outfit(
          color: const Color(0xFF374151),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.outfit(
          color: const Color(0xFF9CA3AF),
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        labelStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
