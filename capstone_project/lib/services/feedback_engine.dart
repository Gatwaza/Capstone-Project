import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/session_model.dart';
import '../core/utils/landmark_math.dart';
import 'tts_service.dart';
import 'inference_service.dart';

class EngineMetrics {
  final double? bpm;
  final double accuracy;
  final int frameCount;
  final int totalCompressions;
  final String? currentLabel;
  final String? currentFeedbackKey;

  const EngineMetrics({
    this.bpm,
    required this.accuracy,
    required this.frameCount,
    required this.totalCompressions,
    this.currentLabel,
    this.currentFeedbackKey,
  });
}

class FeedbackEngine {
  final TtsService _tts;
  final InferenceService _inference;
  final void Function(EngineMetrics) onMetricsUpdate;
  final void Function(FeedbackEvent) onFeedbackEvent;

  bool _active = false;
  int _frameCount = 0;
  int _correctFrames = 0;
  int _consecutiveCorrect = 0;
  int _totalCompressions = 0;

  // BPM detection
  final List<double> _wristYBuffer = [];
  double? _currentBpm;
  final List<double> _bpmHistory = [];

  // Calibration
  double? _baselineWristY;
  double? _refShoulderWidth;
  bool _calibrated = false;

  // Feature state
  double _prevWristY = 0.0;
  double _prevVelY = 0.0;

  // Majority vote smoothing
  final List<String> _recentLabels = [];
  String? _smoothedLabel;

  FeedbackEngine({
    required TtsService tts,
    required InferenceService inference,
    required this.onMetricsUpdate,
    required this.onFeedbackEvent,
  })  : _tts = tts,
        _inference = inference;

  void startSession() {
    _active = true;
    _frameCount = 0;
    _correctFrames = 0;
    _consecutiveCorrect = 0;
    _totalCompressions = 0;
    _wristYBuffer.clear();
    _recentLabels.clear();
    _bpmHistory.clear();
    _currentBpm = null;
    _calibrated = false;
    _prevWristY = 0.0;
    _prevVelY = 0.0;
    _inference.reset();
    _tts.enqueue(AppConstants.promptStart, AppConstants.priorityCritical);
    debugPrint('[FeedbackEngine] Session started');
  }

  void stopSession() {
    _active = false;
    _tts.stop();
  }

  void processFrame({
    required Map features, // from LandmarkMath
    required double? wristY,
    required double? spineAngle,
    required List<double>? featureVector,
    required bool hasSufficientLandmarks,
  }) {
    if (!_active) return;
    _frameCount++;

    if (!hasSufficientLandmarks) {
      if (_frameCount % 30 == 0) { // Don't spam this
        _tts.enqueue(AppConstants.promptCameraAdjust, AppConstants.priorityUrgent);
      }
      _emitMetrics();
      return;
    }

    // Phase 1: Calibration (first N frames)
    if (!_calibrated) {
      if (wristY != null && _baselineWristY == null) {
        _baselineWristY = wristY;
        _refShoulderWidth = features['shoulderWidth'] as double? ?? 0.3;
      }
      if (_frameCount >= AppConstants.baselineCalibrationFrames) {
        _calibrated = true;
      }
      _emitMetrics();
      return;
    }

    // BPM from wrist Y peak detection
    if (wristY != null) {
      _wristYBuffer.add(wristY);
      if (_wristYBuffer.length > 300) _wristYBuffer.removeAt(0);
      final bpm = LandmarkMath.estimateBpm(
        _wristYBuffer,
        minDistance: AppConstants.peakMinDistanceFrames,
      );
      if (bpm != null) {
        _bpmHistory.add(bpm);
        if (_bpmHistory.length > 10) _bpmHistory.removeAt(0);
        _currentBpm = _bpmHistory.reduce((a, b) => a + b) / _bpmHistory.length;
      }
    }

    // ML inference (if model loaded)
    ClassifierResult? prediction;
    if (featureVector != null && _inference.modelLoaded) {
      prediction = _inference.processFrame(featureVector);
    }

    // Smooth classifier output over 5 frames
    if (prediction != null) {
      _recentLabels.add(prediction.label);
      if (_recentLabels.length > 5) _recentLabels.removeAt(0);
      _smoothedLabel = _majorityVote(_recentLabels);
    }

    // Count compressions from velocity direction change
    final velY = wristY != null ? wristY - _prevWristY : 0.0;
    if (_prevVelY < -0.005 && velY >= 0) {
      _totalCompressions++; // downstroke → upstroke transition
    }
    _prevWristY = wristY ?? _prevWristY;
    _prevVelY = velY;

    // Track correct frames
    if (_smoothedLabel == 'correct_compression') {
      _correctFrames++;
      _consecutiveCorrect++;
      if (_consecutiveCorrect == AppConstants.encourageEveryNFrames) {
        _tts.enqueue(AppConstants.promptKeepGoing, AppConstants.priorityEncouragement);
        _consecutiveCorrect = 0;
      }
    } else {
      _consecutiveCorrect = 0;
    }

    // Priority rule evaluation
    _evaluateRules(spineAngle);
    _emitMetrics();
  }

