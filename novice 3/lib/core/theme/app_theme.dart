// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';

/// Novice design system.
/// Dark theme: maximises camera contrast, reduces eye strain in emergencies,
/// and saves battery on iPhone OLED screens.
class AppTheme {
  AppTheme._();

  // ── Brand palette ────────────────────────────────────────
  static const Color accent      = Color(0xFF00E5A0); // mint green — "go" / good
  static const Color accentWarn  = Color(0xFFFF4D6D); // coral red  — error
  static const Color accentAmber = Color(0xFFFFC947); // amber      — caution / rate

  static const Color bg        = Color(0xFF0A0D0F);
  static const Color surface   = Color(0xFF111518);
  static const Color card      = Color(0xFF161C20);
  static const Color border    = Color(0x14FFFFFF); // 8% white
  static const Color textPrimary   = Color(0xFFE8EAEC);
  static const Color textSecondary = Color(0xFF5A6470);

  // ── Typography ───────────────────────────────────────────
  // Using system font fallbacks until custom font assets are added
  static const TextStyle mono = TextStyle(
    fontFamily: 'Courier New', // TODO: replace with Space Mono when added to assets
    letterSpacing: 0.5,
  );

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary:   accent,
        secondary: accentAmber,
        error:     accentWarn,
        surface:   surface,
        onPrimary: Color(0xFF000000),
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentWarn,
          side: const BorderSide(color: Color(0x4DFF4D6D)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
