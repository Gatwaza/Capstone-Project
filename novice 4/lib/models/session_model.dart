// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// Represents a completed CPR training session.
/// Stored locally in SQLite via session_logger.dart.
/// Schema version 1 — increment when adding fields.
@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,           // UUID v4
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalCompressions,
    required double meanBpm,
    required double meanDepthCm,
    required double cprFraction,  // % of session time actively compressing
    required int qualityScore,    // 0–100 composite
    required Map<String, double> errorRates, // errorKey → mean confidence over session
    @Default('en') String language,
    @Default(false) bool modelWasAvailable,
    /// Device identifier for performance tracking across sessions
    String? deviceModel,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}

/// Per-frame inference result passed from InferenceService → FeedbackEngine.
@freezed
class InferenceResult with _$InferenceResult {
  const factory InferenceResult({
    required DateTime timestamp,
    required int topClassIndex,
    required String topClassLabel,
    required double topClassConfidence,
    required Map<String, double> allClassScores,
    required double currentBpm,
    required double estimatedDepthCm,
    required double elbowAngleMean,
    required double spineVerticalityDeg,
    @Default(false) bool isSimulated, // true during Phase 1 demo mode
  }) = _InferenceResult;
}

/// Feedback prompt to be spoken by TTS and displayed in UI.
@freezed
class FeedbackPrompt with _$FeedbackPrompt {
  const factory FeedbackPrompt({
    required String key,       // matches AppConstants.promptsEn keys
    required String message,   // resolved string in active language
    required FeedbackSeverity severity,
    required DateTime issuedAt,
  }) = _FeedbackPrompt;
}

enum FeedbackSeverity { good, warning, critical }
