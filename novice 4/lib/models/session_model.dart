// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:freezed_annotation/freezed_annotation.dart';

import 'landmark_frame.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

/// Represents a completed CPR training session.
/// Schema version 3 — research metrics aligned with TCN evaluation
/// framework (ml_pipeline/CPR_Coach_Training.ipynb cells 33-35):
/// accuracy, precision, recall, F1-score, ROC-AUC per task.
@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    required String participantId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalCompressions,
    required double meanBpm,
    required double meanDepthCm,
    required double cprFraction,

    /// 0–100 weighted multi-task quality score (TCN AUC-weighted).
    required int qualityScore,

    /// Per-frame class distribution: label → fraction of session frames.
    required Map<String, double> errorRates,

    /// Schema generation for this session record.
    ///   1 = pre-3-head-refactor: 8-class single-label output
    ///       (error_rates keys like 'bent_elbows', 'hand_too_high', etc.,
    ///       no rate/depth/recoil precision/recall/F1/AUC columns).
    ///   2 = current: 3-head model (rate/depth/recoil independent labels),
    ///       full per-task accuracy/precision/recall/F1/AUC populated.
    /// Existing rows created before this field existed are migrated to 1
    /// by scripts/migrate_schema_version.py — see that script for the CSV
    /// heuristic used to tell old sessions apart from new ones.
    @Default(2) int schemaVersion,

    // ── Research metrics: ACCURACY ──────────────────────────────────────────
    // Fraction of frames where the model classified the task as "Correct".
    @Default(0.0) double rateAccuracy,
    @Default(0.0) double depthAccuracy,
    @Default(0.0) double recoilAccuracy,

    // ── Research metrics: PRECISION ─────────────────────────────────────────
    // Macro-averaged precision per task (client-side, from frame tally).
    @Default(0.0) double ratePrecision,
    @Default(0.0) double depthPrecision,
    @Default(0.0) double recoilPrecision,

    // ── Research metrics: RECALL ────────────────────────────────────────────
    @Default(0.0) double rateRecall,
    @Default(0.0) double depthRecall,
    @Default(0.0) double recoilRecall,

    // ── Research metrics: F1-SCORE ──────────────────────────────────────────
    // Weighted F1 per task (matches notebook evaluation: F1_w).
    @Default(0.0) double rateF1,
    @Default(0.0) double depthF1,
    @Default(0.0) double recoilF1,

    // ── Research metrics: ROC-AUC ───────────────────────────────────────────
    // Mean model confidence used as probabilistic score for AUC estimation.
    @Default(0.0) double rateAuc,
    @Default(0.0) double depthAuc,
    @Default(0.0) double recoilAuc,

    // ── Legacy per-task confidence (kept for quality score weighting) ───────
    @Default({}) Map<String, double> taskConfidences,

    @Default('en') String language,
    @Default(false) bool modelWasAvailable,
    String? deviceModel,

    /// Raw per-frame landmark data for retraining pipeline.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<LandmarkFrame> rawFrames,

    String? reviewLabel,
    String? reviewNote,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}

/// Per-frame inference result from InferenceService.
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
    // Per-task accuracy and confidence from TCN three-head model
    double? rateAccuracy,
    double? rateConfidence,
    double? depthAccuracy,
    double? depthConfidence,
    double? recoilAccuracy,
    double? recoilConfidence,
    // Direct per-task labels from the 3-head web/API path (e.g. 'Correct',
    // 'Too_Fast', 'Too_Shallow', 'Incomplete'). Null on mobile — the
    // rule-based/8-class inference_service.dart never sets these, so
    // consumers must fall back to topClassLabel/allClassScores when null.
    String? rateLabel,
    String? depthLabel,
    String? recoilLabel,
    @Default(false) bool isSimulated,
  }) = _InferenceResult;
}

/// Feedback prompt spoken by TTS and displayed in UI.
@freezed
class FeedbackPrompt with _$FeedbackPrompt {
  const factory FeedbackPrompt({
    required String key,
    required String message,
    required FeedbackSeverity severity,
    required DateTime issuedAt,
  }) = _FeedbackPrompt;
}

enum FeedbackSeverity { good, warning, critical }