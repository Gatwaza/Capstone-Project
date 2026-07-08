// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// theme_mode_provider.dart — persisted app-wide light/dark toggle.
//
// This is deliberately a single global switch, not a per-screen setting:
// the person picks light or dark once (in Settings, or via the quick
// toggle on the home screen), and every screen in the app follows it
// immediately, because AppTheme.bg/.card/.border/.textPrimary/
// .textSecondary are read fresh on every rebuild (see app_theme.dart).
//
// The one deliberate exception is the live-camera training screen, which
// always renders its HUD in AppTheme's fixed *Dark tokens regardless of
// this setting — a legibility requirement over live video, not a theme
// preference.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

const _prefsKey = 'novice.theme_mode';

/// Notifies listeners with the current [ThemeMode] and keeps
/// [AppTheme]'s mutable color fields in sync with it.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _apply(mode);
    } catch (_) {
      // No persisted preference yet (or storage unavailable) — keep default.
      _apply(ThemeMode.light);
    }
  }

  void _apply(ThemeMode mode) {
    AppTheme.applyBrightness(mode == ThemeMode.dark);
    state = mode;
  }

  /// Switches to the given mode and persists the choice.
  Future<void> setMode(ThemeMode mode) async {
    _apply(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Persistence is best-effort — the toggle still works for this session.
    }
  }

  /// Flips light ⇄ dark.
  Future<void> toggle() => setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);