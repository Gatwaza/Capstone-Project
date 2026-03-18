// Novice — CPR-AI Coach
// GNU General Public License v3.0
//
// Web stub for tflite_flutter. Never called on web — inference handled by
// InferenceServiceWeb (TF.js). Exists only so inference_service.dart compiles.

class Interpreter {
  static Future<Interpreter> fromAsset(
    String path, {
    InterpreterOptions? options,
  }) async => Interpreter();

  void run(dynamic input, dynamic output) {}
  List<dynamic> getInputTensors() => [];
  List<dynamic> getOutputTensors() => [];
  void allocateTensors() {}
  void close() {}
}

class InterpreterOptions {
  int threads = 2;
}
