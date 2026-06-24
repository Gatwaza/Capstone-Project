// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// TelemetryService — uploads completed sessions to Supabase for research analysis.
///
/// Research metrics recorded (TCN evaluation framework):
///   accuracy, precision, recall, F1-score, ROC-AUC — per task (rate/depth/recoil)
///
/// Design principles:
///   • Fire-and-forget: never awaited in the UI path.
///   • Silent on error: logs to debug console only.
///   • Write-only: RLS policy allows INSERT but not SELECT/UPDATE/DELETE.
///   • model_was_available=false sessions should be excluded from metric analysis.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../core/di/injection.dart';
import '../../models/session_model.dart';

class TelemetryService {
  TelemetryService({
    String? supabaseUrl,
    String? anonKey,
  })  : _supabaseUrl = supabaseUrl ??
            const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
        _anonKey = anonKey ??
            const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  final String _supabaseUrl;
  final String _anonKey;

  bool get _configured => _supabaseUrl.isNotEmpty && _anonKey.isNotEmpty;

  Future<void> uploadSession(SessionModel session) async {
    if (!_configured) {
      getIt<Logger>().d('[Telemetry] Not configured — skipping upload. '
          'Set SUPABASE_URL and SUPABASE_ANON_KEY dart-define values.');
      return;
    }

    try {
      final payload = _buildPayload(session);
      final response = await http
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        getIt<Logger>().i('[Telemetry] Session ${session.id} uploaded ✓');
      } else {
        getIt<Logger>().w(
          '[Telemetry] Upload failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      getIt<Logger>().d('[Telemetry] Upload error (silent): $e');
    }
  }

  Map<String, dynamic> _buildPayload(SessionModel session) {
    final dur = session.endedAt.difference(session.startedAt).inSeconds;

    return {
      // ── Identity & timing ─────────────────────────────────────────────────
      'session_id':         session.id,
      'participant_id':     session.participantId,
      'started_at':         session.startedAt.toIso8601String(),
      'ended_at':           session.endedAt.toIso8601String(),
      'duration_seconds':   dur,
      'language':           session.language,

      // ── CPR performance ───────────────────────────────────────────────────
      'total_compressions': session.totalCompressions,
      'mean_bpm':           _round(session.meanBpm),
      'mean_depth_cm':      _round(session.meanDepthCm),
      'cpr_fraction':       _round(session.cprFraction),
      'quality_score':      session.qualityScore,

      // ── Research metrics: ACCURACY ────────────────────────────────────────
      'rate_accuracy':      _round(session.rateAccuracy),
      'depth_accuracy':     _round(session.depthAccuracy),
      'recoil_accuracy':    _round(session.recoilAccuracy),

      // ── Research metrics: PRECISION ───────────────────────────────────────
      'rate_precision':     _round(session.ratePrecision),
      'depth_precision':    _round(session.depthPrecision),
      'recoil_precision':   _round(session.recoilPrecision),

      // ── Research metrics: RECALL ──────────────────────────────────────────
      'rate_recall':        _round(session.rateRecall),
      'depth_recall':       _round(session.depthRecall),
      'recoil_recall':      _round(session.recoilRecall),

      // ── Research metrics: F1-SCORE ────────────────────────────────────────
      'rate_f1':            _round(session.rateF1),
      'depth_f1':           _round(session.depthF1),
      'recoil_f1':          _round(session.recoilF1),

      // ── Research metrics: ROC-AUC (mean model confidence as proxy) ────────
      'rate_auc':           _round(session.rateAuc),
      'depth_auc':          _round(session.depthAuc),
      'recoil_auc':         _round(session.recoilAuc),

      // ── Model availability (exclude false sessions from metric analysis) ──
      'model_was_available': session.modelWasAvailable,

      // ── Per-frame class distribution (optional technique detail) ──────────
      'error_rates':         jsonEncode(session.errorRates),
    };
  }

  double _round(double v) => double.parse(v.toStringAsFixed(4));
}