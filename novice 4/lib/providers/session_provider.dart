// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Riverpod providers for the live training session and saved-session
// history. This is the single source of truth that training_screen,
// home_screen, history_screen, and settings_screen all read from.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/injection.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';
import '../services/feedback_engine.dart';
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
    this.modelUptimeFraction = 0,
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

  /// FIX: this now measures real compression-motion activity
  /// (frames where wrist velocity crossed the compression threshold, or a
  /// down-cycle was in progress) divided by assessed frames — the actual
  /// clinical Chest Compression Fraction concept (ERC/AHA target ≥60%).
  /// Previously this was `_activeFrameCount / _assessedFrameCount` where
  /// _activeFrameCount only tracked `!inference.isSimulated` (model API
  /// reachability), which is a completely different quantity that happened
  /// to share a plausible-sounding field name. An idle, zero-compression
  /// session showed 88% "CPR Fraction" under the old definition purely
  /// because the model stayed reachable — see [modelUptimeFraction] below
  /// for that metric, now correctly separated out and labeled honestly.
  final double cprFraction;

  /// Fraction of assessed frames where the inference API actually
  /// responded (was not in isSimulated/fallback mode). This is what
  /// `cprFraction` used to silently measure. Kept as a distinct,
  /// correctly-named diagnostic signal — useful for spotting connectivity
  /// issues (e.g. the "Model: Unavailable" + nonzero score case, where this
  /// value being low over the session explains why the score is based on
  /// only a partial sample of frames even though the LAST frame shows
  /// Unavailable).
  final double modelUptimeFraction;
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
    double? modelUptimeFraction,
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
      modelUptimeFraction: modelUptimeFraction ?? this.modelUptimeFraction,
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
  int _activeFrameCount = 0;      // model-uptime counter (renamed meaning, see modelUptimeFraction)
  int _compressionMotionFrameCount = 0; // FIX: real compression-activity counter, see cprFraction

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
    _compressionMotionFrameCount = 0;
    _lastVelocityY = null;
    _wasDescending = false;
    _lastCompressionAt = null;
    _feedback.reset();

    // FIX: InferenceServiceWeb is a DI singleton whose causal feature
    // extractor, 60-frame model buffer, BPM history, depth calibration,
    // and cached API result all persist across sessions unless explicitly
    // cleared here. Without this, a second session run in the same
    // browser tab (no page reload) leaks the previous participant's
    // in-flight rolling-window/derivative state into the first ~2.4s of
    // the new session. Must run before the first onFrame() call for this
    // session.
    getIt<InferenceServiceWeb>().resetSession();

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

    // FIX (Bug 4 — see debugging session): rate/depth/recoil accuracy used
    // to accumulate on EVERY assessed frame, with no check for whether any
    // compression motion was actually happening. RATE_CLASSES/DEPTH_CLASSES
    // have no "no compression" option (['Correct','Too_Fast','Too_Slow'] /
    // ['Correct','Too_Deep','Too_Shallow']), so a static/idle frame is
    // out-of-distribution input the model was never trained to abstain on —
    // it defaults toward SOME label regardless (observed: 'Correct' for
    // rate/depth, 'Incomplete' for recoil, on a genuinely idle session).
    // Every one of those meaningless idle-frame guesses was getting
    // averaged into the accuracy that feeds the final quality score,
    // reproduced live as: 0 compressions, 0 bpm → Rate 100%, Depth 100%.
    // Fix: only accumulate accuracy for a frame while real compression
    // motion is in progress — descending past the velocity threshold, or
    // still mid-down-cycle (_wasDescending) — computed BEFORE
    // _updateCompressionCount() below runs and mutates _wasDescending for
    // the next frame.
    final v = frame.wristVelocityY;
    final inCompressionMotion =
        v.abs() > _compressionVelocityThreshold || _wasDescending;
    if (inCompressionMotion) _compressionMotionFrameCount++;

    if (inCompressionMotion) {
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
    }

    // FIX (Bug 1 — see debugging session): this used to append to
    // _bpmHistory/_depthHistory on EVERY frame, decoupled from the actual
    // compression counter. _estimateBpm()'s single-frame velocity-peak
    // detector has no cycle requirement or debounce, so pure landmark-
    // tracking jitter (hand tremor, camera micro-noise) tripped it and got
    // averaged into meanBpm/meanDepthCm even while the stricter, debounced
    // _updateCompressionCount() correctly reported 0 compressions
    // (reproduced: total_compressions=0 but mean_bpm=192). Fix: only
    // accumulate history at the moment a real completed down→up compression
    // cycle is registered.
    final compressionJustCompleted = _updateCompressionCount(frame);
    if (compressionJustCompleted) {
      if (inference.currentBpm > 0) _bpmHistory.add(inference.currentBpm);
      if (inference.estimatedDepthCm > 0) {
        _depthHistory.add(inference.estimatedDepthCm);
      }
    }

    final liveTaskAccuracies = {
      'rate': _mean(_rateAccuracies),
      'depth': _mean(_depthAccuracies),
      'recoil': _mean(_recoilAccuracies),
    };

    state = state.copyWith(
      // FIX (Bug 2 — see debugging session): bpm/depthCm are computed from
      // local pose-landmark math in inference_service_web.dart, independent
      // of whether the hosted TCN model actually responded. Previously
      // these were surfaced unconditionally, so a "Model: Unavailable"
      // session (API unreachable, no classification ran) would still show
      // quantitative-looking bpm/depth numbers right next to it, implying
      // something had been AI-assessed when nothing had. Fix: hide (zero)
      // these live-display fields when the model isn't available;
      // modelAvailable is already exposed in state for the UI to branch on
      // and show "Model Unavailable" instead of a number.
      bpm: inference.isSimulated ? 0 : inference.currentBpm,
      depthCm: inference.isSimulated ? 0 : inference.estimatedDepthCm,
      // FIX: now the real Chest Compression Fraction (compression-motion
      // frames / assessed frames), not model uptime — see field doc above.
      cprFraction: _assessedFrameCount == 0
          ? 0
          : _compressionMotionFrameCount / _assessedFrameCount,
      modelUptimeFraction: _assessedFrameCount == 0
          ? 0
          : _activeFrameCount / _assessedFrameCount,
      currentPrompt: prompt,
      lastInference: inference,
      lastFrame: frame,
      modelAvailable: !inference.isSimulated,
      taskAccuracies: liveTaskAccuracies,
    );

    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);
  }

  /// Web-only build: mobile (on-device TFLite) inference is on hold.
  /// injection.dart only ever registers InferenceServiceWeb now.
  /// NOTE: re-add the kIsWeb ? ... : getIt<InferenceService>() branch here
  /// (and restore inference_service.dart) if mobile work resumes.
  InferenceResult _runInference(LandmarkFrame frame) {
    return getIt<InferenceServiceWeb>().infer(frame);
  }

  /// Returns true iff this call registered a newly-completed compression
  /// (a debounced down→up cycle), so callers (onFrame's history
  /// accumulation) can gate on real compressions rather than raw frames.
  bool _updateCompressionCount(LandmarkFrame frame) {
    final v = frame.wristVelocityY;
    if (_lastVelocityY == null) {
      _lastVelocityY = v;
      return false;
    }

    final descending = v > _compressionVelocityThreshold;
    final ascending = v < -_compressionVelocityThreshold;

    bool completed = false;
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
        completed = true;
      }
      _wasDescending = false;
    }

    _lastVelocityY = v;
    return completed;
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

    // FIX (Bug 3 — see debugging session): this used to divide each
    // accuracy by its F1 baseline (rateF1Baseline=91.7 etc.) before
    // scaling to 0-100. Since those baselines are themselves already close
    // to 100, that division compressed the formula's usable dynamic range
    // into a thin sliver at the top: rateAcc=1.0 (perfect) computed to
    // (100/91.7)=109%, which the .clamp(0,2)*100 ceiling then flattened to
    // exactly 100, while a single misclassified frame dragged the ratio
    // down fast since the denominator was already ~90-98. Net effect: a
    // short session (20-40 assessed frames) almost always landed fully on
    // 0 or 100, never in between. Fix: rateAcc/depthAcc/recoilAcc are
    // already fair 0-1 accuracy fractions on their own — scale directly to
    // 0-100, no baseline division. The AUC-derived weights below keep
    // their intended role as a per-task importance weighting, not a
    // denominator.
    //
    // Baselines from sliding-window retrain (ml_pipeline/CPR_Coach_Training.ipynb,
    // Stage 9 evaluate()) — TCN selected as deploy model in place of
    // CNN_BiLSTM (won on every task/metric: rate/depth/recoil F1_w and AUC).
    // TCN test-set F1_w: rate=91.7%, depth=98.3%, recoil=88.5% (kept here
    // for reference/reporting; not used as a scoring denominator).
    const rateWeight = 0.983;   // TCN test-set rate AUC-ROC
    const depthWeight = 0.993;  // TCN test-set depth AUC-ROC
    const recoilWeight = 0.959; // TCN test-set recoil AUC-ROC
    const totalWeight = rateWeight + depthWeight + recoilWeight;

    final rateScore = rateAcc * 100;     // 0-100, no inflation
    final depthScore = depthAcc * 100;   // 0-100, no inflation
    final recoilScore = recoilAcc * 100; // 0-100, no inflation

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