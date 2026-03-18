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

  double get cprFraction {
    if (elapsedSeconds == 0) return 0;
    return ((compressions * 0.55) / elapsedSeconds).clamp(0.0, 1.0);
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
    );
    await _storage.saveSession(session);
    _log.i('Session saved: $id');
    state = state.copyWith(isActive: false);
    return id;
  }

  void onFrame(LandmarkFrame frame) {
    final result = _runInference(frame);
    final prompt = _feedback.process(result, state.language);
    if (result.currentBpm > 0) _bpmHistory.add(result.currentBpm);
    if (result.estimatedDepthCm > 0) _depthHistory.add(result.estimatedDepthCm);
    if (frame.wristVelocityY > 0.008) {
      state = state.copyWith(compressions: state.compressions + 1);
    }
    state = state.copyWith(
      bpm: result.currentBpm, depthCm: result.estimatedDepthCm,
      currentPrompt: prompt, lastInference: result,
    );
    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);
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

final liveSessionProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>(
  (_) => LiveSessionNotifier(),
);

final sessionHistoryProvider = FutureProvider<List<SessionModel>>((ref) async {
  return getIt<StorageService>().loadAllSessions();
});
