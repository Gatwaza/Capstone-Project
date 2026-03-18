/**
 * Novice — CPR-AI Coach
 * GNU General Public License v3.0
 * Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
 *
 * flutter_inference_bridge.js
 * ───────────────────────────
 * Wraps TensorFlow.js and exposes inference to Flutter Web via
 * window.NoviceInferenceBridge.
 *
 * Loaded by web/index.html BEFORE Flutter bootstrap.
 * Flutter's InferenceServiceWeb calls these via @JS() dart:js interop.
 *
 * Architecture (Web):
 *   Flutter Dart (InferenceServiceWeb)
 *     ↓  @JS() interop
 *   NoviceInferenceBridge.runInference(inputData)
 *     ↓
 *   TensorFlow.js model (loaded from assets/models/model.json)
 *     ↓
 *   float32 scores array [8 classes] → returned to Dart
 *
 * The model.json + weight shards are produced by:
 *   ml_pipeline/src/export/convert_to_tfjs.py
 */

window.NoviceInferenceBridge = {
  _model:       null,
  _modelLoaded: false,
  _loading:     false,

  isModelLoaded() {
    return this._modelLoaded;
  },

  /**
   * Load the TFJS graph model from Flutter's asset bundle.
   * Called automatically when the bridge script loads.
   * Flutter web serves assets at /assets/ by default.
   */
  async loadModel() {
    if (this._loading || this._modelLoaded) return;
    this._loading = true;

    // tf is loaded via CDN <script> in index.html
    if (typeof tf === 'undefined') {
      console.warn('[NoviceInferenceBridge] TensorFlow.js not loaded — inference unavailable');
      this._loading = false;
      return;
    }

    const modelUrl = 'assets/assets/models/model.json';
    try {
      this._model       = await tf.loadGraphModel(modelUrl);
      this._modelLoaded = true;
      console.log('[NoviceInferenceBridge] TFJS model loaded from', modelUrl);
      // Warm-up inference to JIT-compile WebGL kernels
      const dummy = tf.zeros([1, 30, 12]);
      this._model.predict(dummy).dispose();
      dummy.dispose();
      console.log('[NoviceInferenceBridge] Model warm-up complete');
    } catch (err) {
      console.warn(
        '[NoviceInferenceBridge] Model not found at', modelUrl,
        '— running in rule-based mode.\n',
        'Train with ml_pipeline/ and run convert_to_tfjs.py, then flutter build web.'
      );
      this._modelLoaded = false;
    } finally {
      this._loading = false;
    }
  },

  /**
   * Run inference on one temporal window.
   * @param {Array<Array<number>>} inputData — shape [30][12], from Dart list
   * @returns {Array<number>} — softmax scores [8], or null on failure
   */
  runInference(inputData) {
    if (!this._model || !this._modelLoaded) return null;

    // Dart passes a JS array of arrays — reshape to [1, 30, 12] tensor
    let tensor;
    try {
      const flat  = inputData.flat ? inputData.flat() : [].concat(...inputData);
      const input = tf.tensor3d(float32Array(flat), [1, 30, 12]);
      const out   = this._model.predict(input);
      const scores = Array.from(out.dataSync());
      input.dispose();
      out.dispose();
      return scores;
    } catch (err) {
      console.error('[NoviceInferenceBridge] Inference error:', err);
      if (tensor) tensor.dispose();
      return null;
    }
  },
};

function float32Array(arr) {
  const f = new Float32Array(arr.length);
  for (let i = 0; i < arr.length; i++) f[i] = arr[i];
  return f;
}

// Auto-load model as soon as TF.js is available
// TF.js is loaded synchronously via <script> before this file,
// so we can call loadModel immediately.
window.NoviceInferenceBridge.loadModel();
console.log('[NoviceInferenceBridge] Bridge registered on window');
