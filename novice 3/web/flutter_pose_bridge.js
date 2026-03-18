/**
 * Novice — CPR-AI Coach
 * GNU General Public License v3.0
 * Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
 *
 * flutter_pose_bridge.js
 * ──────────────────────
 * Initialises MediaPipe Pose in the browser and exposes results to
 * Flutter Web via window.NovicePoseBridge.
 *
 * Loaded by web/index.html BEFORE Flutter's flutter_bootstrap.js.
 * Flutter's PoseServiceWeb reads from this bridge via dart:js interop.
 *
 * Architecture:
 *   Camera (getUserMedia)
 *     ↓
 *   MediaPipe Pose WASM  (loaded via CDN in index.html)
 *     ↓
 *   window.NovicePoseBridge.latestFrame  (written here)
 *     ↓
 *   Flutter: PoseServiceWeb._getLatestFrame()  (dart:js interop)
 *
 * Phase 1 status: bridge is initialised but Flutter reads it only when
 * PoseServiceWeb detects _isPoseReady() === true. The Flutter app
 * currently falls through to demo/simulation mode until the camera
 * is streaming and landmarks are arriving.
 */

window.NovicePoseBridge = {
  _ready: false,
  _latestFrame: null,
  _pose: null,
  _videoElement: null,

  isReady() {
    return this._ready && this._latestFrame !== null;
  },

  getLatestFrame() {
    return this._latestFrame;
  },

  async init(videoElement) {
    if (typeof Pose === 'undefined') {
      console.warn('[NovicePoseBridge] MediaPipe Pose not loaded yet.');
      return;
    }

    this._videoElement = videoElement;

    this._pose = new Pose({
      locateFile: (file) =>
        `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`,
    });

    this._pose.setOptions({
      modelComplexity:        2,
      smoothLandmarks:        true,
      enableSegmentation:     false,
      minDetectionConfidence: 0.5,
      minTrackingConfidence:  0.5,
    });

    this._pose.onResults((results) => {
      if (!results.poseLandmarks) return;

      // Write to shared JS object — Flutter reads via _getLatestFrame()
      window.NovicePoseBridge._latestFrame = {
        landmarks: results.poseLandmarks.map(lm => ({
          x:          lm.x,
          y:          lm.y,
          z:          lm.z,
          visibility: lm.visibility ?? 1.0,
        })),
        timestamp: Date.now(),
      };

      if (!window.NovicePoseBridge._ready) {
        window.NovicePoseBridge._ready = true;
        console.log('[NovicePoseBridge] First frame received — bridge active');
      }
    });

    await this._pose.initialize();
    console.log('[NovicePoseBridge] MediaPipe Pose initialised');
  },

  async sendFrame(videoElement) {
    if (!this._pose) return;
    await this._pose.send({ image: videoElement ?? this._videoElement });
  },
};

console.log('[NovicePoseBridge] Bridge registered on window');
