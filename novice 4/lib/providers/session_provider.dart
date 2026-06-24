// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Riverpod providers for the live training session and saved-session
// history. This is the single source of truth that training_screen,
// home_screen, history_screen, and settings_screen all read from.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/injection.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';
import '../services/feedback_engine.dart';
import '../services/inference_service.dart';
import '../services/platform/inference_service_web.dart';
import '../services/platform/storage_service.dart';
import '../services/platform/telemetry_service.dart'; // FIX: import added
import '../services/tts_service.dart';

/// Immutable snapshot of an in-progress (or not-yet-started) training
/// session. Consumed directly by TrainingScreen's HUD and by
/// settings_screen for the language toggle.
class LiveSessionState {
  const LiveSessionState({
    this.isActive = false,
    this.participantId,
    this.compressions = 0,
    this.bpm = 0,
    this.depthCm = 0,
    this.cprFraction = 0,
    this.language = 'en',
    this.modelAvailable = false,
    this.currentPrompt,
    this.lastInference,
    this.lastFrame,
    this.taskAccuracies = const {},
    this.elapsed = Duration.zero,
  });

  final bool isActive;
  final String? participantId;
  final int compressions;
  final double bpm;
  final double depthCm;
  final double cprFraction;
  final String language;
  final bool modelAvailable;
  final FeedbackPrompt? currentPrompt;
  final InferenceResult? lastInference;
  final LandmarkFrame? lastFrame;

  /// Live per-task accuracy snapshot ('rate'/'depth'/'recoil' → 0.0–1.0),
  /// updated every assessed frame so _TaskIndicators in training_screen can
  /// show a running readout during the session.
  final Map<String, double> taskAccuracies;

  final Duration elapsed;

  String get elapsedFormatted {
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  LiveSessionState copyWith({
    bool? isActive,
    String? participantId,
    int? compressions,
    double? bpm,
    double? depthCm,
    double? cprFraction,
    String? language,
    bool? modelAvailable,
    FeedbackPrompt? currentPrompt,
    InferenceResult? lastInference,
    LandmarkFrame? lastFrame,
    Map<String, double>? taskAccuracies,
    Duration? elapsed,
  }) {
    return LiveSessionState(
      isActive: isActive ?? this.isActive,
      participantId: participantId ?? this.participantId,
      compressions: compressions ?? this.compressions,
      bpm: bpm ?? this.bpm,
      depthCm: depthCm ?? this.depthCm,
      cprFraction: cprFraction ?? this.cprFraction,
      language: language ?? this.language,
      modelAvailable: modelAvailable ?? this.modelAvailable,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      lastInference: lastInference ?? this.lastInference,
      lastFrame: lastFrame ?? this.lastFrame,
      taskAccuracies: taskAccuracies ?? this.taskAccuracies,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  LiveSessionNotifier() : super(const LiveSessionState()) {
    _feedback = FeedbackEngine();
    _tts = getIt<TtsService>();
    _storage = getIt<StorageService>();
    _telemetry = getIt<TelemetryService>(); // FIX: wire in TelemetryService
  }

  late final FeedbackEngine _feedback;
  late final TtsService _tts;
  late final StorageService _storage;
  late final TelemetryService _telemetry; // FIX: field added

  DateTime? _sessionStart;
  Timer? _ticker;

  final List<double> _bpmHistory = [];
  final List<double> _depthHistory = [];
  final List<LandmarkFrame> _frameBuffer = [];

  int _assessedFrameCount = 0;
  int _activeFrameCount = 0;

  // Per-task accuracy histories, used both for the live taskAccuracies
  // readout and for the final SessionModel research metrics at stopSession.
  final List<double> _rateAccuracies = [];
  final List<double> _depthAccuracies = [];
  final List<double> _recoilAccuracies = [];
  final Map<String, double> _taskConfidences = {
    'rate': 0.0,
    'depth': 0.0,
    'recoil': 0.0,
  };

  // Simple compression counter: a "compression" is counted on each downward
  // → upward direction change of wristVelocityY (i.e. each completed press
  // cycle).
  //
  // FIX: the original 0.002 threshold was within the noise floor of
  // MediaPipe landmark jitter — small frame-to-frame tracking wobble was
  // enough to flip descending/ascending state even with hands completely
  // still, producing physically impossible counts (200+ bpm, 170+
  // compressions in 38s). Two changes:
  //   1. Threshold raised to 0.012 — well above jitter, comfortably below
  //      real compression velocity (~0.03-0.08 normalized units/frame at
  //      25fps for a 5-6cm press).
  //   2. Minimum 300ms between counted compressions (hard caps the counter
  //      at 200bpm even in pathological noise — real CPR tops out ~120bpm
  //      per ERC guidelines, so this is a generous physical ceiling, not a
  //      tight clamp).
  double? _lastVelocityY;
  bool _wasDescending = false;
  DateTime? _lastCompressionAt;
  static const double _compressionVelocityThreshold = 0.012;
  static const Duration _minCompressionInterval = Duration(milliseconds: 300);

  void startSession(String participantId) {
    _sessionStart = DateTime.now();
    _frameBuffer.clear();
    _bpmHistory.clear();
    _depthHistory.clear();
    _rateAccuracies.clear();
    _depthAccuracies.clear();
    _recoilAccuracies.clear();
    _taskConfidences['rate'] = 0.0;
    _taskConfidences['depth'] = 0.0;
    _taskConfidences['recoil'] = 0.0;
    _assessedFrameCount = 0;
    _activeFrameCount = 0;
    _lastVelocityY = null;
    _wasDescending = false;
    _lastCompressionAt = null;
    _feedback.reset();

    state = state.copyWith(
      isActive: true,
      participantId: participantId,
      compressions: 0,
      bpm: 0,
      depthCm: 0,
      cprFraction: 0,
      currentPrompt: null,
      taskAccuracies: const {},
      elapsed: Duration.zero,
    );

    _tts.speakKey('start');

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStart == null) return;
      state = state.copyWith(
        elapsed: DateTime.now().difference(_sessionStart!),
      );
    });
  }

