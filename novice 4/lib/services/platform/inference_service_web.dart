// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Web ML inference — calls hosted CNN_BiLSTM API.
// Falls back to rule-based classification when API is unreachable.

import 'dart:collection';

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import '../../models/session_model.dart';
import 'cpr_api_service.dart';

class InferenceServiceWeb {
  final _frameBuffer   = ListQueue<List<double>>();
  final _wristYHistory = ListQueue<_TimedSample>();
  final _api           = CprApiService();

  bool get isModelLoaded => _api.isReachable;

  // Called once from injection.dart after registration
  Future<void> init() async {
    await _api.checkHealth();
  }

  Future<InferenceResult> inferAsync(LandmarkFrame frame) async {
    final features = _buildFeatures(frame);

    _frameBuffer.addLast(features);
    while (_frameBuffer.length > AppConstants.temporalWindowFrames) {
      _frameBuffer.removeFirst();
    }

    _wristYHistory.addLast(_TimedSample(frame.capturedAt, frame.wristMidY));
    while (_wristYHistory.length > AppConstants.bpmHistoryLength) {
      _wristYHistory.removeFirst();
    }

    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);

    // ── Try API inference when buffer is full ────────────────────
    if (_api.isReachable &&
        _frameBuffer.length >= AppConstants.temporalWindowFrames) {
      final sequence = _frameBuffer.toList();
      final prediction = await _api.predict(sequence);

      if (prediction != null) {
        return InferenceResult(
          timestamp:           DateTime.now(),
          topClassIndex:       0,
          topClassLabel:       prediction.resolvedLabel,
          topClassConfidence:  prediction.resolvedConfidence,
          allClassScores: {
            prediction.rateLabel:   prediction.rateConfidence,
            prediction.depthLabel:  prediction.depthConfidence,
            prediction.recoilLabel: prediction.recoilConfidence,
          },
          currentBpm:           bpm,
          estimatedDepthCm:     depth,
          elbowAngleMean:       (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
          spineVerticalityDeg:  frame.spineVerticality,
          isSimulated:          false,  // real model output
        );
      }
      // API call failed mid-session — mark unreachable and fall through
      // (next infer() call will retry health check via _api.isReachable guard)
    }

    // ── Rule-based fallback ──────────────────────────────────────
    return _ruleBased(frame, bpm, depth);
  }

  // Keep sync infer() so existing callers don't break —
  // it returns a rule-based result immediately and fires the async
  // API call in the background, updating next frame.
  InferenceResult infer(LandmarkFrame frame) {
    inferAsync(frame); // fire-and-forget; result used next frame
    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);
    return _ruleBased(frame, bpm, depth);
  }

  // ── Feature builder (matches Python Stage 4 exactly) ────────────────────
  List<double> _buildFeatures(LandmarkFrame frame) {
    return LandmarkMath.buildFeatureVector(
      leftElbowAngle:     frame.leftElbowAngle,
      rightElbowAngle:    frame.rightElbowAngle,
      spineVerticality:   frame.spineVerticality,
      wristY:             frame.wristMidY,
      wristVelocityY:     frame.wristVelocityY,
      wristAccelerationY: frame.wristAccelerationY,
      normalizedDepth:    LandmarkMath.normalizedWristDisplacement(
        frame.wristMidY, frame.leftShoulderY, frame.leftHipY,
      ),
      shoulderWidth:      frame.shoulderWidth,
      meanConfidence:     frame.meanLandmarkConfidence,
      leftElbowVisible:
          frame.leftElbowVisibility > AppConstants.minLandmarkVisibility,
      rightElbowVisible:
          frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );
  }

  InferenceResult _ruleBased(
    LandmarkFrame frame, double bpm, double depth,
  ) {
    String label = 'correct_compression';
    String? rateError;
    if (bpm > 0) {
      if (bpm < AppConstants.cprMinRateBpm) rateError = 'rate_too_slow';
      if (bpm > AppConstants.cprMaxRateBpm) rateError = 'rate_too_fast';
    }
    if (rateError != null) {
      label = rateError;
    } else {
      final meanElbow = (frame.leftElbowAngle + frame.rightElbowAngle) / 2;
      if (meanElbow < AppConstants.elbowLockAngleDeg) label = 'bent_elbows';
      else if (depth > 0 && depth < AppConstants.cprMinDepthCm - 0.5) label = 'too_shallow';
      else if (depth > AppConstants.cprMaxDepthCm + 0.5) label = 'too_deep';
    }
    return InferenceResult(
      timestamp:           DateTime.now(),
      topClassIndex:       0,
      topClassLabel:       label,
      topClassConfidence:  0.85,
      allClassScores:      {label: 0.85},
      currentBpm:          bpm,
      estimatedDepthCm:    depth,
      elbowAngleMean:      (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
      spineVerticalityDeg: frame.spineVerticality,
      isSimulated:         true,  // rule-based fallback
    );
  }

  double _estimateBpm() {
    if (_wristYHistory.length < 10) return 0;
    final samples    = _wristYHistory.toList();
    final velocities = <double>[];
    for (int i = 1; i < samples.length; i++) {
      velocities.add(samples[i].value - samples[i - 1].value);
    }
    final peaks = <DateTime>[];
    for (int i = 1; i < velocities.length - 1; i++) {
      if (velocities[i] > velocities[i - 1] &&
          velocities[i] > velocities[i + 1] &&
          velocities[i] > 0.005) {
        peaks.add(samples[i + 1].timestamp);
      }
    }
    if (peaks.length < 2) return 0;
    double totalMs = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalMs += peaks[i].difference(peaks[i - 1]).inMilliseconds;
    }
    final meanMs = totalMs / (peaks.length - 1);
    return meanMs <= 0 ? 0 : (60000 / meanMs).clamp(0, 200);
  }

  double _estimateDepthCm(LandmarkFrame frame) {
    final normDisp = LandmarkMath.normalizedWristDisplacement(
      frame.wristMidY,
      (frame.leftShoulderY + frame.rightShoulderY) / 2,
      (frame.leftHipY + frame.rightHipY) / 2,
    );
    return (normDisp * 50).clamp(0, 10);
  }

  void dispose() {}
}

class _TimedSample {
  final DateTime timestamp;
  final double   value;
  _TimedSample(this.timestamp, this.value);
}