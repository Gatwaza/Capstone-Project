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
    this.language = 'en',
    this.modelAvailable = false,
  });

  final bool isActive;
  final double bpm;
  final double depthCm;
  final int compressions;
  final int elapsedSeconds;
  final FeedbackPrompt? currentPrompt;
  final InferenceResult? lastInference;
  final String language;
  final bool modelAvailable;

  String get elapsedFormatted {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── FIX 2: cprFraction based on real inter-compression timing ──────────────
  // ERC 2021: CPR fraction = proportion of time spent compressing.
  // At 100–120 bpm each compression+recoil cycle takes ~500–600 ms.
  // We estimate: compressions * 0.52s / totalElapsed.
  // Clamped to [0, 1] to stay meaningful.
  double get cprFraction {
    if (elapsedSeconds == 0) return 0;
    // 0.52 s ≈ mid-point of a 100–120 bpm cycle (500–600 ms per compression)
    return ((compressions * 0.52) / elapsedSeconds).clamp(0.0, 1.0);
  }

  int get qualityScore {
    if (compressions == 0) return 0;
    double score = 100;
    if (bpm > 0 && (bpm < 100 || bpm > 120)) score -= 20;
    if (depthCm > 0 && (depthCm < 4.5 || depthCm > 6.5)) score -= 20;
    if (cprFraction < 0.6) score -= 15;
    return score.clamp(0, 100).toInt();
  }

  LiveSessionState copyWith({
    bool? isActive, double? bpm, double? depthCm,
    int? compressions, int? elapsedSeconds,
    FeedbackPrompt? currentPrompt, InferenceResult? lastInference,
    String? language, bool? modelAvailable,
  }) => LiveSessionState(
    isActive: isActive ?? this.isActive,
    bpm: bpm ?? this.bpm,
    depthCm: depthCm ?? this.depthCm,
    compressions: compressions ?? this.compressions,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    currentPrompt: currentPrompt ?? this.currentPrompt,
    lastInference: lastInference ?? this.lastInference,
    language: language ?? this.language,
    modelAvailable: modelAvailable ?? this.modelAvailable,
  );
}

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  LiveSessionNotifier() : super(const LiveSessionState()) {
    _feedback = getIt<FeedbackEngine>();
    _tts      = getIt<TtsService>();
    _storage  = getIt<StorageService>();
    _log      = getIt<Logger>();
  }

  late final FeedbackEngine _feedback;
  late final TtsService     _tts;
  late final StorageService _storage;
  late final Logger         _log;

  Timer? _ticker;
  final List<double> _bpmHistory   = [];
  final List<double> _depthHistory = [];

  // ── FIX 1: Compression state machine ───────────────────────────────────────
  // A compression is counted exactly once per downstroke→upstroke transition.
  // States: idle → descending → ascending (= 1 compression counted) → idle
  //
  // Thresholds tuned to normalised wrist velocity (0.0–1.0 coordinate space):
  //   +ve velocity = wrist moving DOWN (toward patient)
  //   -ve velocity = wrist moving UP   (recoil)
  _CompressionPhase _compressionPhase = _CompressionPhase.idle;
  static const double _downThreshold = 0.006;  // entering descent
  static const double _upThreshold   = -0.004; // entering recoil (negative)
  // Minimum consecutive frames in descent before we believe it's a real compression
  int _descentFrameCount = 0;
  static const int _minDescentFrames = 3;

  // ── FIX 3: Raw frame buffer for dataset collection ─────────────────────────
  final List<LandmarkFrame> _frameBuffer = [];
  DateTime? _sessionStart;

  bool get _modelAvailable {
    try {
      if (kIsWeb) return getIt<InferenceServiceWeb>().isModelLoaded;
      return getIt<InferenceService>().isModelLoaded;
    } catch (_) { return false; }
  }

  InferenceResult _runInference(LandmarkFrame frame) {
    try {
      if (kIsWeb) return getIt<InferenceServiceWeb>().infer(frame);
      return getIt<InferenceService>().infer(frame);
    } catch (_) {
      return InferenceResult(
        timestamp: DateTime.now(), topClassIndex: 0,
        topClassLabel: 'correct_compression', topClassConfidence: 0.5,
        allClassScores: const {}, currentBpm: 0, estimatedDepthCm: 0,
        elbowAngleMean: 0, spineVerticalityDeg: 0, isSimulated: true,
      );
    }
  }

  void startSession() {
    _sessionStart = DateTime.now();
    _bpmHistory.clear();
    _depthHistory.clear();
    _frameBuffer.clear();
    // Reset compression state machine
    _compressionPhase = _CompressionPhase.idle;
    _descentFrameCount = 0;

    _feedback.reset();
    state = state.copyWith(
      isActive: true, compressions: 0, elapsedSeconds: 0,
      bpm: 0, depthCm: 0, modelAvailable: _modelAvailable,
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
    final session = SessionModel(
      id: id, startedAt: _sessionStart!, endedAt: DateTime.now(),
      totalCompressions: state.compressions,
      meanBpm: _mean(_bpmHistory), meanDepthCm: _mean(_depthHistory),
      cprFraction: state.cprFraction, qualityScore: state.qualityScore,
      errorRates: {}, language: state.language,
      modelWasAvailable: state.modelAvailable,
      // FIX 3: persist raw frames for retraining pipeline
      rawFrames: List.unmodifiable(_frameBuffer),
    );
    await _storage.saveSession(session);
    _log.i('Session saved: $id | compressions=${state.compressions} '
           '| frames=${_frameBuffer.length}');
    state = state.copyWith(isActive: false);
    return id;
  }

  void onFrame(LandmarkFrame frame) {
    // FIX 3: buffer every frame
    _frameBuffer.add(frame);

    final result = _runInference(frame);
    final prompt = _feedback.process(result, state.language);

    if (result.currentBpm > 0) _bpmHistory.add(result.currentBpm);
    if (result.estimatedDepthCm > 0) _depthHistory.add(result.estimatedDepthCm);

    // FIX 1: state machine compression counting
    _updateCompressionCount(frame);

    state = state.copyWith(
      bpm: result.currentBpm, depthCm: result.estimatedDepthCm,
      currentPrompt: prompt, lastInference: result,
    );
    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);
  }

  /// Counts one compression per downstroke→upstroke transition.
  ///
  /// Phase diagram:
  ///   idle ──(vel > +down)──> descending
  ///   descending ──(vel < +up after minFrames)──> ascending  [COUNT HERE]
  ///   ascending ──(vel > +down OR near zero)──> idle/descending
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
          // Confirmed real downstroke has ended — count one compression
          _compressionPhase = _CompressionPhase.ascending;
          state = state.copyWith(compressions: state.compressions + 1);
          _descentFrameCount = 0;
        } else if (vel.abs() < _downThreshold * 0.5) {
          // Velocity near zero without proper descent — back to idle (noise)
          _compressionPhase = _CompressionPhase.idle;
          _descentFrameCount = 0;
        }
        break;

      case _CompressionPhase.ascending:
        // Wait for wrist to return near neutral before allowing next compression
        if (vel > _downThreshold) {
          // New descent started — go directly to descending
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
  void dispose() { _ticker?.cancel(); super.dispose(); }
}

/// Compression detection phase for the wrist velocity state machine.
enum _CompressionPhase { idle, descending, ascending }

final liveSessionProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>(
  (_) => LiveSessionNotifier(),
);

final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) async {
  return getIt<StorageService>().loadAllSessions();
});