  void setLanguage(String lang) {
    _tts.setLanguage(lang);
    state = state.copyWith(language: lang);
  }

  /// Called once per assessed pose frame from the camera/web pose loop.
  void onFrame(LandmarkFrame frame) {
    if (!state.isActive) return;

    _frameBuffer.add(frame);

    final inference = _runInference(frame);
    final prompt = _feedback.process(inference, state.language);

    _assessedFrameCount++;
    if (!inference.isSimulated) _activeFrameCount++;

    if (inference.rateAccuracy != null) {
      _rateAccuracies.add(inference.rateAccuracy!);
      _taskConfidences['rate'] = inference.rateConfidence ?? 0.0;
    }
    if (inference.depthAccuracy != null) {
      _depthAccuracies.add(inference.depthAccuracy!);
      _taskConfidences['depth'] = inference.depthConfidence ?? 0.0;
    }
    if (inference.recoilAccuracy != null) {
      _recoilAccuracies.add(inference.recoilAccuracy!);
      _taskConfidences['recoil'] = inference.recoilConfidence ?? 0.0;
    }

    if (inference.currentBpm > 0) _bpmHistory.add(inference.currentBpm);
    if (inference.estimatedDepthCm > 0) {
      _depthHistory.add(inference.estimatedDepthCm);
    }

    _updateCompressionCount(frame);

    final liveTaskAccuracies = {
      'rate': _mean(_rateAccuracies),
      'depth': _mean(_depthAccuracies),
      'recoil': _mean(_recoilAccuracies),
    };

    state = state.copyWith(
      bpm: inference.currentBpm,
      depthCm: inference.estimatedDepthCm,
      cprFraction:
          _assessedFrameCount == 0 ? 0 : _activeFrameCount / _assessedFrameCount,
      currentPrompt: prompt,
      lastInference: inference,
      lastFrame: frame,
      modelAvailable: !inference.isSimulated,
      taskAccuracies: liveTaskAccuracies,
    );

    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);
  }

  /// Routes to the platform-appropriate inference backend. injection.dart
  /// registers exactly one of these depending on kIsWeb — InferenceService
  /// (mobile, on-device TFLite) or InferenceServiceWeb (web, hosted
  /// TCN API) — never both, so the kIsWeb check here must match.
  InferenceResult _runInference(LandmarkFrame frame) {
    if (kIsWeb) {
      return getIt<InferenceServiceWeb>().infer(frame);
    }
    return getIt<InferenceService>().infer(frame);
  }

  void _updateCompressionCount(LandmarkFrame frame) {
    final v = frame.wristVelocityY;
    if (_lastVelocityY == null) {
      _lastVelocityY = v;
      return;
    }

    final descending = v > _compressionVelocityThreshold;
    final ascending = v < -_compressionVelocityThreshold;

    if (descending) {
      _wasDescending = true;
    } else if (ascending && _wasDescending) {
      final now = DateTime.now();
      final sinceLast = _lastCompressionAt == null
          ? _minCompressionInterval
          : now.difference(_lastCompressionAt!);
      if (sinceLast >= _minCompressionInterval) {
        // Completed a down-then-up cycle, not too soon after the last one
        // — count one compression.
        state = state.copyWith(compressions: state.compressions + 1);
        _lastCompressionAt = now;
      }
      _wasDescending = false;
    }

    _lastVelocityY = v;
  }

  Future<String?> stopSession() async {
    _ticker?.cancel();
    if (!state.isActive || _sessionStart == null) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final participantId = state.participantId ?? 'unknown';

    final rateAcc = _mean(_rateAccuracies);
    final depthAcc = _mean(_depthAccuracies);
    final recoilAcc = _mean(_recoilAccuracies);

    final session = SessionModel(
      id: id,
      participantId: participantId,
      startedAt: _sessionStart!,
      endedAt: DateTime.now(),
      totalCompressions: state.compressions,
      meanBpm: _mean(_bpmHistory),
      meanDepthCm: _mean(_depthHistory),
      cprFraction: state.cprFraction,
      qualityScore: _computeQualityScore(rateAcc, depthAcc, recoilAcc),
      errorRates: const {},
      rateAccuracy: rateAcc,
      depthAccuracy: depthAcc,
      recoilAccuracy: recoilAcc,
      taskConfidences: Map.of(_taskConfidences),
      language: state.language,
      modelWasAvailable: state.modelAvailable,
      rawFrames: List.unmodifiable(_frameBuffer),
    );

    // Save locally (SharedPreferences on web, SQLite on mobile)
    await _storage.saveSession(session);

    // FIX: Upload to Supabase. Fire-and-forget — TelemetryService has its
    // own 10s timeout and silent error handling, so we never await this.
    // A network failure here must not block navigation to the results screen.
    unawaited(_telemetry.uploadSession(session));

    state = state.copyWith(isActive: false);
    return id;
  }

  /// Weighted multi-task quality score (0–100).
  ///
  /// Evidence sources: ml_pipeline/CPR_Coach_Training.ipynb, sliding-window
  /// retrain (Stage 9 evaluate(), TCN selected as deploy model — outperformed
  /// CNN_BiLSTM on every task/metric this run):
  ///   TCN test-set F1_w:    rate=91.7%, depth=98.3%, recoil=88.5%
  ///   TCN test-set AUC-ROC: rate=98.3%, depth=99.3%, recoil=95.9%
  /// Depth is weighted highest (AUC≈99%) since it's the most reliable task.
  int _computeQualityScore(double rateAcc, double depthAcc, double recoilAcc) {
    if (_assessedFrameCount == 0) return 0;

    // Confirmed from sliding-window retrain (ml_pipeline/CPR_Coach_Training.ipynb,
    // Stage 9 evaluate()) — TCN selected as deploy model in place of
    // CNN_BiLSTM (won on every task/metric: rate/depth/recoil F1_w and AUC).
    // Was rate=81.4/depth=94.0/recoil=74.4 F1 and 0.7923/0.9466/0.8172 AUC
    // weights from the pre-sliding-window CNN_BiLSTM run.
    const rateF1Baseline = 91.7;
    const depthF1Baseline = 98.3;
    const recoilF1Baseline = 88.5;

    const rateWeight = 0.983;
    const depthWeight = 0.993;
    const recoilWeight = 0.959;
    const totalWeight = rateWeight + depthWeight + recoilWeight;

    final rateScore = (rateAcc * 100 / rateF1Baseline).clamp(0, 2) * 100;
    final depthScore = (depthAcc * 100 / depthF1Baseline).clamp(0, 2) * 100;
    final recoilScore = (recoilAcc * 100 / recoilF1Baseline).clamp(0, 2) * 100;

    double weightedScore = ((rateScore * rateWeight) +
            (depthScore * depthWeight) +
            (recoilScore * recoilWeight)) /
        totalWeight;

    if (state.cprFraction < 0.6) weightedScore -= 10.0;

    final avgConfidence = (_taskConfidences['rate']! +
            _taskConfidences['depth']! +
            _taskConfidences['recoil']!) /
        3.0;
    if (avgConfidence >= 0.80) weightedScore += 5.0;

    return weightedScore.clamp(0, 100).round();
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final liveSessionProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>(
  (ref) => LiveSessionNotifier(),
);

/// Saved-session history, read by home_screen (latest session preview) and
/// history_screen (full list). Backed by StorageService, which delegates to
/// SQLite on mobile and SharedPreferences on web.
final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) {
  return getIt<StorageService>().loadAllSessions();
});