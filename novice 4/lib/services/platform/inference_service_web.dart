// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Web ML inference — calls hosted CNN_BiLSTM API.
// Falls back to rule-based classification when API is unreachable.

import 'dart:collection';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import '../../models/session_model.dart';
import 'cpr_api_service.dart';

class InferenceServiceWeb {
  final _frameBuffer   = ListQueue<List<double>>();
  final _wristYHistory = ListQueue<_TimedSample>();
  final _api           = CprApiService();

  // ── FIX: Depth calibration ─────────────────────────────────────────────────
  // Track wrist Y range within the session to normalise depth dynamically.
  // On first frames we have no range yet — we use a conservative fixed scale
  // until we have enough history (>= _depthCalibFrames samples).
  //
  // Physical basis: typical adult torso is ~50–60 cm tall when seated/kneeling.
  // Sternum compression target = 5–6 cm ≈ 9–11% of torso height.
  // normalizedWristDisplacement() returns a value in [0,1] relative to torso.
  // So: depthCm = normDisp * torsoHeightCm
  // We estimate torsoHeightCm from shoulderWidth (roughly 1:1 in adults).
  double _shoulderWidthPxSum = 0;
  int _shoulderWidthSamples  = 0;
  static const int _depthCalibFrames = 30; // ~1.2s at 25fps before depth is live

  bool get isModelLoaded => _api.isReachable;

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

    _updateDepthCalibration(frame);

    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);

    if (_api.isReachable &&
        _frameBuffer.length >= AppConstants.temporalWindowFrames) {
      final sequence   = _frameBuffer.toList();
      final prediction = await _api.predict(sequence);

      if (prediction != null) {
        print('[InferenceServiceWeb] API → ${prediction.resolvedLabel} '
              '(${prediction.resolvedConfidence.toStringAsFixed(2)})');
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
          currentBpm:          bpm,
          estimatedDepthCm:    depth,
          elbowAngleMean:      (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
          spineVerticalityDeg: frame.spineVerticality,
          isSimulated:         false,
        );
      }
    }

    return _ruleBased(frame, bpm, depth);
  }

  InferenceResult infer(LandmarkFrame frame) {
    inferAsync(frame);
    _updateDepthCalibration(frame);
    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);
    return _ruleBased(frame, bpm, depth);
  }

  List<double> _buildFeatures(LandmarkFrame frame) {
    return LandmarkMath.buildFeatureVector(
      leftElbowAngle:     frame.leftElbowAngle,
      rightElbowAngle:    frame.rightElbowAngle,
      spineVerticality:   frame.spineVerticality,
      wristY:             frame.wristMidY,
      wristVelocityY:     frame.wristVelocityY,
      wristAccelerationY: frame.wristAccelerationY,
      normalizedDepth: LandmarkMath.normalizedWristDisplacement(
        frame.wristMidY, frame.leftShoulderY, frame.leftHipY,
      ),
      shoulderWidth:    frame.shoulderWidth,
      meanConfidence:   frame.meanLandmarkConfidence,
      leftElbowVisible:
          frame.leftElbowVisibility > AppConstants.minLandmarkVisibility,
      rightElbowVisible:
          frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );
  }

  InferenceResult _ruleBased(LandmarkFrame frame, double bpm, double depth) {
    String label = 'correct_compression';
    if (bpm > 0) {
      if (bpm < AppConstants.cprMinRateBpm) label = 'rate_too_slow';
      if (bpm > AppConstants.cprMaxRateBpm) label = 'rate_too_fast';
    }
    if (label == 'correct_compression') {
      final meanElbow = (frame.leftElbowAngle + frame.rightElbowAngle) / 2;
      if (meanElbow < AppConstants.elbowLockAngleDeg)            label = 'bent_elbows';
      else if (depth > 0 && depth < AppConstants.cprMinDepthCm - 0.5) label = 'too_shallow';
      else if (depth > AppConstants.cprMaxDepthCm + 0.5)         label = 'too_deep';
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
      isSimulated:         true,
    );
  }

  // ── Depth calibration helpers ──────────────────────────────────────────────

  void _updateDepthCalibration(LandmarkFrame frame) {
    if (frame.shoulderWidth > 0.05) { // ignore frames with invisible shoulders
      _shoulderWidthPxSum += frame.shoulderWidth;
      _shoulderWidthSamples++;
    }
  }

  /// Estimates physical depth in cm from normalised wrist displacement.
  ///
  /// Strategy:
  ///   1. Compute normalised wrist displacement relative to torso height
  ///      (0 = at shoulder, 1 = at hip level).
  ///   2. Multiply by estimated torso height in cm.
  ///
  /// Torso height estimation:
  ///   We use mean shoulder width as a proxy (biacromial width ≈ torso height
  ///   in seated/kneeling adults, both ~40–48 cm for typical adults).
  ///   The scale factor (AppConstants.shoulderWidthToTorsoRatio) is calibrated
  ///   to a typical rescuer distance from the manikin camera.
  ///
  /// Before calibration frames accumulate, falls back to a fixed 45 cm torso.
  double _estimateDepthCm(LandmarkFrame frame) {
    final normDisp = LandmarkMath.normalizedWristDisplacement(
      frame.wristMidY,
      (frame.leftShoulderY + frame.rightShoulderY) / 2,
      (frame.leftHipY + frame.rightHipY) / 2,
    );

    // Estimate torso height in cm
    double torsoHeightCm;
    if (_shoulderWidthSamples >= _depthCalibFrames) {
      final meanShoulderWidthNorm = _shoulderWidthPxSum / _shoulderWidthSamples;
      // shoulderWidthToTorsoRatio: empirically ~0.85 (shoulder width ≈ 85% of torso height)
      torsoHeightCm = (meanShoulderWidthNorm * AppConstants.normToPhysicalCmScale)
                      / AppConstants.shoulderWidthToTorsoRatio;
    } else {
      // Conservative fallback until we have enough calibration data
      torsoHeightCm = AppConstants.fallbackTorsoHeightCm;
    }

    // Clamp to clinically plausible range [0, 10] cm
    return (normDisp * torsoHeightCm).clamp(0.0, 10.0);
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

  void dispose() {}
}

class _TimedSample {
  final DateTime timestamp;
  final double   value;
  _TimedSample(this.timestamp, this.value);
}
