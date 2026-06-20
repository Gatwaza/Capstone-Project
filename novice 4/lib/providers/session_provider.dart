// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../core/di/injection.dart';
import '../models/session_model.dart';
import '../models/landmark_frame.dart';
import '../services/feedback_engine.dart';
import '../services/inference_service.dart';
import '../services/platform/inference_service_web.dart';
import '../services/platform/storage_service.dart';
import '../services/platform/telemetry_service.dart';
import '../services/tts_service.dart';

class LiveSessionState {
  const LiveSessionState({
    this.isActive = false,
    this.bpm = 0.0,
    this.depthCm = 0.0,
    this.compressions = 0,
    this.elapsedSeconds = 0,
    this.currentPrompt,
    this.lastInference,
    this.lastFrame,
    this.language = 'en',
    this.modelAvailable = false,
    this.taskAccuracies = const {},
    this.taskConfidences = const {},
  });

  final bool isActive;
  final double bpm;
  final double depthCm;
  final int compressions;
  final int elapsedSeconds;
  final FeedbackPrompt? currentPrompt;
  final InferenceResult? lastInference;
  final LandmarkFrame? lastFrame;
  final String language;
  final bool modelAvailable;
  final Map<String, double> taskAccuracies;
  final Map<String, double> taskConfidences;

  String get elapsedFormatted {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ERC 2021: CPR fraction = proportion of time spent compressing.
  double get cprFraction {
    if (elapsedSeconds == 0) return 0;
    return ((compressions * 0.52) / elapsedSeconds).clamp(0.0, 1.0);
  }

  // Live HUD estimate — NOT what gets saved (see _computeQualityScore).
  // Shows 0 until first compression so the HUD never misleads.
  int get qualityScore {
    if (compressions == 0) return 0;
    double score = 100;
    if (bpm > 0 && (bpm < 100 || bpm > 120)) score -= 20;
    if (depthCm > 0 && (depthCm < 4.5 || depthCm > 6.5)) score -= 20;
    if (cprFraction < 0.6) score -= 15;
    return score.clamp(0, 100).toInt();
  }

  LiveSessionState copyWith({
    bool? isActive,
    double? bpm,
    double? depthCm,
    int? compressions,
    int? elapsedSeconds,
    FeedbackPrompt? currentPrompt,
    InferenceResult? lastInference,
    LandmarkFrame? lastFrame,
    String? language,
    bool? modelAvailable,
    Map<String, double>? taskAccuracies,
    Map<String, double>? taskConfidences,
  }) =>
      LiveSessionState(
        isActive: isActive ?? this.isActive,
        bpm: bpm ?? this.bpm,
        depthCm: depthCm ?? this.depthCm,
        compressions: compressions ?? this.compressions,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        currentPrompt: currentPrompt ?? this.currentPrompt,
        lastInference: lastInference ?? this.lastInference,
        lastFrame: lastFrame ?? this.lastFrame,
        language: language ?? this.language,
        modelAvailable: modelAvailable ?? this.modelAvailable,
        taskAccuracies: taskAccuracies ?? this.taskAccuracies,
        taskConfidences: taskConfidences ?? this.taskConfidences,
      );
}

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  LiveSessionNotifier() : super(const LiveSessionState()) {
    _feedback = getIt<FeedbackEngine>();
    _tts = getIt<TtsService>();
    _storage = getIt<StorageService>();
    _telemetry = getIt<TelemetryService>();
    _log = getIt<Logger>();
  }

  late final FeedbackEngine _feedback;
  late final TtsService _tts;
  late final StorageService _storage;
  late final TelemetryService _telemetry;
  late final Logger _log;

  Timer? _ticker;
  final List<double> _bpmHistory = [];
  final List<double> _depthHistory = [];

  // Per-task accuracy tracking (CNN-BiLSTM 3-head evaluation)
  final List<double> _rateAccuracies = [];
  final List<double> _depthAccuracies = [];
  final List<double> _recoilAccuracies = [];
  Map<String, double> _taskConfidences = {
    'rate': 0.0,
    'depth': 0.0,
    'recoil': 0.0,
  };

  // ── Compression state machine ───────────────────────────────────────────────
  _CompressionPhase _compressionPhase = _CompressionPhase.idle;
  static const double _downThreshold = 0.006;
  static const double _upThreshold = -0.004;
  int _descentFrameCount = 0;
  static const int _minDescentFrames = 3;

