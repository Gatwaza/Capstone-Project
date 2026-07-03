// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/session_model.dart';
import '../../models/landmark_frame.dart';

/// Web-only session storage: sessions as JSON in SharedPreferences
/// (backed by localStorage in the browser).
///
/// NOTE: mobile (SQLite via SessionLogger) support is on hold. If mobile
/// work resumes, restore SessionLogger, the mobileLogger constructor param,
/// and the kIsWeb branches this file used to have (see git history).
///
/// Schema v2: SessionModel now includes rawFrames (List<LandmarkFrame>).
/// Raw frames are stored with the session but stripped from the summary
/// list view to keep memory footprint low.
///
/// Storage keys:
///   novice_sessions_v2        — JSON array of sessions (rawFrames included)
///   novice_frames_<sessionId> — overflow key for very large frame sets
class StorageService {
  StorageService();

  static const _sessionsKey = 'novice_sessions_v2';

  // ── Save ───────────────────────────────────────────────

  Future<void> saveSession(SessionModel session) async {
    await _saveWeb(session);
  }

  // ── Load all (summaries — rawFrames stripped) ──────────

  Future<List<SessionModel>> loadAllSessions() async {
    final all = await _loadAllWeb();
    // Strip raw frames from the list view to keep memory low
    return all.map((s) => s.copyWith(rawFrames: const [])).toList();
  }

  // ── Load one (with rawFrames intact) ──────────────────

  Future<SessionModel?> loadSession(String id) async {
    final all = await _loadAllWeb();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Review labelling ───────────────────────────────────

  /// Saves a reviewer's label + note back onto an existing session.
  Future<void> labelSession(
    String id, {
    required String label,
    String? note,
  }) async {
    final session = await loadSession(id);
    if (session == null) return;
    await saveSession(session.copyWith(reviewLabel: label, reviewNote: note));
  }

  // ── Export helpers ─────────────────────────────────────

  /// Returns a JSON string of all sessions (no raw frames) for UI sharing.
  Future<String> exportSummaryJson() async {
    final sessions = await loadAllSessions();
    return jsonEncode(sessions.map((s) => s.toJson()).toList());
  }

  /// Alias for [exportSummaryJson] — used by SettingsScreen share button.
  Future<String> exportJson() => exportSummaryJson();

  /// Returns newline-delimited JSON (NDJSON) of raw frame data for retraining.
  ///
  /// Each line is one session object:
  ///   { "id": "...", "label": "correct|incorrect|partial|null",
  ///     "startedAt": "...", "frames": [ { ...LandmarkFrame fields... } ] }
  ///
  /// This format is directly consumable by the Python retraining pipeline:
  ///   ml_pipeline/src/data/ingest_novice_sessions.py
  Future<String> exportFramesNdjson() async {
    final sessions = await _loadAllWeb(); // full, with rawFrames
    final buffer = StringBuffer();
    for (final session in sessions) {
      if (session.rawFrames.isEmpty) continue;
      final record = {
        'id':        session.id,
        'startedAt': session.startedAt.toIso8601String(),
        'label':     session.reviewLabel,
        'language':  session.language,
        'qualityScore': session.qualityScore,
        'totalCompressions': session.totalCompressions,
        'meanBpm':   session.meanBpm,
        'meanDepthCm': session.meanDepthCm,
        'frames':    session.rawFrames.map(_frameToMap).toList(),
      };
      buffer.writeln(jsonEncode(record));
    }
    return buffer.toString();
  }

  // ── Web (SharedPreferences / localStorage) ─────────────

  Future<void> _saveWeb(SessionModel session) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await _loadAllWeb();
    final updated  = [...existing.where((s) => s.id != session.id), session];
    await prefs.setString(
      _sessionsKey,
      jsonEncode(updated.map((s) => s.toJson()).toList()),
    );
  }

  Future<List<SessionModel>> _loadAllWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_sessionsKey);
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

  // ── Serialisation helpers ──────────────────────────────

  static Map<String, dynamic> _frameToMap(LandmarkFrame f) => {
    'capturedAt':           f.capturedAt.toIso8601String(),
    'leftShoulderX':        f.leftShoulderX,
    'leftShoulderY':        f.leftShoulderY,
    'rightShoulderX':       f.rightShoulderX,
    'rightShoulderY':       f.rightShoulderY,
    'leftElbowX':           f.leftElbowX,
    'leftElbowY':           f.leftElbowY,
    'rightElbowX':          f.rightElbowX,
    'rightElbowY':          f.rightElbowY,
    'leftWristX':           f.leftWristX,
    'leftWristY':           f.leftWristY,
    'rightWristX':          f.rightWristX,
    'rightWristY':          f.rightWristY,
    'leftHipX':             f.leftHipX,
    'leftHipY':             f.leftHipY,
    'rightHipX':            f.rightHipX,
    'rightHipY':            f.rightHipY,
    'leftElbowVisibility':  f.leftElbowVisibility,
    'rightElbowVisibility': f.rightElbowVisibility,
    'leftWristVisibility':  f.leftWristVisibility,
    'rightWristVisibility': f.rightWristVisibility,
    'leftElbowAngle':       f.leftElbowAngle,
    'rightElbowAngle':      f.rightElbowAngle,
    'spineVerticality':     f.spineVerticality,
    'wristMidX':            f.wristMidX,
    'wristMidY':            f.wristMidY,
    'shoulderWidth':        f.shoulderWidth,
    'wristVelocityY':       f.wristVelocityY,
    'wristAccelerationY':   f.wristAccelerationY,
    'allLandmarksVisible':  f.allLandmarksVisible,
    'meanLandmarkConfidence': f.meanLandmarkConfidence,
  };
}