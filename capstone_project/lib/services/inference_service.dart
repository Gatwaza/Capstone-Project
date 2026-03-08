import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';

class InferenceService {
  Interpreter? _interpreter;
  bool _modelLoaded = false;

  bool get modelLoaded => _modelLoaded;

  // Rolling window: [windowSize][features]
  final List<List<double>> _window = [];

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        AppConstants.modelAssetPath,
        options: options,
      );
      _modelLoaded = true;
      debugPrint('[InferenceService] TFLite model loaded ✓');
    } catch (e) {
      _modelLoaded = false;
      debugPrint('[InferenceService] No model found — running rule-based mode. ($e)');
    }
  }

  /// Add a 12-dim feature frame to the rolling window.
  /// Returns a [ClassifierResult] when the window is full (30 frames),
  /// or null if the window is still filling or model not loaded.
  ClassifierResult? processFrame(List<double> features) {
    if (!_modelLoaded || _interpreter == null) return null;

    _window.add(features);
    if (_window.length > AppConstants.classifierWindowFrames) {
      _window.removeAt(0);
    }
    if (_window.length < AppConstants.classifierWindowFrames) return null;

    // Build input tensor: shape [1, 30, 12]
    final input = [_window.map((f) => f).toList()];
    final output = List.generate(1, (_) => List.filled(AppConstants.classLabels.length, 0.0));

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      debugPrint('[InferenceService] Inference error: $e');
      return null;
    }

    final probs = output[0];
    int maxIdx = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxIdx]) maxIdx = i;
    }

    if (probs[maxIdx] < AppConstants.classifierConfidenceThreshold) return null;

    return ClassifierResult(
      label: AppConstants.classLabels[maxIdx],
      confidence: probs[maxIdx],
      allProbabilities: Map.fromIterables(AppConstants.classLabels, probs),
    );
  }

  void reset() => _window.clear();

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
  }
}

class ClassifierResult {
  final String label;
  final double confidence;
  final Map<String, double> allProbabilities;
  const ClassifierResult({
    required this.label,
    required this.confidence,
    required this.allProbabilities,
  });
}
