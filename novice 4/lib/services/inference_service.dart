// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// On-device BiLSTM inference via TFLite (iOS/Android only).
// On web, InferenceServiceWeb handles inference via TF.js.
// This file compiles on web via tflite_compat.dart stub.

import 'dart:collection';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

import 'tflite_compat.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/landmark_math.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';

/// On-device BiLSTM inference.
/// Input:  [1, 30, 12] — 30 frames × 12 landmark features
/// Output: [1, 8]      — softmax over 8 error classes
///
/// Gracefully falls back to rule-based classification when:
///   • Model file not found in assets (rule-based fallback)
///   • Running on web (always — use InferenceServiceWeb instead)
class InferenceService {
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  final _log = Logger();

  final _frameBuffer  = ListQueue<List<double>>();
  final _wristHistory = ListQueue<_TimedSample>();

  bool get isModelLoaded => _modelLoaded;

  Future<void> loadModel() async {
    if (kIsWeb) return; // Web uses InferenceServiceWeb
    try {
      _interpreter = await Interpreter.fromAsset(
        AppConstants.tfliteModelPath,
        options: InterpreterOptions()..threads = 2,
      );
      _modelLoaded = true;
      _log.i('InferenceService: model loaded');
    } catch (e) {
      _log.w(
        'InferenceService: model not found at ${AppConstants.tfliteModelPath}. '
        'Running in rule-based fallback mode. '
        'Train with ml_pipeline/ then run convert_to_tflite.py.',
      );
      _modelLoaded = false;
    }
  }

  InferenceResult infer(LandmarkFrame frame) {
    final features = LandmarkMath.buildFeatureVector(
      leftElbowAngle:     frame.leftElbowAngle,
      rightElbowAngle:    frame.rightElbowAngle,
      spineVerticality:   frame.spineVerticality,
      wristY:             frame.wristMidY,
      wristVelocityY:     frame.wristVelocityY,
      wristAccelerationY: frame.wristAccelerationY,
      normalizedDepth: LandmarkMath.normalizedWristDisplacement(
        frame.wristMidY,
        (frame.leftShoulderY + frame.rightShoulderY) / 2,
        (frame.leftHipY + frame.rightHipY) / 2,
      ),
      shoulderWidth:    frame.shoulderWidth,
      meanConfidence:   frame.meanLandmarkConfidence,
      leftElbowVisible:  frame.leftElbowVisibility  > AppConstants.minLandmarkVisibility,
      rightElbowVisible: frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );

    _frameBuffer.addLast(features);
    while (_frameBuffer.length > AppConstants.temporalWindowFrames) {
      _frameBuffer.removeFirst();
    }

    _wristHistory.addLast(_TimedSample(frame.capturedAt, frame.wristMidY));
    while (_wristHistory.length > AppConstants.bpmHistoryLength) {
      _wristHistory.removeFirst();
    }

    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);

    // Rate errors are rule-based (±5 bpm accuracy target from proposal §1.4)
    String? rateError;
    if (bpm > 0) {
      if (bpm < AppConstants.cprMinRateBpm) rateError = 'rate_too_slow';
      if (bpm > AppConstants.cprMaxRateBpm) rateError = 'rate_too_fast';
    }

    if (_modelLoaded && _frameBuffer.length == AppConstants.temporalWindowFrames) {
      return _runModel(frame, bpm, depth, rateError);
    }
    return _ruleBased(frame, bpm, depth, rateError);
  }

  InferenceResult _runModel(
    LandmarkFrame frame, double bpm, double depth, String? rateError,
  ) {
    final inputData = _frameBuffer.map((f) => List<double>.from(f)).toList();
    final input     = [inputData];
    final output    = [List.filled(8, 0.0)];

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      _log.e('InferenceService: run failed — $e');
      return _ruleBased(frame, bpm, depth, rateError);
    }

    final scores  = output[0];
    int topIdx    = 0;
    double topScore = scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > topScore) { topScore = scores[i]; topIdx = i; }
    }

    final allScores = <String, double>{};
    for (int i = 0; i < scores.length; i++) {
      allScores[AppConstants.errorClassLabels[i] ?? 'class_$i'] = scores[i];
    }

    final label = rateError ?? (AppConstants.errorClassLabels[topIdx] ?? 'correct_compression');

    return InferenceResult(
      timestamp: DateTime.now(),
      topClassIndex: topIdx,
      topClassLabel: label,
      topClassConfidence: topScore,
      allClassScores: allScores,
      currentBpm: bpm,
      estimatedDepthCm: depth,
      elbowAngleMean: (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
      spineVerticalityDeg: frame.spineVerticality,
      isSimulated: false,
    );
  }

  InferenceResult _ruleBased(
    LandmarkFrame? frame, double bpm, double depth, String? rateError,
  ) {
    String label = 'correct_compression';
    if (rateError != null) {
      label = rateError;
    } else if (frame != null) {
      final meanElbow = (frame.leftElbowAngle + frame.rightElbowAngle) / 2;
      if (meanElbow < AppConstants.elbowLockAngleDeg) {
        label = 'bent_elbows';
      } else if (depth > 0 && depth < AppConstants.cprMinDepthCm - 0.5) {
        label = 'too_shallow';
      } else if (depth > AppConstants.cprMaxDepthCm + 0.5) {
        label = 'too_deep';
      } else {
        final placement = LandmarkMath.assessHandPlacement(
          frame.wristMidY, frame.leftShoulderY, frame.leftHipY,
        );
        if (placement == HandPlacementResult.tooHigh) label = 'hand_too_high';
        if (placement == HandPlacementResult.tooLow)  label = 'hand_too_low';
      }
    }

    return InferenceResult(
      timestamp: DateTime.now(),
      topClassIndex: 0,
      topClassLabel: label,
      topClassConfidence: 0.85,
      allClassScores: {label: 0.85},
      currentBpm: bpm,
      estimatedDepthCm: depth,
      elbowAngleMean: frame != null
          ? (frame.leftElbowAngle + frame.rightElbowAngle) / 2 : 0,
      spineVerticalityDeg: frame?.spineVerticality ?? 0,
      isSimulated: true,
    );
  }

  // ── BPM via wrist Y-velocity peak detection ──────────────
  // Mirrors InferenceServiceWeb._estimateBpm() and Python evaluate.py
  double _estimateBpm() {
    if (_wristHistory.length < 10) return 0.0;
    final samples    = _wristHistory.toList();
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
    if (peaks.length < 2) return 0.0;
    double totalMs = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalMs += peaks[i].difference(peaks[i - 1]).inMilliseconds.toDouble();
    }
    final meanMs = totalMs / (peaks.length - 1);
    return meanMs <= 0 ? 0.0 : (60000.0 / meanMs).clamp(0.0, 200.0);
  }

  // ── Depth via wrist displacement proxy ──────────────────
  // Calibrated against CPR-Coach dataset. Validate in pilot study (§3.6.2).
  double _estimateDepthCm(LandmarkFrame frame) {
    final normDisp = LandmarkMath.normalizedWristDisplacement(
      frame.wristMidY,
      (frame.leftShoulderY + frame.rightShoulderY) / 2,
      (frame.leftHipY + frame.rightHipY) / 2,
    );
    return (normDisp * 50.0).clamp(0.0, 10.0);
  }

  void dispose() => _interpreter?.close();
}

class _TimedSample {
  final DateTime timestamp;
  final double   value;
  const _TimedSample(this.timestamp, this.value);
}