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
    required String id, // millisecondsSinceEpoch string
    required String participantId, // FK -> participants.participant_id (Supabase)
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalCompressions,
    required double meanBpm,
    required double meanDepthCm,
    required double cprFraction, // % of session time actively compressing
    required int
        qualityScore, // 0–100, derived from CNN-BiLSTM multi-task weighted formula (research: ml_pipeline/CPR_Coach_Training.ipynb cell 35)
    required Map<String, double>
        errorRates, // classLabel → fraction of session frames classified as that label (model-derived)
    /// Per-task model accuracies from CNN-BiLSTM (test-set baseline reference)
    /// Example: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75}
    /// Research basis: Rate F1_w=75.92%, Depth F1_w=94.05%, Recoil F1_w=74.79%
    @Default({}) Map<String, double> taskAccuracies,

    /// Per-task model confidence scores from inference
    /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
    /// Used for quality score weighting and session reliability assessment
    @Default({}) Map<String, double> taskConfidences,
    @Default('en') String language,
    @Default(false) bool modelWasAvailable,

    /// Device identifier for performance tracking across sessions
    String? deviceModel,

    /// Raw per-frame landmark data for retraining pipeline.
    /// Excluded from json_serializable — StorageService serialises frames
    /// manually via _frameToMap / exportFramesNdjson so we keep full control
    /// over the wire format and avoid bloating the freezed generated code.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<LandmarkFrame> rawFrames,

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
/// Now includes per-task accuracy and confidence for CNN-BiLSTM multi-task model.
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
    // Per-task metrics from CNN-BiLSTM three-head model
    double? rateAccuracy, // Rate classification accuracy (0.0–1.0)
    double? rateConfidence, // Rate classification confidence
    double? depthAccuracy, // Depth classification accuracy (0.0–1.0)
    double? depthConfidence, // Depth classification confidence
    double? recoilAccuracy, // Recoil classification accuracy (0.0–1.0)
    double? recoilConfidence, // Recoil classification confidence
    @Default(false) bool isSimulated, // true during Phase 1 demo mode
  }) = _InferenceResult;
}

/// Feedback prompt to be spoken by TTS and displayed in UI.
@freezed
class FeedbackPrompt with _$FeedbackPrompt {
  const factory FeedbackPrompt({
    required String key, // matches AppConstants.promptsEn keys
    required String message, // resolved string in active language
    required FeedbackSeverity severity,
    required DateTime issuedAt,
  }) = _FeedbackPrompt;
}

enum FeedbackSeverity { good, warning, critical }