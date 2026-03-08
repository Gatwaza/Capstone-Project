import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();
  static const Color background   = Color(0xFF0A0A0F);
  static const Color surface      = Color(0xFF151520);
  static const Color card         = Color(0xFF1E1E2E);
  static const Color cardAlt      = Color(0xFF1A1A28);
  static const Color accentRed    = Color(0xFFE53935);
  static const Color accentRedDark= Color(0xFFB71C1C);
  static const Color accentGreen  = Color(0xFF43A047);
  static const Color accentAmber  = Color(0xFFFF8F00);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0x99FFFFFF);
  static const Color textMuted    = Color(0x61FFFFFF);
  static const Color divider      = Color(0x1FFFFFFF);
  static const Color skeletonLine = Color(0xCCFFFFFF);
  static const Color skeletonJoint= Color(0xFFE53935);
}

class AppTheme {
  AppTheme._();

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.accentRed,
      secondary: AppColors.accentGreen,
      surface:   AppColors.surface,
      error:     AppColors.accentRed,
    ),
    cardColor: AppColors.card,
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
      titleLarge:   TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium:  TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge:    TextStyle(color: AppColors.textPrimary, fontSize: 16),
      bodyMedium:   TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall:    TextStyle(color: AppColors.textMuted, fontSize: 12),
      labelSmall:   TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.2),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
  );
}
