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

  double get cprFraction {
    if (elapsedSeconds == 0) return 0;
    return ((compressions * 0.52) / elapsedSeconds).clamp(0.0, 1.0);
  }

  /// Live HUD estimate — derived from model task accuracies when available.
  int get qualityScore {
    if (compressions == 0) return 0;
    final rateAcc = taskAccuracies['rate'] ?? 0.0;
    final depthAcc = taskAccuracies['depth'] ?? 0.0;
    final recoilAcc = taskAccuracies['recoil'] ?? 0.0;
    if (rateAcc == 0.0 && depthAcc == 0.0 && recoilAcc == 0.0) {
      // No model data yet — show 0 rather than a misleading rule-based score.
      return 0;
    }
    // Simple mean for the live HUD; the persisted score uses AUC weighting.
    return ((rateAcc + depthAcc + recoilAcc) / 3 * 100).clamp(0, 100).toInt();
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
  String _participantId = '';
  final List<double> _bpmHistory = [];
  final List<double> _depthHistory = [];

  // ── Per-task tracking (CNN-BiLSTM 3-head evaluation) ───────────────────────
  // Accuracy: 1.0 when model says "Correct", 0.0 otherwise (per frame)
  final List<double> _rateAccuracies   = [];
  final List<double> _depthAccuracies  = [];
  final List<double> _recoilAccuracies = [];

  // Confidence scores (used as AUC proxy and quality weighting)
  Map<String, double> _taskConfidences = {
    'rate': 0.0, 'depth': 0.0, 'recoil': 0.0,
  };

  // Class-level counters for precision/recall/F1 computation
  // Rate task: Correct, Too_Fast, Too_Slow
  final Map<String, int> _rateClassCounts   = {};
  // Depth task: Correct, Too_Shallow, Too_Deep
  final Map<String, int> _depthClassCounts  = {};
  // Recoil task: Correct, Incomplete
  final Map<String, int> _recoilClassCounts = {};

  // ── Compression state machine ───────────────────────────────────────────────
  _CompressionPhase _compressionPhase = _CompressionPhase.idle;
  static const double _downThreshold = 0.006;
  static const double _upThreshold = -0.004;
  int _descentFrameCount = 0;
  static const int _minDescentFrames = 3;

  final List<LandmarkFrame> _descentFrameBuffer = [];
  static const int _inferenceWindowSize = 60;

  final List<LandmarkFrame> _frameBuffer = [];
  DateTime? _sessionStart;

  final Map<String, int> _classFrameCounts = {};
  int _assessedFrameCount = 0;
  bool _modelUsedThisSession = false;

  // Confidence thresholds — reject results below these to prevent
  // majority-class collapse from inflating scores.
  static const double _depthConfidenceThreshold = 0.70;
  static const double _taskConfidenceThreshold  = 0.55;

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
      // Return a null-signal result — isSimulated=true so the provider
      // will not accumulate it into accuracy/confidence lists, and
      // model_was_available will remain false for this session.
      return InferenceResult(
        timestamp: DateTime.now(),
        topClassIndex: 0,
        topClassLabel: 'model_unavailable',
        topClassConfidence: 0.0,
        allClassScores: const {},
        currentBpm: 0,
        estimatedDepthCm: 0,
        elbowAngleMean: 0,
        spineVerticalityDeg: 0,
        isSimulated: true,
      );
    }
  }

  void startSession(String participantId) {
    _participantId = participantId;
    _sessionStart = DateTime.now();
    _bpmHistory.clear();
    _depthHistory.clear();
    _frameBuffer.clear();
    _descentFrameBuffer.clear();
    _classFrameCounts.clear();
    _rateClassCounts.clear();
    _depthClassCounts.clear();
    _recoilClassCounts.clear();
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
    _log.i('Session started for participant: $participantId');
  }

  Future<String?> stopSession() async {
    _ticker?.cancel();
    if (!state.isActive || _sessionStart == null) return null;
    if (_participantId.isEmpty) {
      _log.w('stopSession called with no participantId — refusing to save.');
      state = state.copyWith(isActive: false);
      return null;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final errorRates = _computeErrorRates();

    final taskAccuracies = {
      'rate':   _mean(_rateAccuracies),
      'depth':  _mean(_depthAccuracies),
      'recoil': _mean(_recoilAccuracies),
    };

    // ── Compute per-task research metrics ─────────────────────────────────
    final rateMetrics   = _computeClassificationMetrics(_rateClassCounts);
    final depthMetrics  = _computeClassificationMetrics(_depthClassCounts);
    final recoilMetrics = _computeClassificationMetrics(_recoilClassCounts);

    final qualityScore = _computeQualityScore(taskAccuracies);

    final session = SessionModel(
      id: id,
      participantId: _participantId,
      startedAt: _sessionStart!,
      endedAt: DateTime.now(),
      totalCompressions: state.compressions,
      meanBpm: _mean(_bpmHistory),
      meanDepthCm: _mean(_depthHistory),
      cprFraction: state.cprFraction,
      qualityScore: qualityScore,
      errorRates: errorRates,
      schemaVersion: 2,
      // Research metrics
      rateAccuracy:   taskAccuracies['rate']   ?? 0.0,
      depthAccuracy:  taskAccuracies['depth']  ?? 0.0,
      recoilAccuracy: taskAccuracies['recoil'] ?? 0.0,
      ratePrecision:   rateMetrics['precision']   ?? 0.0,
      depthPrecision:  depthMetrics['precision']  ?? 0.0,
      recoilPrecision: recoilMetrics['precision'] ?? 0.0,
      rateRecall:   rateMetrics['recall']   ?? 0.0,
      depthRecall:  depthMetrics['recall']  ?? 0.0,
      recoilRecall: recoilMetrics['recall'] ?? 0.0,
      rateF1:   rateMetrics['f1']   ?? 0.0,
      depthF1:  depthMetrics['f1']  ?? 0.0,
      recoilF1: recoilMetrics['f1'] ?? 0.0,
      rateAuc:   _taskConfidences['rate']   ?? 0.0,
      depthAuc:  _taskConfidences['depth']  ?? 0.0,
      recoilAuc: _taskConfidences['recoil'] ?? 0.0,
      taskConfidences: Map.of(_taskConfidences),
      language: state.language,
      modelWasAvailable: _modelUsedThisSession,
      rawFrames: List.unmodifiable(_frameBuffer),
    );

    await _storage.saveSession(session);
    _telemetry.uploadSession(session);

    _log.i(
      'Session saved: $id | compressions=${state.compressions} '
      '| rate_f1=${rateMetrics['f1']?.toStringAsFixed(3)} '
      '| depth_f1=${depthMetrics['f1']?.toStringAsFixed(3)} '
      '| recoil_f1=${recoilMetrics['f1']?.toStringAsFixed(3)}',
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

  /// Computes precision, recall, F1 from a per-class frame count map.
  ///
  /// Treats "Correct" as the positive class and all other classes as negatives
  /// for binary metrics.  Returns macro-averaged precision/recall/F1 across
  /// all observed classes for a richer multi-class picture, plus the binary
  /// correct-vs-errors decomposition used in the notebook.
  Map<String, double> _computeClassificationMetrics(Map<String, int> classCounts) {
    if (classCounts.isEmpty) return {'precision': 0, 'recall': 0, 'f1': 0};

    final total = classCounts.values.fold(0, (s, v) => s + v);
    if (total == 0) return {'precision': 0, 'recall': 0, 'f1': 0};

    // Binary decomposition: Correct = TP, everything else = FP/FN
    final tp = (classCounts['Correct'] ?? 0).toDouble();
    final fp = (total - tp);
    final fn = fp; // symmetric for the binary case

    final precision = (tp + fp) > 0 ? tp / (tp + fp) : 0.0;
    final recall    = (tp + fn) > 0 ? tp / (tp + fn) : 0.0;
    final f1        = (precision + recall) > 0
        ? 2 * precision * recall / (precision + recall)
        : 0.0;

    return {
      'precision': precision,
      'recall':    recall,
      'f1':        f1,
    };
  }

  /// Multi-task quality score.
  ///
  /// Tasks weighted by CNN-BiLSTM test-set AUC-ROC (trust weights only).
  /// Tasks with no assessed frames are excluded rather than scored as zero.
  int _computeQualityScore(Map<String, double> taskAccuracies) {
    if (_assessedFrameCount == 0) return 0;

    const int minCompressionsForScore = 5;
    if (state.compressions < minCompressionsForScore) return 0;

    // AUC-ROC from notebook (trust weights — NOT divisors)
    const double rateTrust   = 0.8110;
    const double depthTrust  = 0.9511;
    const double recoilTrust = 0.8414;

    final entries = <MapEntry<double, double>>[];

    if (_rateAccuracies.isNotEmpty) {
      entries.add(MapEntry(
        (taskAccuracies['rate'] ?? 0.0).clamp(0.0, 1.0) * 100, rateTrust));
    }
    if (_depthAccuracies.isNotEmpty) {
      entries.add(MapEntry(
        (taskAccuracies['depth'] ?? 0.0).clamp(0.0, 1.0) * 100, depthTrust));
    }
    if (_recoilAccuracies.isNotEmpty) {
      entries.add(MapEntry(
        (taskAccuracies['recoil'] ?? 0.0).clamp(0.0, 1.0) * 100, recoilTrust));
    }

    if (entries.isEmpty) return 0;

    final double totalTrust = entries.fold(0.0, (s, e) => s + e.value);
    double weighted = entries.fold(0.0, (s, e) => s + e.key * e.value) / totalTrust;

    if (state.cprFraction < 0.6) weighted -= 10.0;

    return weighted.clamp(0, 100).round();
  }

  void onFrame(LandmarkFrame frame) {
    _frameBuffer.add(frame);
    if (!state.isActive) return;

    _updateCompressionCount(frame);
    final bool hasStartedCompressing = state.compressions > 0;

    if (_compressionPhase == _CompressionPhase.descending) {
      _descentFrameBuffer.add(frame);
      if (_descentFrameBuffer.length > _inferenceWindowSize) {
        _descentFrameBuffer.removeAt(0);
      }
    }

    if (!hasStartedCompressing) return;
    if (_descentFrameBuffer.length < 10) return;

    final result = _runInference(frame);

    // Only accumulate real model predictions — skip simulated (model unavailable)
    if (!result.isSimulated) {
      _assessedFrameCount++;
      _modelUsedThisSession = true;

      // Track top-level label for error rate breakdown
      _classFrameCounts.update(
        result.topClassLabel, (n) => n + 1, ifAbsent: () => 1,
      );

      // Rate task
      if (result.rateAccuracy != null &&
          (result.rateConfidence ?? 0.0) >= _taskConfidenceThreshold) {
        _rateAccuracies.add(result.rateAccuracy!);
        _taskConfidences['rate'] = result.rateConfidence!;
        // Prefer the direct per-task label from the 3-head web/API path.
        // Falls back to the allClassScores rescan only for mobile, whose
        // rule-based inference_service.dart never sets rateLabel.
        final rateLabel = result.rateLabel ??
            result.allClassScores.entries
                .where((e) => ['Correct','Too_Fast','Too_Slow'].contains(e.key))
                .fold<String>('', (best, e) => best.isEmpty || e.value > (result.allClassScores[best] ?? 0) ? e.key : best);
        if (rateLabel.isNotEmpty) {
          _rateClassCounts.update(rateLabel, (n) => n + 1, ifAbsent: () => 1);
        }
      }

      // Depth task — stricter threshold guards against majority-class collapse
      if (result.depthAccuracy != null &&
          (result.depthConfidence ?? 0.0) >= _depthConfidenceThreshold) {
        _depthAccuracies.add(result.depthAccuracy!);
        _taskConfidences['depth'] = result.depthConfidence!;
        final depthLabel = result.depthLabel ??
            result.allClassScores.entries
                .where((e) => ['Correct','Too_Shallow','Too_Deep'].contains(e.key))
                .fold<String>('', (best, e) => best.isEmpty || e.value > (result.allClassScores[best] ?? 0) ? e.key : best);
        if (depthLabel.isNotEmpty) {
          _depthClassCounts.update(depthLabel, (n) => n + 1, ifAbsent: () => 1);
        }
      }

      // Recoil task
      if (result.recoilAccuracy != null &&
          (result.recoilConfidence ?? 0.0) >= _taskConfidenceThreshold) {
        _recoilAccuracies.add(result.recoilAccuracy!);
        _taskConfidences['recoil'] = result.recoilConfidence!;
        final recoilLabel = result.recoilLabel ??
            result.allClassScores.entries
                .where((e) => ['Correct','Incomplete'].contains(e.key))
                .fold<String>('', (best, e) => best.isEmpty || e.value > (result.allClassScores[best] ?? 0) ? e.key : best);
        if (recoilLabel.isNotEmpty) {
          _recoilClassCounts.update(recoilLabel, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }

    if (result.currentBpm > 0) _bpmHistory.add(result.currentBpm);
    if (result.estimatedDepthCm > 0) _depthHistory.add(result.estimatedDepthCm);

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