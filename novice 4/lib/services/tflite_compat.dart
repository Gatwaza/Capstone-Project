// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// Conditional tflite_flutter import.
// tflite_flutter is mobile-only. On web, InferenceServiceWeb handles
// inference via TF.js. This compat file lets inference_service.dart
// compile on web without errors.

export 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'tflite_web_stub.dart';
