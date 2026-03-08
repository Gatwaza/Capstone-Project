// web/src/services/inferenceService.js
// Loads the exported TensorFlow.js graph model and runs BiLSTM inference.
// Falls back gracefully (this.loaded === false) when the model file is absent —
// the app then runs in rule-based-only mode.

import * as tf from '@tensorflow/tfjs';
import '@tensorflow/tfjs-backend-webgl';
import { CONST } from '../utils/constants.js';

const MODEL_PATH = './assets/models/model.json';

export class InferenceService {
  constructor() {
    this._model = null;
    // Rolling 30-frame window: Array of 12-element feature arrays
    this._window = [];
  }

  /** True when a model has been loaded successfully. */
  get loaded() { return this._model !== null; }

  /**
   * Load the TFJS graph model.
   * Silently fails if the model file is not present.
   * @param {(progress: number) => void} onProgress  0–1
   */
  async load(onProgress) {
    try {
      await tf.setBackend('webgl');
      await tf.ready();
      onProgress?.(0.2);

      this._model = await tf.loadLayersModel(MODEL_PATH);
      onProgress?.(0.8);

      // Warm-up prediction to avoid first-inference latency
      const dummy = tf.zeros([1, CONST.WINDOW_FRAMES, 12]);
      const warmup = this._model.predict(dummy);
      warmup.dispose();
      dummy.dispose();

      onProgress?.(1);
      console.log(`[Inference] Model loaded. Backend: ${tf.getBackend()}`);
    } catch (err) {
      this._model = null;
      console.warn(
        '[Inference] Model not found — running in rule-based mode.\n' +
        'Train the model via the Colab notebook and place model.json in web/assets/models/',
        err.message
      );
    }
  }

  /**
   * Add a 12-dim feature frame to the rolling window and run inference
   * when the window is full (30 frames).
   *
   * @param {number[]} features  12-element array
   * @returns {{ label: string, confidence: number, probs: Object } | null}
   */
  run(features) {
    if (!this._model) return null;

    this._window.push(features);
    if (this._window.length > CONST.WINDOW_FRAMES) this._window.shift();
    if (this._window.length < CONST.WINDOW_FRAMES) return null;

    // Build tensor: shape [1, 30, 12]
    let result = null;
    const inputTensor = tf.tensor3d([this._window], [1, CONST.WINDOW_FRAMES, 12]);
    try {
      const outputTensor = this._model.predict(inputTensor);
      const probs = Array.from(outputTensor.dataSync());
      outputTensor.dispose();

      const maxIdx = probs.indexOf(Math.max(...probs));
      if (probs[maxIdx] >= CONST.CLASSIFIER_CONFIDENCE) {
        result = {
          label:      CONST.CLASS_LABELS[maxIdx],
          confidence: probs[maxIdx],
          probs:      Object.fromEntries(CONST.CLASS_LABELS.map((l, i) => [l, probs[i]])),
        };
      }
    } catch (err) {
      console.error('[Inference] Prediction error:', err);
    } finally {
      inputTensor.dispose();
    }
    return result;
  }

  /** Clear the rolling feature window (call at session start). */
  reset() { this._window = []; }
}
