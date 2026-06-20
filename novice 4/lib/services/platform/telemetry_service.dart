// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// TelemetryService — uploads completed sessions to Supabase for research analysis.
///
/// Design principles:
///   • Fire-and-forget: never awaited in the UI path. A network failure must
///     never block the user from seeing their results screen.
///   • Silent on error: logs to debug console only. No user-visible errors.
///   • No PII: no user ID, no name, no email. Sessions identified only by
///     timestamp-based ID and device language setting.
///   • Write-only from client: Supabase RLS policy allows INSERT but not
///     SELECT/UPDATE/DELETE from the anon key. Researcher reads via
///     authenticated Supabase dashboard or service-role key.
///
/// Setup:
///   1. Create a Supabase project at https://supabase.com
///   2. Run the SQL in docs/SUPABASE_SETUP.sql
///   3. Set SUPABASE_URL and SUPABASE_ANON_KEY as --dart-define values
///      (see docs/DEPLOYMENT.md) or replace the const defaults below.

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
            const String.fromEnvironment(
              'SUPABASE_URL',
              defaultValue: '',
            ),
        _anonKey = anonKey ??
            const String.fromEnvironment(
              'SUPABASE_ANON_KEY',
              defaultValue: '',
            );

  final String _supabaseUrl;
  final String _anonKey;

  bool get _configured =>
      _supabaseUrl.isNotEmpty && _anonKey.isNotEmpty;

  /// Uploads a completed session to Supabase.
  ///
  /// Call with unawaited() or as fire-and-forget — this method catches all
  /// exceptions internally and never throws.
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
      // Never surface telemetry errors to the user.
      getIt<Logger>().d('[Telemetry] Upload error (silent): $e');
    }
  }

  Map<String, dynamic> _buildPayload(SessionModel session) {
    final taskAcc  = session.taskAccuracies;
    final taskConf = session.taskConfidences;
    final dur = session.endedAt.difference(session.startedAt).inSeconds;

    return {
      'session_id':         session.id,
      'started_at':         session.startedAt.toIso8601String(),
      'ended_at':           session.endedAt.toIso8601String(),
      'duration_seconds':   dur,
      'total_compressions': session.totalCompressions,
      'mean_bpm':           _round(session.meanBpm),
      'mean_depth_cm':      _round(session.meanDepthCm),
      'cpr_fraction':       _round(session.cprFraction),
      'quality_score':      session.qualityScore,
      // Per-task accuracies (core research metrics)
      'rate_accuracy':      _round(taskAcc['rate']   ?? 0.0),
      'depth_accuracy':     _round(taskAcc['depth']  ?? 0.0),
      'recoil_accuracy':    _round(taskAcc['recoil'] ?? 0.0),
      // Per-task model confidences
      'rate_confidence':    _round(taskConf['rate']   ?? 0.0),
      'depth_confidence':   _round(taskConf['depth']  ?? 0.0),
      'recoil_confidence':  _round(taskConf['recoil'] ?? 0.0),
      // Session metadata
      'model_was_available': session.modelWasAvailable,
      'language':            session.language,
      // Error breakdown as JSONB (optional, for technique analysis)
      'error_rates':         jsonEncode(session.errorRates),
    };
  }

  double _round(double v) => double.parse(v.toStringAsFixed(4));
}
