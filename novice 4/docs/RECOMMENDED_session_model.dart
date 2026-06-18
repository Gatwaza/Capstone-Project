/// MODIFIED: session_model.dart
/// 
/// Evidence-Based Updates:
/// - Added taskAccuracies and taskConfidences maps to track per-task performance
/// - Aligns with CNN-BiLSTM three-head architecture (rate, depth, recoil)
/// - Research source: ml_pipeline/CPR_Coach_Training.ipynb (cells 33–35)
/// 
/// CHANGES FROM ORIGINAL:
///  1. Added Map<String, double> taskAccuracies (line ~50)
///  2. Added Map<String, double> taskConfidences (line ~51)
///  3. Updated freezed generator (@freezed)

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required int totalCompressions,
    required double meanBpm,
    required double meanDepthCm,
    required double cprFraction,
    required int qualityScore,
    
    /// Error rates breakdown from model inference
    /// Example: {'correct_compression': 0.75, 'hand_too_high': 0.15, ...}
    required Map<String, double> errorRates,
    
    /// NEW: Per-task model accuracies (CNN-BiLSTM test-set baseline)
    /// Example: {'rate': 0.82, 'depth': 0.95, 'recoil': 0.76}
    /// Research basis: CNN-BiLSTM achieves rate=75.92%, depth=94.05%, recoil=74.79%
    /// (ml_pipeline/CPR_Coach_Training.ipynb, notebook cell 35)
    @Default({})
    Map<String, double> taskAccuracies,
    
    /// NEW: Per-task model confidence scores from inference
    /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
    /// Used for quality score weighting (see qualityScoreCalculation in docs/EVALUATION_METRICS_AUDIT.md)
    @Default({})
    Map<String, double> taskConfidences,
    
    required String language,
    required bool modelWasAvailable,
    @Default({}) Map<String, dynamic> deviceInfo,
    @Default([]) List<dynamic> rawFrames,
    @Default('') String reviewLabel,
    @Default('') String reviewNote,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}
