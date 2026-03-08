// web/src/services/poseService.js
// Wraps @mediapipe/pose + @mediapipe/camera_utils for browser pose estimation.
// Landmarks are delivered as a flat array of 33 {x, y, z, visibility} objects
// (normalised 0–1 image coordinates).

export class PoseService {
  constructor({ onResults }) {
    this._onResults = onResults;
    this._pose = null;
    this._camera = null;
    this._videoEl = null;
  }

  /**
   * Load MediaPipe Pose WASM model.
   * @param {(progress: number) => void} onProgress  0–1
   */
  async init(onProgress) {
    // Dynamically import to avoid blocking initial page load
    const { Pose } = await import('@mediapipe/pose');
    onProgress?.(0.1);

    this._pose = new Pose({
      locateFile: (file) =>
        `https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/${file}`,
    });

    this._pose.setOptions({
      modelComplexity: 1,           // 0=lite 1=full 2=heavy
      smoothLandmarks: true,
      enableSegmentation: false,    // Not needed — saves memory
      smoothSegmentation: false,
      minDetectionConfidence: 0.50,
      minTrackingConfidence: 0.50,
    });

    this._pose.onResults((results) => {
      // results.poseLandmarks is null when no person detected
      this._onResults(results.poseLandmarks ?? null);
    });

    onProgress?.(0.5);
    // Warm-up initialises the WASM binary (downloads ~8 MB on first load,
    // served from cache thereafter via the browser's HTTP cache)
    await this._pose.initialize();
    onProgress?.(1);
  }

  /**
   * Open the camera and begin streaming frames to the pose model.
   * @param {HTMLVideoElement} videoEl
   * @returns {boolean} true if camera started successfully
   */
  async startCamera(videoEl) {
    this._videoEl = videoEl;
    try {
      const { Camera } = await import('@mediapipe/camera_utils');
      this._camera = new Camera(videoEl, {
        onFrame: async () => {
          if (this._pose && videoEl.readyState >= 2) {
            await this._pose.send({ image: videoEl });
          }
        },
        width: 640,
        height: 480,
        facingMode: 'user',  // Front camera for self-monitoring
      });
      await this._camera.start();
      return true;
    } catch (err) {
      // Gracefully handle permission denied or no camera
      if (err.name === 'NotAllowedError') {
        console.warn('[PoseService] Camera permission denied');
      } else if (err.name === 'NotFoundError') {
        console.warn('[PoseService] No camera found');
      } else {
        console.error('[PoseService] Camera error:', err);
      }
      return false;
    }
  }

  /**
   * Stop camera stream and release resources.
   */
  stopCamera() {
    try {
      this._camera?.stop();
    } catch (_) { /* ignore */ }
    this._camera = null;
    // Pause and clear video src to release camera hardware
    if (this._videoEl) {
      this._videoEl.pause();
      if (this._videoEl.srcObject) {
        this._videoEl.srcObject.getTracks().forEach(t => t.stop());
        this._videoEl.srcObject = null;
      }
    }
  }

  /** Clean up the pose model (call on component unmount). */
  async dispose() {
    this.stopCamera();
    await this._pose?.close();
    this._pose = null;
  }
}
