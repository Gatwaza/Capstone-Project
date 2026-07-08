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
  static const Color accent      = Color(0xFF00A876); // mint   — "go/good"  → --mint (deepened for light-mode contrast; still legible on the dark camera HUD)
  static const Color accentWarn  = Color(0xFFFF4D6D); // coral  — error       → --coral
  static const Color accentAmber = Color(0xFFFFC947); // amber  — caution     → --amber

  // ── Module accent colours (matches HTML module cards) ───
  static const Color cprRed      = Color(0xFFC84B25);
  static const Color chokingAmber= Color(0xFFA8660E);
  static const Color strokePurple= Color(0xFF4840A8);
  static const Color recoveryTeal= Color(0xFF0F9070);
  static const Color aedBlue     = Color(0xFF2B7FD4);

  // ── Dark tokens — full parity set for the app-wide dark theme ──
  // Also reused as the fixed, always-on palette for the live-camera HUD
  // (training_screen.dart, pose_overlay.dart, bpm_indicator.dart,
  // compression_gauge.dart), which stays dark regardless of the person's
  // chosen app theme — a legibility requirement over live video, not a
  // theme choice.
  static const Color bgDark          = Color(0xFF0A0D0F);
  static const Color surfaceDark     = Color(0xFF111518);
  static const Color cardDark        = Color(0xFF161C20);
  static const Color borderDark      = Color(0x14FFFFFF);
  static const Color borderMidDark   = Color(0x22FFFFFF);
  static const Color textPrimaryDark   = Color(0xFFE8EAEC);
  static const Color textSecondaryDark = Color(0xFF9AA4A8);

  // ── Runtime-switchable surface/text tokens ──────────────
  // These used to be `static const`, fixed to light values. They're now
  // plain mutable static fields so the whole app can flip between light
  // and dark at runtime via AppTheme.applyBrightness(), called whenever
  // themeModeProvider changes (see providers/theme_mode_provider.dart and
  // main.dart). Every screen that already reads AppTheme.bg / .card /
  // .border / .textPrimary / .textSecondary picks up the new value on its
  // next rebuild — no per-screen changes needed.
  //
  // IMPORTANT: because these are no longer compile-time constants, any
  // `const` widget that references them (e.g. `const TextStyle(color:
  // AppTheme.textPrimary)`) will no longer compile as `const` — the const
  // keyword must be dropped at that call site. This was done throughout
  // the codebase as part of this change.
  static Color bg          = bgLight;
  static Color surface     = surfaceLight;
  static Color card        = cardLight;
  static Color border      = borderLight;
  static Color borderMid   = borderMidLight;
  static Color textPrimary   = textPrimaryLight;
  static Color textSecondary = textSecondaryLight;

  static bool isDark = false;

  /// Call once whenever the app's ThemeMode changes (see main.dart) to
  /// repoint every screen's colors at the light or dark set.
  static void applyBrightness(bool dark) {
    isDark = dark;
    bg            = dark ? bgDark            : bgLight;
    surface       = dark ? surfaceDark       : surfaceLight;
    card          = dark ? cardDark          : cardLight;
    border        = dark ? borderDark        : borderLight;
    borderMid     = dark ? borderMidDark     : borderMidLight;
    textPrimary   = dark ? textPrimaryDark   : textPrimaryLight;
    textSecondary = dark ? textSecondaryDark : textSecondaryLight;
  }

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

  // ── Light-mode surface palette ───────────────────────────
  // Supervisor feedback: switch primary UI to light mode. Kept as separate
  // tokens (rather than flipping dark values) because dark tokens like
  // `border` (8% white) are invisible on a light background — light mode
  // needs its own contrast-appropriate values, not an inverted dark theme.
  // Brand/module accent colors are reused as-is so the two themes still
  // read as the same product.
  static const Color bgLight          = Color(0xFFF7F8F6);
  static const Color surfaceLight     = Color(0xFFFFFFFF);
  static const Color cardLight        = Color(0xFFFFFFFF);
  static const Color borderLight      = Color(0xFFE3E6E2);
  static const Color borderMidLight   = Color(0xFFD2D6D1);
  static const Color textPrimaryLight   = Color(0xFF14181A);
  static const Color textSecondaryLight = Color(0xFF5E6A66);


  // ── Theme ───────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'DM Sans',
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary:   accent,
        secondary: accentAmber,
        error:     accentWarn,
        surface:   surfaceLight,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: const BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentWarn,
          side: BorderSide(color: accentWarn.withOpacity(.4)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: accent),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight),
        hintStyle: const TextStyle(color: textSecondaryLight),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimaryLight, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryLight, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryLight, fontSize: 16, height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryLight, fontSize: 14, height: 1.5,
        ),
        labelSmall: TextStyle(
          color: textSecondaryLight, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'DM Sans',
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary:   accent,
        secondary: accentAmber,
        error:     accentWarn,
        surface:   surfaceDark,
        onPrimary: Color(0xFF000000),
        onSurface: textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
          side: const BorderSide(color: borderDark),
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
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rMd),
          borderSide: const BorderSide(color: accent),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
        hintStyle: const TextStyle(color: textSecondaryDark),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimaryDark, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryDark, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimaryDark, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimaryDark, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryDark, fontSize: 16, height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryDark, fontSize: 14, height: 1.5,
        ),
        labelSmall: TextStyle(
          color: textSecondaryDark, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}