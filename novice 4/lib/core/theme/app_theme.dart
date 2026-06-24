// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// app_theme.dart — Unified Flutter × Landing Page design system.
// Dark-first palette. Every color token here maps 1:1 to CSS vars
// in the blended landing page (novice_blended.html).

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Brand palette (Flutter ↔ HTML parity) ──────────────
  static const Color accent      = Color(0xFF00E5A0); // mint   — "go/good"  → --mint
  static const Color accentWarn  = Color(0xFFFF4D6D); // coral  — error       → --coral
  static const Color accentAmber = Color(0xFFFFC947); // amber  — caution     → --amber

  // ── Module accent colours (matches HTML module cards) ───
  static const Color cprRed      = Color(0xFFC84B25);
  static const Color chokingAmber= Color(0xFFA8660E);
  static const Color strokePurple= Color(0xFF4840A8);
  static const Color recoveryTeal= Color(0xFF0F9070);
  static const Color aedBlue     = Color(0xFF2B7FD4);

  // ── Surface palette ─────────────────────────────────────
  static const Color bg          = Color(0xFF0A0D0F); // --bg
  static const Color surface     = Color(0xFF111518); // --surface
  static const Color card        = Color(0xFF161C20); // --card
  static const Color border      = Color(0x14FFFFFF); // --border  (8 % white)
  static const Color borderMid   = Color(0x22FFFFFF); // --border-m (14 % white)

  // ── Text ────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8EAEC);
  static const Color textSecondary = Color(0xFF5A6470);

  // ── Typography ──────────────────────────────────────────
  static const TextStyle mono = TextStyle(
    fontFamily: 'Courier New',
    letterSpacing: 0.5,
  );

  // ── Shadows ─────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 4, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 18, offset: const Offset(0, 4)),
  ];

  // ── Radii ───────────────────────────────────────────────
  static const double r   = 16;
  static const double rMd = 10;
  static const double rSm = 6;

  // ── Theme ───────────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'DM Sans',
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
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentWarn,
          side: BorderSide(color: accentWarn.withOpacity(.3)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: accent),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary, fontSize: 16, height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: textSecondary, fontSize: 14, height: 1.5,
        ),
        labelSmall: TextStyle(
          color: textSecondary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