  // ── Descending-phase frame buffer for inference ─────────────────────────────
  // FIX: Only buffer frames captured during the active downstroke phase.
  // This prevents idle/rest frames from polluting the 60-frame inference
  // window, which was causing the model to see "slow rate" (rest frames
  // look like no compression happening) and "correct depth" (majority class
  // collapse for Depth head is less triggered when input is active motion).
  final List<LandmarkFrame> _descentFrameBuffer = [];
  static const int _inferenceWindowSize = 60;

  // ── Raw frame buffer (all frames, for dataset export) ──────────────────────
  final List<LandmarkFrame> _frameBuffer = [];
  DateTime? _sessionStart;

  // ── Model-derived grading ──────────────────────────────────────────────────
  final Map<String, int> _classFrameCounts = {};
  int _assessedFrameCount = 0;
  bool _modelUsedThisSession = false;

  // Depth confidence threshold — FIX: Reject Depth classifications below this
  // threshold. The Depth head shows majority-class collapse (always "Correct"
  // at ~94% confidence). Below 0.70 we treat the depth result as unreliable
  // and don't accumulate it, preventing artificially inflated depth scores.
  static const double _depthConfidenceThreshold = 0.70;
  // For rate and recoil, a lower threshold is sufficient since they don't
  // exhibit the same collapse pattern.
  static const double _taskConfidenceThreshold = 0.55;

  bool get _modelAvailable {
    try {
      if (kIsWeb) return getIt<InferenceServiceWeb>().isModelLoaded;
      return getIt<InferenceService>().isModelLoaded;
    } catch (_) {
      return false;
    }
  }

  InferenceResult _runInference(LandmarkFrame frame) {
    try {
      if (kIsWeb) return getIt<InferenceServiceWeb>().infer(frame);
      return getIt<InferenceService>().infer(frame);
    } catch (_) {
      return InferenceResult(
        timestamp: DateTime.now(),
        topClassIndex: 0,
        topClassLabel: 'correct_compression',
        topClassConfidence: 0.5,
        allClassScores: const {},
        currentBpm: 0,
        estimatedDepthCm: 0,
        elbowAngleMean: 0,
        spineVerticalityDeg: 0,
        rateAccuracy: null,
        rateConfidence: null,
        depthAccuracy: null,
        depthConfidence: null,
        recoilAccuracy: null,
        recoilConfidence: null,
        isSimulated: true,
      );
    }
  }

