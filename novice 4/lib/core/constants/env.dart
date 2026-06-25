// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Env — runtime credential access for Flutter Web.
//
// WHY dart:js_interop INSTEAD OF dart:js:
//   The legacy dart:js library (js.context['key'] / JsObject cast) silently
//   returns null or throws in release/minified builds produced by
//   `flutter build web`. In debug / `flutter run` it works — which is why
//   the app worked locally but failed in production.
//
//   dart:js_interop uses @JS() external declarations resolved at compile time.
//   They survive dart2js tree-shaking and minification correctly in both
//   debug and release modes.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_interop';

// ── External JS declarations ─────────────────────────────────────────────────
// Maps directly to window.__NOVICE_CONFIG__ which is injected by:
//   • web/index.html (source, for local dev)
//   • scripts/vercel_build.sh (production, overwrites with real env vars)

@JS('__NOVICE_CONFIG__')
external _NoviceConfig? get _noviceConfig;

extension type _NoviceConfig._(JSObject _) implements JSObject {
  external String? get supabaseUrl;
  external String? get supabaseAnonKey;
  external String? get researcherPin;
}

// ── Env ──────────────────────────────────────────────────────────────────────

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
      final config = _noviceConfig;
      if (config == null) {
        _log('__NOVICE_CONFIG__ is null — injection may have failed');
        return fallback;
      }
      final String? value = switch (key) {
        'supabaseUrl'     => config.supabaseUrl,
        'supabaseAnonKey' => config.supabaseAnonKey,
        'researcherPin'   => config.researcherPin,
        _                 => null,
      };
      if (value == null ||
          value.isEmpty ||
          value == 'null' ||
          value == 'undefined') {
        return fallback;
      }
      return value;
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
      _log('✗ Not configured. Check that web/index.html contains:');
      _log('  <script>window.__NOVICE_CONFIG__={supabaseUrl:"...",supabaseAnonKey:"...",...};</script>');
      _log('  Attempted reads:');
      _log('    supabaseUrl     = "${_get('supabaseUrl')}"');
      _log('    supabaseAnonKey = "${_get('supabaseAnonKey')}"');
    }
  }
}