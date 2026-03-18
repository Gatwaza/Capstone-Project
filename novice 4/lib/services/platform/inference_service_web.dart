// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

// Web-only — JS interop to TensorFlow.js loaded in web/index.html.

@JS()
library novice_inference_web;

import 'dart:collection';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import '../../models/session_model.dart';

// ── JS interop — TF.js bridge ────────────────────────────
// These functions are defined in web/flutter_inference_bridge.js
// (injected via web/index.html) and wrap TF.js model calls.

@JS('NoviceInferenceBridge.isModelLoaded')
external bool _isTfjsModelLoaded();

@JS('NoviceInferenceBridge.runInference')
external dynamic _runInference(List<dynamic> inputData);

/// Web ML inference via TensorFlow.js.
/// Shares the same BiLSTM model exported by ml_pipeline/src/export/convert_to_tfjs.py.
///
/// Falls back to rule-based classification when model is not loaded.
///
/// TODO: Implement web/flutter_inference_bridge.js wrapping tf.loadGraphModel()
/// For Phase 1 the fallback rule-based path is always used.
class InferenceServiceWeb {
  final _frameBuffer = ListQueue<List<double>>();
  final _wristYHistory = ListQueue<_TimedSample>();

  bool get isModelLoaded {
    try { return _isTfjsModelLoaded(); }
    catch (_) { return false; }
  }

  InferenceResult infer(LandmarkFrame frame) {
    final features = LandmarkMath.buildFeatureVector(
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
      leftElbowVisible:   frame.leftElbowVisibility > AppConstants.minLandmarkVisibility,
      rightElbowVisible:  frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );

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

    String? rateError;
    if (bpm > 0) {
      if (bpm < AppConstants.cprMinRateBpm) rateError = 'rate_too_slow';
      if (bpm > AppConstants.cprMaxRateBpm) rateError = 'rate_too_fast';
    }

    // Attempt TF.js inference
    if (isModelLoaded && _frameBuffer.length == AppConstants.temporalWindowFrames) {
      return _runTfjs(frame, bpm, depth, rateError);
    }

    return _ruleBased(frame, bpm, depth, rateError);
  }

  InferenceResult _runTfjs(
    LandmarkFrame frame, double bpm, double depth, String? rateError,
  ) {
    try {
      final inputData = _frameBuffer.map((f) => f).toList();
      final jsResult  = _runInference(inputData);
      final scores    = List<double>.from(
        (jsResult as List).map((v) => (v as num).toDouble()),
      );
      int topIdx = 0;
      double topScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > topScore) { topScore = scores[i]; topIdx = i; }
      }
      final label = rateError ?? (AppConstants.errorClassLabels[topIdx] ?? 'correct_compression');
      final allScores = <String, double>{};
      for (int i = 0; i < scores.length; i++) {
        allScores[AppConstants.errorClassLabels[i] ?? 'class_$i'] = scores[i];
      }
      return InferenceResult(
        timestamp: DateTime.now(), topClassIndex: topIdx,
        topClassLabel: label, topClassConfidence: topScore,
        allClassScores: allScores, currentBpm: bpm,
        estimatedDepthCm: depth,
        elbowAngleMean: (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
        spineVerticalityDeg: frame.spineVerticality, isSimulated: false,
      );
    } catch (_) {
      return _ruleBased(frame, bpm, depth, rateError);
    }
  }

  InferenceResult _ruleBased(
    LandmarkFrame? frame, double bpm, double depth, String? rateError,
  ) {
    String label = 'correct_compression';
    if (rateError != null) {
      label = rateError;
    } else if (frame != null) {
      final meanElbow = (frame.leftElbowAngle + frame.rightElbowAngle) / 2;
      if (meanElbow < AppConstants.elbowLockAngleDeg) label = 'bent_elbows';
      else if (depth > 0 && depth < AppConstants.cprMinDepthCm - 0.5) label = 'too_shallow';
      else if (depth > AppConstants.cprMaxDepthCm + 0.5) label = 'too_deep';
    }
    return InferenceResult(
      timestamp: DateTime.now(), topClassIndex: 0,
      topClassLabel: label, topClassConfidence: 0.85,
      allClassScores: {label: 0.85}, currentBpm: bpm,
      estimatedDepthCm: depth,
      elbowAngleMean: frame != null
          ? (frame.leftElbowAngle + frame.rightElbowAngle) / 2 : 0,
      spineVerticalityDeg: frame?.spineVerticality ?? 0, isSimulated: true,
    );
  }

  double _estimateBpm() {
    if (_wristYHistory.length < 10) return 0;
    final samples = _wristYHistory.toList();
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
  final double value;
  _TimedSample(this.timestamp, this.value);
}
