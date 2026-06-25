// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Env — runtime credential access for Flutter Web.
//
// WHY RUNTIME INSTEAD OF COMPILE-TIME:
//   String.fromEnvironment / --dart-define is silently broken in Flutter
//   3.29.3's web build pipeline. Instead, run_local.sh injects credentials
//   as window.__NOVICE_CONFIG__ into index.html at serve time, and we read
//   them here via dart:js interop at app startup.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  Env._();

  static String get supabaseUrl     => _get('supabaseUrl');
  static String get supabaseAnonKey => _get('supabaseAnonKey');
  static String get researcherPin   => _get('researcherPin', fallback: '2026');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String _get(String key, {String fallback = ''}) {
    if (!kIsWeb) return fallback;
    try {
      final config = js.context['__NOVICE_CONFIG__'];
      if (config == null) {
        _log('__NOVICE_CONFIG__ is null — injection may have failed');
        return fallback;
      }
      final jsObj = config as js.JsObject;
      if (!jsObj.hasProperty(key)) {
        _log('__NOVICE_CONFIG__ missing property "$key"');
        return fallback;
      }
      final value = jsObj[key];
      if (value == null) return fallback;
      final str = value.toString();
      if (str == 'null' || str == 'undefined') return fallback;
      return str;
    } catch (e) {
      _log('Error reading "$key": $e');
      return fallback;
    }
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[Env] $msg');
  }

  static void warmup() {
    if (!kIsWeb) return;
    if (isConfigured) {
      _log('Config loaded ✓  URL=${supabaseUrl.substring(0, 30)}...');
    } else {
      _log('✗ Not configured. Dumping raw window.__NOVICE_CONFIG__:');
      try {
        final raw = js.context['__NOVICE_CONFIG__'];
        _log('  raw type = ${raw.runtimeType}  value = $raw');
        if (raw != null) {
          final jsObj = raw as js.JsObject;
          _log('  supabaseUrl     = ${jsObj['supabaseUrl']}');
          _log('  supabaseAnonKey = ${jsObj['supabaseAnonKey']}');
        }
      } catch (e) {
        _log('  dump failed: $e');
      }
    }
  }
}
