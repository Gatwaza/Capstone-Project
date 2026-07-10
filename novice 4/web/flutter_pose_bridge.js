// Novice — CPR-AI Coach
// MediaPipe Pose bridge — BlazePose via CDN global (not ES module import)

window._novicePoseLandmarks  = null;
window._novicePoseTimestamp  = 0;
// FIX: readiness flags read by Dart (PoseServiceWeb + TrainingScreen poller).
// Set to true only after the first onResults with valid video dimensions.
window._novicePoseVideoReady = false;
window._novicePoseReady      = false;

// FIX (train/live feature-mismatch, root-cause table idx 0-3, 8): MediaPipe
// landmarks are normalized PER AXIS (x = px/videoWidth, y = px/videoHeight
// independently), which distorts angle and ratio calculations whenever the
// video isn't square -- the training model was built on raw AlphaPose pixel
// coordinates, where aspect ratio is preserved automatically. Exposing the
// live video's real pixel dimensions here lets Dart convert normalized
// landmarks back to pixel space (x*width, y*height) before running the same
// geometry formulas the notebook uses, instead of feeding it
// aspect-distorted values. See CprCausalFeatureExtractor in
// lib/core/utils/landmark_math.dart.
window._novicePoseVideoWidth  = 0;
window._novicePoseVideoHeight = 0;

// Bumped on every initPoseBridge() call (fresh Pose instance). A running
// sendFrame() loop from a previous (possibly crashed) instance checks this
// and stops rescheduling itself once it's stale, instead of running two
// concurrent send loops against the same video element after a recovery
// reinit.
window._novicePoseGeneration = 0;

