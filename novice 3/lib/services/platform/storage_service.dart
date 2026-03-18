// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../session_logger.dart';
import '../../models/session_model.dart';

/// Cross-platform session storage.
///
/// Mobile (iOS/Android): delegates to SessionLogger (SQLite via sqflite).
/// Web:                  stores sessions as JSON in SharedPreferences
///                       (backed by localStorage in the browser).
///
/// SharedPreferences is available on all platforms, so it is used as
/// the web fallback without requiring a separate sqflite import on web.
///
/// Note: For large datasets on web, IndexedDB would be more appropriate.
/// SharedPreferences is sufficient for Phase 1 pilot study volumes.
class StorageService {
  StorageService({SessionLogger? mobileLogger})
      : _mobileLogger = mobileLogger;

  final SessionLogger? _mobileLogger;
  static const _prefsKey = 'novice_sessions_v1';

  // ── Save ───────────────────────────────────────────────

  Future<void> saveSession(SessionModel session) async {
    if (!kIsWeb && _mobileLogger != null) {
      await _mobileLogger!.saveSession(session);
    } else {
      await _saveWeb(session);
    }
  }

  // ── Load all ───────────────────────────────────────────

  Future<List<SessionModel>> loadAllSessions() async {
    if (!kIsWeb && _mobileLogger != null) {
      return _mobileLogger!.loadAllSessions();
    }
    return _loadAllWeb();
  }

  // ── Load one ───────────────────────────────────────────

  Future<SessionModel?> loadSession(String id) async {
    if (!kIsWeb && _mobileLogger != null) {
      return _mobileLogger!.loadSession(id);
    }
    final all = await _loadAllWeb();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Export JSON ────────────────────────────────────────

  Future<String> exportJson() async {
    final sessions = await loadAllSessions();
    return jsonEncode(sessions.map((s) => s.toJson()).toList());
  }

  // ── Web (SharedPreferences / localStorage) ─────────────

  Future<void> _saveWeb(SessionModel session) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await _loadAllWeb();
    final updated  = [...existing.where((s) => s.id != session.id), session];
    await prefs.setString(
      _prefsKey,
      jsonEncode(updated.map((s) => s.toJson()).toList()),
    );
  }

  Future<List<SessionModel>> _loadAllWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }
}
