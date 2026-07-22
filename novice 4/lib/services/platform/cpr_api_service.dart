// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// HTTP client to the hosted TCN inference API.
// Replaces rule-based fallback on web when API is reachable.
import 'dart:convert';
import 'package:http/http.dart' as http;

class CprApiService {
  CprApiService({String? baseUrl})
      : _base = baseUrl ?? const String.fromEnvironment(
          'CPR_API_URL',
          defaultValue: 'https://jeanrobert-novice.hf.space', // ← all lowercase
        );

  final String _base;
  bool _reachable = false;
  bool get isReachable => _reachable;

  // FIX (model never predicts for the whole session after a cold Space):
  // checkHealth() used to run exactly once, at app startup. Hugging Face
  // Spaces on the free tier sleep after inactivity and can take 30-60s+ to
  // cold-boot — well past the 15s timeout below. If the Space happened to
  // be asleep at startup, _reachable latched to false and NOTHING ever
  // asked again: every _maybeCallApi() call in inference_service_web.dart
  // bails on `if (!_api.isReachable) return;` for the rest of the session,
  // no matter how correctly the user compresses. _lastHealthCheckAt +
  // maybeRecheckHealth() below let the inference service opportunistically
  // retry (throttled, so we don't hammer a genuinely-down API every frame)
  // instead of trusting a single point-in-time result forever.
  DateTime? _lastHealthCheckAt;
  static const Duration _healthRecheckInterval = Duration(seconds: 20);

  // Call at startup — sets _reachable flag.
  Future<void> checkHealth() async {
    _lastHealthCheckAt = DateTime.now();
    try {
      final res = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 15)); // ← bumped from 5s
      _reachable = res.statusCode == 200;
      print('[CprApiService] health check: ${res.statusCode} → reachable=$_reachable');
    } catch (e) {
      _reachable = false;
      print('[CprApiService] health check failed: $e');
    }
  }

  /// Opportunistic, throttled re-check. Safe to call every frame — it only
  /// actually issues a network request once every [_healthRecheckInterval],
  /// and only while we currently believe the API is unreachable (a Space
  /// that's already confirmed healthy doesn't need re-probing here; a real
  /// outage after that point will surface via predict() failing per-call).
  /// Call this from the inference gate BEFORE bailing on `!isReachable`, so
  /// a Space that finishes cold-booting mid-session gets picked up instead
  /// of staying permanently marked dead.
  Future<void> maybeRecheckHealth() async {
    if (_reachable) return;
    final last = _lastHealthCheckAt;
    if (last != null && DateTime.now().difference(last) < _healthRecheckInterval) {
      return;
    }
    await checkHealth();
  }

  /// Sends a (60 × 12) feature sequence to the API.
  Future<ApiPrediction?> predict(List<List<double>> sequence) async {
    if (!_reachable) return null;
    try {
      final res = await http
          .post(
            Uri.parse('$_base/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sequence': sequence}),
          )
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return ApiPrediction.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class ApiPrediction {
  final String rateLabel;
  final double rateConfidence;
  final String depthLabel;
  final double depthConfidence;
  final String recoilLabel;
  final double recoilConfidence;

  const ApiPrediction({
    required this.rateLabel,
    required this.rateConfidence,
    required this.depthLabel,
    required this.depthConfidence,
    required this.recoilLabel,
    required this.recoilConfidence,
  });

  factory ApiPrediction.fromJson(Map<String, dynamic> json) {
    return ApiPrediction(
      rateLabel:        json['rate']['label']        as String,
      rateConfidence:   (json['rate']['confidence']  as num).toDouble(),
      depthLabel:       json['depth']['label']       as String,
      depthConfidence:  (json['depth']['confidence'] as num).toDouble(),
      recoilLabel:      json['recoil']['label']      as String,
      recoilConfidence: (json['recoil']['confidence'] as num).toDouble(),
    );
  }

  String get resolvedLabel {
    if (rateLabel == 'Too_Fast')      return 'rate_too_fast';
    if (rateLabel == 'Too_Slow')      return 'rate_too_slow';
    if (depthLabel == 'Too_Deep')     return 'too_deep';
    if (depthLabel == 'Too_Shallow')  return 'too_shallow';
    if (recoilLabel == 'Incomplete')  return 'incomplete_decomp';
    return 'correct_compression';
  }

  double get resolvedConfidence {
    if (rateLabel != 'Correct')  return rateConfidence;
    if (depthLabel != 'Correct') return depthConfidence;
    return recoilConfidence;
  }
}