function initPoseBridge() {
  // Use the global Pose already available from CDN script tag
  if (typeof Pose === 'undefined') {
    console.warn('[NovicePose] Pose not loaded yet, retrying...');
    setTimeout(initPoseBridge, 300);
    return;
  }

  const myGeneration = ++window._novicePoseGeneration;

  const pose = new Pose({
    locateFile: (file) =>
      `https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/${file}`,
  });

  pose.setOptions({
    modelComplexity: 1,
    smoothLandmarks: true,
    enableSegmentation: false,
    minDetectionConfidence: 0.5,
    minTrackingConfidence: 0.5,
  });

  let watchdogTimer = null;
  function clearWatchdog() {
    if (watchdogTimer) {
      clearTimeout(watchdogTimer);
      watchdogTimer = null;
    }
  }

  pose.onResults((results) => {
    if (myGeneration !== window._novicePoseGeneration) return; // stale instance
    clearWatchdog();

    // FIX: Signal Dart that MediaPipe has successfully processed a real frame.
    // This is set here — inside onResults — because onResults is only called
    // after pose.send() completes without crashing, which means the video
    // element had non-zero dimensions at send time. Dart polls these flags
    // before starting the landmark read loop.
    window._novicePoseVideoReady = true;
    window._novicePoseReady      = true;

    if (results.poseLandmarks) {
      window._novicePoseLandmarks = results.poseLandmarks;
      window._novicePoseTimestamp = Date.now();
    }
  });

  function findVideoAndStart() {
    if (myGeneration !== window._novicePoseGeneration) return; // stale instance

    const video = document.querySelector('video');
    if (!video) {
      setTimeout(findVideoAndStart, 500);
      return;
    }

    // ── Settle + auto-recovery for a known local-GPU MediaPipe crash ─────
    // On some local GPU/driver combinations (seen with Chrome+WebGL on
    // certain machines, not reproduced on the hosted production pipeline),
    // the very first pose.send() call — right as the WebGL context is
    // created — can hit a FATAL MediaPipe check failure ("roi->width > 0
    // && roi->height > 0" inside ImageToTensorCalculator), which aborts
    // the WASM graph. This is an unrecoverable native abort(), not a
    // catchable JS exception, so the try/catch below only handles
    // ordinary single-frame errors — it can't save an already-aborted
    // graph. Two mitigations instead:
    //   1. Require several consecutive frames of STABLE, non-zero video
    //      dimensions before the very first send (not just one check) —
    //      the crash appears tied to sending while the camera stream's
    //      reported size is still settling right after WebGL init.
    //   2. A watchdog: if onResults hasn't fired within 3s of starting to
    //      send frames, assume the graph died and transparently
    //      reinitialise (up to 2 attempts) rather than leaving the
    //      session silently stuck with no pose data.
    const REQUIRED_STABLE_FRAMES = 5;
    const WATCHDOG_MS = 3000;
    const MAX_RESTART_ATTEMPTS = 2;
    let restartAttempts = 0;
    let sendStarted = false;
    let stableFrames = 0;
    let lastW = 0, lastH = 0;

    function armWatchdog() {
      clearWatchdog();
      watchdogTimer = setTimeout(() => {
        if (myGeneration !== window._novicePoseGeneration) return;
        if (window._novicePoseReady) return; // already got results, fine
        restartAttempts++;
        if (restartAttempts <= MAX_RESTART_ATTEMPTS) {
          console.warn(
            `[NovicePose] No results ${WATCHDOG_MS}ms after sending frames ` +
            `— pose graph likely crashed. Reinitialising (attempt ${restartAttempts}/${MAX_RESTART_ATTEMPTS})…`
          );
          initPoseBridge(); // fresh Pose instance; this loop self-retires below
        } else {
          console.error(
            `[NovicePose] Still no results after ${MAX_RESTART_ATTEMPTS} reinit ` +
            `attempts — giving up. Live pose tracking unavailable this session.`
          );
        }
      }, WATCHDOG_MS);
    }

    async function sendFrame() {
      if (myGeneration !== window._novicePoseGeneration) return; // superseded

      try {
        // FIX: Guard on videoWidth/videoHeight in addition to readyState.
        // readyState >= 2 (HAVE_CURRENT_DATA) does NOT guarantee non-zero
        // dimensions on Chrome+WebGL — the browser can report current data
        // before the GPU has decoded the first frame dimensions. Sending a
        // zero-dimension frame into MediaPipe's ImageToTensorCalculator
        // triggers the same fatal RET_CHECK described above.
        if (
          !video.paused &&
          !video.ended &&
          video.readyState >= 2 &&
          video.videoWidth > 0 &&    // ← key fix: wait for real dimensions
          video.videoHeight > 0      // ← key fix
        ) {
          if (!sendStarted) {
            if (video.videoWidth === lastW && video.videoHeight === lastH) {
              stableFrames++;
            } else {
              stableFrames = 0;
              lastW = video.videoWidth;
              lastH = video.videoHeight;
            }
            if (stableFrames < REQUIRED_STABLE_FRAMES) {
              requestAnimationFrame(sendFrame);
              return;
            }
            sendStarted = true;
            armWatchdog();
          }

          // Keep the pixel-dimension globals current every frame -- cheap
          // (two int reads) and avoids any race with camera resolution
          // changing mid-session (e.g. device rotation, permission re-grant).
          window._novicePoseVideoWidth  = video.videoWidth;
          window._novicePoseVideoHeight = video.videoHeight;
          await pose.send({ image: video });
        }
      } catch (e) {
        // Ordinary catchable single-frame errors only — see note above on
        // why the fatal graph abort can't be caught here.
      }
      requestAnimationFrame(sendFrame);
    }

    sendFrame();
    console.log('[NovicePose] MediaPipe bridge active — sending frames');
  }

  findVideoAndStart();
}

// Also load the MediaPipe script explicitly so we control the version
const script = document.createElement('script');
script.src = 'https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/pose.js';
script.crossOrigin = 'anonymous';
script.onload = initPoseBridge;
script.onerror = () => console.error('[NovicePose] Failed to load MediaPipe');
document.head.appendChild(script);