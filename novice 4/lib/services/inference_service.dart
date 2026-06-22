// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Mobile ML inference — on-device TFLite (INT8 quantized BiLSTM,
// assets/models/novice_cpr_classifier.tflite). 8-class single-label output
// (AppConstants.errorClassLabels), unlike the web path's 3-head API
// (InferenceServiceWeb in platform/inference_service_web.dart), which
// returns independent rate/depth/recoil labels. Both produce InferenceResult
// so session_provider.dart can consume either without a platform check.
//
// rateAccuracy/depthAccuracy/recoilAccuracy/rateLabel/depthLabel/recoilLabel
// are intentionally left null here — this model doesn't classify those
// dimensions independently. session_provider falls back to topClassLabel
// for per-task tallying on mobile (see SessionModel.rateAccuracy docs).

import 'dart:async';
import 'dart:collection';

import '../core/constants/app_constants.dart';
import '../core/utils/landmark_math.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';
import 'tflite_compat.dart';

class InferenceService {
  Interpreter? _interpreter;
  final _frameBuffer = ListQueue<List<double>>();
  final _wristYHistory = ListQueue<_TimedSample>();

  double _shoulderWidthPxSum = 0;
  int _shoulderWidthSamples = 0;
  static const int _depthCalibFrames = 30;

  bool get isModelLoaded => _interpreter != null;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.tfliteModelPath);
      _interpreter!.allocateTensors();
    } catch (e) {
      // Model asset missing or failed to load — infer() falls back to
      // isSimulated=true results so the UI can show a clear "rule-based
      // fallback" state instead of crashing.
      _interpreter = null;
    }
  }

  InferenceResult infer(LandmarkFrame frame) {
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

    final bpm = _estimateBpm();
    final depth = _estimateDepthCm(frame);

    if (_interpreter == null ||
        _frameBuffer.length < AppConstants.temporalWindowFrames) {
      return InferenceResult(
        timestamp: DateTime.now(),
        topClassIndex: 0,
        topClassLabel: 'model_unavailable',
        topClassConfidence: 0.0,
        allClassScores: const {},
        currentBpm: bpm,
        estimatedDepthCm: depth,
        elbowAngleMean: (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
        spineVerticalityDeg: frame.spineVerticality,
        isSimulated: true,
      );
    }

    final input = [_frameBuffer.toList()];
    final output = [List.filled(AppConstants.errorClassLabels.length, 0.0)];

    _interpreter!.run(input, output);

    final scores = output[0];
    int topIndex = 0;
    double topScore = scores.isEmpty ? 0.0 : scores[0];
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > topScore) {
        topScore = scores[i];
        topIndex = i;
      }
    }

    final allScores = <String, double>{
      for (int i = 0; i < scores.length; i++)
        AppConstants.errorClassLabels[i] ?? 'class_$i': scores[i],
    };

    return InferenceResult(
      timestamp: DateTime.now(),
      topClassIndex: topIndex,
      topClassLabel: AppConstants.errorClassLabels[topIndex] ?? 'unknown',
      topClassConfidence: topScore,
      allClassScores: allScores,
      currentBpm: bpm,
      estimatedDepthCm: depth,
      elbowAngleMean: (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
      spineVerticalityDeg: frame.spineVerticality,
      isSimulated: false,
    );
  }

  List<double> _buildFeatures(LandmarkFrame frame) {
    return LandmarkMath.buildFeatureVector(
      leftElbowAngle: frame.leftElbowAngle,
      rightElbowAngle: frame.rightElbowAngle,
      spineVerticality: frame.spineVerticality,
      wristY: frame.wristMidY,
      wristVelocityY: frame.wristVelocityY,
      wristAccelerationY: frame.wristAccelerationY,
      normalizedDepth: LandmarkMath.normalizedWristDisplacement(
        frame.wristMidY, frame.leftShoulderY, frame.leftHipY,
      ),
      shoulderWidth: frame.shoulderWidth,
      meanConfidence: frame.meanLandmarkConfidence,
      leftElbowVisible:
          frame.leftElbowVisibility > AppConstants.minLandmarkVisibility,
      rightElbowVisible:
          frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );
  }

  void _updateDepthCalibration(LandmarkFrame frame) {
    if (frame.shoulderWidth > 0.05) {
      _shoulderWidthPxSum += frame.shoulderWidth;
      _shoulderWidthSamples++;
    }
  }

  double _estimateDepthCm(LandmarkFrame frame) {
    final normDisp = LandmarkMath.normalizedWristDisplacement(
      frame.wristMidY,
      (frame.leftShoulderY + frame.rightShoulderY) / 2,
      (frame.leftHipY + frame.rightHipY) / 2,
    );

    double torsoHeightCm;
    if (_shoulderWidthSamples >= _depthCalibFrames) {
      final meanShoulderWidthNorm = _shoulderWidthPxSum / _shoulderWidthSamples;
      torsoHeightCm = (meanShoulderWidthNorm * AppConstants.normToPhysicalCmScale)
          / AppConstants.shoulderWidthToTorsoRatio;
    } else {
      torsoHeightCm = AppConstants.fallbackTorsoHeightCm;
    }

    return (normDisp * torsoHeightCm).clamp(0.0, 10.0);
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
          velocities[i] > 0.012) {
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

  void dispose() {
    _interpreter?.close();
  }
}

class _TimedSample {
  final DateTime timestamp;
  final double value;
  _TimedSample(this.timestamp, this.value);
}