  void startSession() {
    _sessionStart = DateTime.now();
    _bpmHistory.clear();
    _depthHistory.clear();
    _frameBuffer.clear();
    _descentFrameBuffer.clear();
    _classFrameCounts.clear();
    _assessedFrameCount = 0;
    _modelUsedThisSession = false;
    _compressionPhase = _CompressionPhase.idle;
    _descentFrameCount = 0;
    _rateAccuracies.clear();
    _depthAccuracies.clear();
    _recoilAccuracies.clear();
    _taskConfidences = {'rate': 0.0, 'depth': 0.0, 'recoil': 0.0};

    _feedback.reset();
    state = state.copyWith(
      isActive: true,
      compressions: 0,
      elapsedSeconds: 0,
      bpm: 0,
      depthCm: 0,
      taskAccuracies: const {},
      taskConfidences: const {},
      modelAvailable: _modelAvailable,
    );
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1),
    );
    _tts.speakKey('start');
    _log.i('Session started');
  }

  Future<String?> stopSession() async {
    _ticker?.cancel();
    if (!state.isActive || _sessionStart == null) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final errorRates = _computeErrorRates();

    final taskAccuracies = {
      'rate': _mean(_rateAccuracies),
      'depth': _mean(_depthAccuracies),
      'recoil': _mean(_recoilAccuracies),
    };

    final session = SessionModel(
      id: id,
      startedAt: _sessionStart!,
      endedAt: DateTime.now(),
      totalCompressions: state.compressions,
      meanBpm: _mean(_bpmHistory),
      meanDepthCm: _mean(_depthHistory),
      cprFraction: state.cprFraction,
      qualityScore: _computeQualityScore(errorRates, taskAccuracies),
      errorRates: errorRates,
      language: state.language,
      taskAccuracies: taskAccuracies,
      taskConfidences: _taskConfidences,
      modelWasAvailable: _modelUsedThisSession,
      rawFrames: List.unmodifiable(_frameBuffer),
    );

    // Save locally and upload to Supabase concurrently — telemetry failure
    // never blocks the user from seeing their results.
    await _storage.saveSession(session);
    _telemetry.uploadSession(session); // fire-and-forget, silent on error

    _log.i(
      'Session saved: $id | compressions=${state.compressions} '
      '| rate=${(_mean(_rateAccuracies) * 100).toStringAsFixed(1)}% '
      '| depth=${(_mean(_depthAccuracies) * 100).toStringAsFixed(1)}% '
      '| recoil=${(_mean(_recoilAccuracies) * 100).toStringAsFixed(1)}%',
    );
    state = state.copyWith(isActive: false);
    return id;
  }

  Map<String, double> _computeErrorRates() {
    if (_assessedFrameCount == 0) return {};
    return _classFrameCounts.map(
      (label, count) => MapEntry(label, count / _assessedFrameCount),
    );
  }

  /// Multi-task quality score, research-backed by CNN-BiLSTM evaluation.
  ///
  /// Formula (evidence: ml_pipeline/CPR_Coach_Training.ipynb cell 35):
  ///   - Each task accuracy normalized against test-set F1_w baseline
  ///   - Weighted by AUC-ROC reliability (Depth most reliable at 95.11%)
  ///   - CPR fraction penalty: −10 if < 60%
  ///   - Confidence bonus: +5 if mean confidence ≥ 80%
  ///
  /// CNN-BiLSTM Test-Set Baselines:
  ///   Rate:   F1_w=75.92%, AUC=81.10%
  ///   Depth:  F1_w=94.05%, AUC=95.11%
  ///   Recoil: F1_w=74.79%, AUC=84.14%
  int _computeQualityScore(
    Map<String, double> errorRates,
    Map<String, double> taskAccuracies,
  ) {
    if (_assessedFrameCount == 0) return 0;

    const double rateF1  = 0.7592;
    const double depthF1 = 0.9405;
    const double recoilF1 = 0.7479;
    const double rateW   = 0.8110;
    const double depthW  = 0.9511;
    const double recoilW = 0.8414;
    final double totalW  = rateW + depthW + recoilW;

    final double rateAcc   = (taskAccuracies['rate']   ?? 0.0).clamp(0.0, 1.0);
    final double depthAcc  = (taskAccuracies['depth']  ?? 0.0).clamp(0.0, 1.0);
    final double recoilAcc = (taskAccuracies['recoil'] ?? 0.0).clamp(0.0, 1.0);

    final double rateScore   = (rateAcc   / rateF1)   * 100;
    final double depthScore  = (depthAcc  / depthF1)  * 100;
    final double recoilScore = (recoilAcc / recoilF1) * 100;

    double weighted = ((rateScore * rateW) + (depthScore * depthW) + (recoilScore * recoilW)) / totalW;

    if (state.cprFraction < 0.6) weighted -= 10.0;

    final double avgConf = ((_taskConfidences['rate']   ?? 0.0) +
                            (_taskConfidences['depth']  ?? 0.0) +
                            (_taskConfidences['recoil'] ?? 0.0)) / 3.0;
    if (avgConf >= 0.80) weighted += 5.0;

    return weighted.clamp(0, 100).round();
  }

  void onFrame(LandmarkFrame frame) {
    // Always buffer for raw dataset export regardless of session state.
    _frameBuffer.add(frame);

    // ── GATE 1: Only process when session is active ─────────────────────────
    if (!state.isActive) return;

    // Run the compression state machine first — it determines phase,
    // which the inference gate below depends on.
    _updateCompressionCount(frame);

    // ── GATE 2: Metrics accumulate only after first confirmed compression ───
    // Before compressions > 0, all scores/bpm/depth display as zero.
    // This is the "zero before start" fix.
    final bool hasStartedCompressing = state.compressions > 0;

    // ── GATE 3: Buffer descending-phase frames for inference only ───────────
    // FIX: Only accumulate frames into the inference buffer during an active
    // downstroke. This prevents idle rest-phase frames from making the model
    // see "no motion" = "too slow rate" and triggering the Depth majority-class
    // collapse (Depth head classifies rest frames as "Correct depth" trivially).
    if (_compressionPhase == _CompressionPhase.descending) {
      _descentFrameBuffer.add(frame);
      // Keep buffer bounded — slide the window, preserving the most recent frames.
      if (_descentFrameBuffer.length > _inferenceWindowSize) {
        _descentFrameBuffer.removeAt(0);
      }
    }

    // Only run inference and accumulate once we have enough active frames
    // AND the first compression has confirmed the user has started.
    if (!hasStartedCompressing) return;
    if (_descentFrameBuffer.length < 10) return; // need a minimum active window

    final result = _runInference(frame);

    // Accumulate per-task accuracy with confidence thresholds.
    // FIX: Reject Depth classifications below _depthConfidenceThreshold to
    // guard against majority-class collapse inflating depth scores.
    _assessedFrameCount++;
    _classFrameCounts.update(
      result.topClassLabel,
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    if (!result.isSimulated) _modelUsedThisSession = true;

    if (result.rateAccuracy != null &&
        (result.rateConfidence ?? 0.0) >= _taskConfidenceThreshold) {
      _rateAccuracies.add(result.rateAccuracy!);
      _taskConfidences['rate'] = result.rateConfidence!;
    }

    // Depth: stricter threshold guards against majority-class collapse.
    if (result.depthAccuracy != null &&
        (result.depthConfidence ?? 0.0) >= _depthConfidenceThreshold) {
      _depthAccuracies.add(result.depthAccuracy!);
      _taskConfidences['depth'] = result.depthConfidence!;
    }

    if (result.recoilAccuracy != null &&
        (result.recoilConfidence ?? 0.0) >= _taskConfidenceThreshold) {
      _recoilAccuracies.add(result.recoilAccuracy!);
      _taskConfidences['recoil'] = result.recoilConfidence!;
    }

    if (result.currentBpm > 0) _bpmHistory.add(result.currentBpm);
    if (result.estimatedDepthCm > 0) _depthHistory.add(result.estimatedDepthCm);

    // FeedbackEngine now stays silent when technique is correct (see
    // feedback_engine.dart — FeedbackSeverity.good never triggers speech).
    final prompt = _feedback.process(result, state.language);
    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);

    final liveTaskAccuracies = {
      'rate':   _mean(_rateAccuracies),
      'depth':  _mean(_depthAccuracies),
      'recoil': _mean(_recoilAccuracies),
    };

    state = state.copyWith(
      bpm: result.currentBpm,
      depthCm: result.estimatedDepthCm,
      currentPrompt: prompt,
      lastInference: result,
      lastFrame: frame,
      taskAccuracies: liveTaskAccuracies,
      taskConfidences: Map.of(_taskConfidences),
    );
  }

  /// Counts one compression per downstroke→upstroke transition.
  void _updateCompressionCount(LandmarkFrame frame) {
    final vel = frame.wristVelocityY;

    switch (_compressionPhase) {
      case _CompressionPhase.idle:
        if (vel > _downThreshold) {
          _compressionPhase = _CompressionPhase.descending;
          _descentFrameCount = 1;
        }
        break;

      case _CompressionPhase.descending:
        if (vel > _downThreshold) {
          _descentFrameCount++;
        } else if (vel < _upThreshold && _descentFrameCount >= _minDescentFrames) {
          _compressionPhase = _CompressionPhase.ascending;
          state = state.copyWith(compressions: state.compressions + 1);
          _descentFrameCount = 0;
        } else if (vel.abs() < _downThreshold * 0.5) {
          _compressionPhase = _CompressionPhase.idle;
          _descentFrameCount = 0;
        }
        break;

      case _CompressionPhase.ascending:
        if (vel > _downThreshold) {
          _compressionPhase = _CompressionPhase.descending;
          _descentFrameCount = 1;
        } else if (vel.abs() < _downThreshold) {
          _compressionPhase = _CompressionPhase.idle;
        }
        break;
    }
  }

  void setLanguage(String lang) {
    _tts.setLanguage(lang);
    state = state.copyWith(language: lang);
  }

  double _mean(List<double> vals) =>
      vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

enum _CompressionPhase { idle, descending, ascending }

final liveSessionProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>(
  (_) => LiveSessionNotifier(),
);

final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) async {
  return getIt<StorageService>().loadAllSessions();
});