  void _evaluateRules(double? spineAngle) {
    // P1 — hand placement (highest priority)
    if (_smoothedLabel == 'wrong_hand_high') {
      _issueAndLog(AppConstants.promptHandHigh, AppConstants.priorityCritical);
      return;
    }
    if (_smoothedLabel == 'wrong_hand_low') {
      _issueAndLog(AppConstants.promptHandLow, AppConstants.priorityCritical);
      return;
    }

    // P2 — body mechanics
    if (_smoothedLabel == 'bent_elbows') {
      _issueAndLog(AppConstants.promptElbowsBent, AppConstants.priorityUrgent);
      return;
    }
    if (spineAngle != null && spineAngle > 30) {
      _issueAndLog(AppConstants.promptBodyLean, AppConstants.priorityUrgent);
      return;
    }

    // P3 — depth + rate (coaching level)
    if (_smoothedLabel == 'too_shallow') {
      _issueAndLog(AppConstants.promptTooShallow, AppConstants.priorityCoaching);
    }
    if (_currentBpm != null) {
      if (_currentBpm! < AppConstants.cprBpmMin) {
        _issueAndLog(AppConstants.promptRateSlow, AppConstants.priorityCoaching);
      } else if (_currentBpm! > AppConstants.cprBpmMax) {
        _issueAndLog(AppConstants.promptRateFast, AppConstants.priorityCoaching);
      } else if (_frameCount % 60 == 0) {
        _issueAndLog(AppConstants.promptGreatRate, AppConstants.priorityEncouragement);
      }
    }
  }

  void _issueAndLog(String key, int priority) {
    _tts.enqueue(key, priority);
    onFeedbackEvent(FeedbackEvent(
      frameIndex: _frameCount,
      promptKey: key,
      priority: priority,
      bpmAtEvent: _currentBpm,
      label: _smoothedLabel ?? 'unknown',
    ));
  }

  void _emitMetrics() {
    final accuracy = _frameCount > AppConstants.baselineCalibrationFrames
        ? _correctFrames / (_frameCount - AppConstants.baselineCalibrationFrames)
        : 0.0;
    onMetricsUpdate(EngineMetrics(
      bpm: _currentBpm,
      accuracy: accuracy.clamp(0.0, 1.0),
      frameCount: _frameCount,
      totalCompressions: _totalCompressions,
      currentLabel: _smoothedLabel,
      currentFeedbackKey: null,
    ));
  }

  String? _majorityVote(List<String> labels) {
    if (labels.isEmpty) return null;
    final counts = <String, int>{};
    for (final l in labels) counts[l] = (counts[l] ?? 0) + 1;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  CprSession buildSession({required String id, required String lang, required int duration}) {
    final accuracy = _frameCount > 0
        ? _correctFrames / _frameCount.toDouble()
        : 0.0;
    final avgBpm = _bpmHistory.isNotEmpty
        ? _bpmHistory.reduce((a, b) => a + b) / _bpmHistory.length
        : null;

    // Rate adherence: how many BPM readings were in target range
    final rateScore = avgBpm != null
        ? (avgBpm >= AppConstants.cprBpmMin && avgBpm <= AppConstants.cprBpmMax
            ? 1.0
            : 1.0 - ((avgBpm - 110).abs() / 30).clamp(0.0, 1.0))
        : 0.5;

    return CprSession(
      id: id,
      startedAt: DateTime.now().subtract(Duration(seconds: duration)),
      endedAt: DateTime.now(),
      durationSeconds: duration,
      avgBpm: avgBpm,
      rateAdherenceScore: rateScore,
      postureScore: accuracy,
      overallScore: (accuracy * 0.6 + rateScore * 0.4),
      totalCompressions: _totalCompressions,
      language: lang,
      events: [],
    );
  }

  double? get currentBpm => _currentBpm;
  bool get isActive => _active;
}
