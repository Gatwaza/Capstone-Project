// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// HTTP client to the hosted CNN_BiLSTM inference API.
// Replaces rule-based fallback on web when API is reachable.

import 'dart:convert';
import 'package:http/http.dart' as http;

class CprApiService {
  CprApiService({String? baseUrl})
      : _base = baseUrl ?? const String.fromEnvironment(
          'CPR_API_URL',
          defaultValue: 'https://Jeanrobert-Novice.hf.space',
        );

  final String _base;
  bool _reachable = false;
  bool get isReachable => _reachable;

  // Call once at startup — sets _reachable flag
  Future<void> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 5));
      _reachable = res.statusCode == 200;
    } catch (_) {
      _reachable = false;
    }
  }

  /// Sends a (60 × 12) feature sequence to the API.
  /// Returns parsed [ApiPrediction] or null on failure.
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
      rateLabel:       json['rate']['label']       as String,
      rateConfidence:  (json['rate']['confidence'] as num).toDouble(),
      depthLabel:      json['depth']['label']      as String,
      depthConfidence: (json['depth']['confidence'] as num).toDouble(),
      recoilLabel:     json['recoil']['label']     as String,
      recoilConfidence:(json['recoil']['confidence'] as num).toDouble(),
    );
  }

  // Merge rate + depth + recoil into a single label FeedbackEngine understands.
  // Priority: rate errors first, then depth, then recoil.
  String get resolvedLabel {
    if (rateLabel == 'Too_Fast') return 'rate_too_fast';
    if (rateLabel == 'Too_Slow') return 'rate_too_slow';
    if (depthLabel == 'Too_Deep') return 'too_deep';
    if (depthLabel == 'Too_Shallow') return 'too_shallow';
    if (recoilLabel == 'Incomplete') return 'incomplete_decomp';
    return 'correct_compression';
  }

  double get resolvedConfidence {
    if (rateLabel != 'Correct') return rateConfidence;
    if (depthLabel != 'Correct') return depthConfidence;
    return recoilConfidence;
  }
}