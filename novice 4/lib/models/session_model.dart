// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:freezed_annotation/freezed_annotation.dart';

import 'landmark_frame.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// Represents a completed CPR training session.
/// Stored locally via StorageService.
/// Schema version 2 — added rawFrames for retraining pipeline.
@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,           // millisecondsSinceEpoch string
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalCompressions,
    required double meanBpm,
    required double meanDepthCm,
    required double cprFraction,  // % of session time actively compressing
    required int qualityScore,    // 0–100 composite
    required Map<String, double> errorRates, // errorKey → mean confidence
    @Default('en') String language,
    @Default(false) bool modelWasAvailable,
    /// Device identifier for performance tracking across sessions
    String? deviceModel,
    /// Raw per-frame landmark data for retraining pipeline.
    /// Excluded from json_serializable — StorageService serialises frames
    /// manually via _frameToMap / exportFramesNdjson so we keep full control
    /// over the wire format and avoid bloating the freezed generated code.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([]) List<LandmarkFrame> rawFrames,
    /// Reviewer label assigned after session review (null = not yet reviewed).
    /// Values: 'correct' | 'incorrect' | 'partial'
    String? reviewLabel,
    /// Optional free-text note from reviewer or researcher.
    String? reviewNote,
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
