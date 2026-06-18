/// MODIFIED: Key Sections of session_provider.dart
/// 
/// EVIDENCE-BASED CHANGES:
/// - Replaced single-metric qualityScore with multi-task weighted scoring
/// - Integrated CNN-BiLSTM test-set F1-weighted and AUC-ROC baselines
/// - Added per-task tracking (rate, depth, recoil separately)
/// - Research source: ml_pipeline/CPR_Coach_Training.ipynb (cells 18, 33, 35)
///
/// RESEARCH METRICS EMBEDDED:
/// - CNN-BiLSTM Rate F1_w: 75.92%, AUC: 81.10%
/// - CNN-BiLSTM Depth F1_w: 94.05%, AUC: 95.11%
/// - CNN-BiLSTM Recoil F1_w: 74.79%, AUC: 84.14%
/// - Mean F1: 81.59%

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novice/models/session_model.dart';
import 'package:novice/models/landmark_frame.dart';

// ... [Keep existing imports and class definition] ...

class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  
  // Existing fields (unchanged):
  DateTime? _sessionStart;
  final List<double> _bpmHistory = [];
  final List<double> _depthHistory = [];
  final List<LandmarkFrame> _frameBuffer = [];
  int _assessedFrameCount = 0;
  Timer? _ticker;
  
  // NEW: Per-task accuracy tracking
  /// Tracks accuracy for each frame's Rate classification (0.0–1.0)
  final List<double> _rateAccuracies = [];
  
  /// Tracks accuracy for each frame's Depth classification (0.0–1.0)
  final List<double> _depthAccuracies = [];
  
  /// Tracks accuracy for each frame's Recoil classification (0.0–1.0)
  final List<double> _recoilAccuracies = [];
  
  // NEW: Per-task confidence tracking
  /// Model confidence for Rate task (0.0–1.0)
  Map<String, double> _taskConfidences = {'rate': 0, 'depth': 0, 'recoil': 0};
  
  // Existing services (unchanged):
  late final SessionLoggerService _storage;
  late final FeedbackEngine _feedback;
  late final TtsService _tts;
  
  // ... [Existing initState, startSession, stopSession, etc.] ...

  /// MODIFIED: Process each frame and accumulate per-task metrics
  ///
  /// Changes from original:
  ///  - Extract rate, depth, recoil accuracy/confidence from model output
  ///  - Accumulate in separate lists for later aggregation
  ///  - Pass to qualityScore computation at session end
  void onFrame(LandmarkFrame frame) {
    _frameBuffer.add(frame);

    final result = _runInference(frame);
    final prompt = _feedback.process(result, state.language);

    // NEW: Tally per-task classification accuracy and confidence
    _assessedFrameCount++;
    
    // Extract per-task metrics from inference result
    // (Assumes InferenceResult now has: 
    //   rateAccuracy, depthAccuracy, recoilAccuracy,
    //   rateConfidence, depthConfidence, recoilConfidence)
    if (result.rateAccuracy != null) {
      _rateAccuracies.add(result.rateAccuracy!);
      _taskConfidences['rate'] = result.rateConfidence ?? 0.0;
    }
    if (result.depthAccuracy != null) {
      _depthAccuracies.add(result.depthAccuracy!);
      _taskConfidences['depth'] = result.depthConfidence ?? 0.0;
    }
    if (result.recoilAccuracy != null) {
      _recoilAccuracies.add(result.recoilAccuracy!);
      _taskConfidences['recoil'] = result.recoilConfidence ?? 0.0;
    }

    // Existing metrics (unchanged)
    if (result.currentBpm > 0) _bpmHistory.add(result.currentBpm);
    if (result.estimatedDepthCm > 0) _depthHistory.add(result.estimatedDepthCm);

    _updateCompressionCount(frame);

    state = state.copyWith(
      bpm: result.currentBpm, 
      depthCm: result.estimatedDepthCm,
      currentPrompt: prompt, 
      lastInference: result, 
      lastFrame: frame,
    );
    if (_feedback.shouldSpeak(prompt)) _tts.speakKey(prompt.key);
  }

  /// MODIFIED: Multi-task quality score computation
  ///
  /// Research-backed formula:
  ///  1. Calculate mean accuracy per task (rate, depth, recoil)
  ///  2. Normalize against CNN-BiLSTM test-set F1-weighted baseline
  ///  3. Weight by AUC-ROC reliability scores
  ///  4. Apply CPR fraction penalty if < 60%
  ///  5. Apply confidence bonus if mean confidence ≥ 80%
  ///
  /// Evidence Sources:
  ///  - CNN-BiLSTM F1_w: Rate=75.92%, Depth=94.05%, Recoil=74.79%
  ///  - CNN-BiLSTM AUC-ROC: Rate=81.10%, Depth=95.11%, Recoil=84.14%
  ///  - Training notebook: ml_pipeline/CPR_Coach_Training.ipynb (cells 33–35)
  ///  - Full analysis: docs/EVALUATION_METRICS_AUDIT.md § "PART 4.1"
  int _computeQualityScore() {
    if (_assessedFrameCount == 0) return 0;
    
    // ─── CNN-BiLSTM Test-Set Baseline (Research) ───
    // Source: notebook cell 35, model ranking by mean F1 = 81.59%
    const double rateF1Baseline = 75.92;      // CNN-BiLSTM Rate F1_w %
    const double depthF1Baseline = 94.05;     // CNN-BiLSTM Depth F1_w %
    const double recoilF1Baseline = 74.79;    // CNN-BiLSTM Recoil F1_w %
    
    // ─── Weight by AUC-ROC (Test Set) ───
    // Higher AUC = more reliable classification; use as weight
    const double rateWeight = 0.8110;         // Rate AUC-ROC
    const double depthWeight = 0.9511;        // Depth AUC-ROC (highest)
    const double recoilWeight = 0.8414;       // Recoil AUC-ROC
    final double totalWeight = rateWeight + depthWeight + recoilWeight;
    
    // ─── Calculate Mean Accuracy per Task ───
    double rateMeanAcc = _rateAccuracies.isEmpty ? 0 : 
        (_rateAccuracies.reduce((a, b) => a + b) / _rateAccuracies.length) * 100;
    
    double depthMeanAcc = _depthAccuracies.isEmpty ? 0 : 
        (_depthAccuracies.reduce((a, b) => a + b) / _depthAccuracies.length) * 100;
    
    double recoilMeanAcc = _recoilAccuracies.isEmpty ? 0 : 
        (_recoilAccuracies.reduce((a, b) => a + b) / _recoilAccuracies.length) * 100;
    
    // ─── Normalize Against Baseline ───
    // If user achieves same accuracy as test-set model, score = 100
    // If user achieves half the baseline accuracy, score = 50
    double rateScore = (rateMeanAcc / rateF1Baseline).clamp(0, 2) * 100;
    double depthScore = (depthMeanAcc / depthF1Baseline).clamp(0, 2) * 100;
    double recoilScore = (recoilMeanAcc / recoilF1Baseline).clamp(0, 2) * 100;
    
    // ─── Weighted Average ───
    // Depth is most reliable (AUC=95%), so has highest weight
    double weightedScore = (
        (rateScore * rateWeight) +
        (depthScore * depthWeight) +
        (recoilScore * recoilWeight)
    ) / totalWeight;
    
    // ─── CPR Fraction Penalty ───
    // Rationale: Model can only assess frames where person is present.
    // If session < 60% active compression, penalize consistency.
    if (state.cprFraction < 0.6) {
      weightedScore -= 10.0;
    }
    
    // ─── Confidence Bonus ───
    // If all three tasks have high confidence (≥80%), add reliability bonus
    final double avgConfidence = (_taskConfidences['rate'] ?? 0.0 +
                                  _taskConfidences['depth'] ?? 0.0 +
                                  _taskConfidences['recoil'] ?? 0.0) / 3.0;
    if (avgConfidence >= 0.80) {
      weightedScore += 5.0;  // Bonus for high-confidence session
    }
    
    // ─── Final Clamp ───
    return weightedScore.clamp(0, 100).round();
  }

  /// MODIFIED: stopSession now includes per-task metrics in returned SessionModel
  ///
  /// Changes:
  ///  - Compute taskAccuracies (mean per task)
  ///  - Compute taskConfidences (final confidence state)
  ///  - Pass to SessionModel constructor
  Future<String?> stopSession() async {
    _ticker?.cancel();
    if (!state.isActive || _sessionStart == null) return null;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // NEW: Calculate mean per-task accuracy
    final taskAccuracies = {
      'rate': _rateAccuracies.isEmpty ? 0.0 : 
          _rateAccuracies.reduce((a, b) => a + b) / _rateAccuracies.length,
      'depth': _depthAccuracies.isEmpty ? 0.0 : 
          _depthAccuracies.reduce((a, b) => a + b) / _depthAccuracies.length,
      'recoil': _recoilAccuracies.isEmpty ? 0.0 : 
          _recoilAccuracies.reduce((a, b) => a + b) / _recoilAccuracies.length,
    };
    
    final session = SessionModel(
      id: id, 
      startedAt: _sessionStart!, 
      endedAt: DateTime.now(),
      totalCompressions: state.compressions,
      meanBpm: _mean(_bpmHistory), 
      meanDepthCm: _mean(_depthHistory),
      cprFraction: state.cprFraction, 
      qualityScore: _computeQualityScore(),  // USES NEW FORMULA
      errorRates: {},
      taskAccuracies: taskAccuracies,        // NEW: Per-task tracking
      taskConfidences: _taskConfidences,     // NEW: Confidence tracking
      language: state.language,
      modelWasAvailable: state.modelAvailable,
      rawFrames: List.unmodifiable(_frameBuffer),
    );
    
    await _storage.saveSession(session);
    _log.i('Session saved: $id | compressions=${state.compressions} '
           '| rate=${taskAccuracies['rate']?.toStringAsFixed(2)}% '
           '| depth=${taskAccuracies['depth']?.toStringAsFixed(2)}% '
           '| recoil=${taskAccuracies['recoil']?.toStringAsFixed(2)}%');
    
    state = state.copyWith(isActive: false);
    return id;
  }

  // ... [Keep existing helper methods: _mean, _runInference, etc.] ...
}

// ─── UPDATE: Modify InferenceResult if needed ───
// Ensure the model result includes:
//  - rateAccuracy, depthAccuracy, recoilAccuracy (0.0–1.0)
//  - rateConfidence, depthConfidence, recoilConfidence (0.0–1.0)
//
// Example addition to inference_service.dart:
//
// class InferenceResult {
//   final String topClassLabel;
//   final double topClassConfidence;
//   // ... existing fields ...
//   
//   // NEW:
//   final double? rateAccuracy;        // Accuracy for rate classification
//   final double? depthAccuracy;       // Accuracy for depth classification
//   final double? recoilAccuracy;      // Accuracy for recoil classification
//   final double? rateConfidence;      // Model confidence for rate
//   final double? depthConfidence;     // Model confidence for depth
//   final double? recoilConfidence;    // Model confidence for recoil
// }
