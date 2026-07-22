// Novice — CPR-AI Coach
// MediaPipe Pose bridge — @mediapipe/tasks-vision (PoseLandmarker)
//
// Migrated from the legacy @mediapipe/pose (0.5.x, UMD/global) bundle.
//
// Why: the legacy package keeps its WASM runtime behind a page-global
// `Module` singleton that is not cleanly released between instances —
// creating a second `new Pose()` in the same page (e.g. on watchdog
// recovery) collided with that global and produced the unrecoverable
// "Module.arguments has been replaced with plain arguments_" /
// "Aborted(Assertion failed)" native aborts. tasks-vision's PoseLandmarker
// encapsulates each instance's WASM/GPU resources properly —
// createFromOptions() -> close() -> createFromOptions() again is a
// supported pattern with no global collision — and most failures surface
// as catchable JS errors instead of native aborts.
//
// IMPORTANT: tasks-vision is ESM-only, so this file must be loaded as
//   <script type="module" src="flutter_pose_bridge.js"></script>
// (see web/index.html — module scripts are deferred by default, so the
// old `defer` attribute is no longer needed).
//
// Contract with Dart (unchanged from the legacy bridge, so
// pose_service_web.dart needs no changes):
//   window._novicePoseLandmarks   — array of 33 BlazePose landmarks
//                                    ({x, y, visibility}, same indices)
//   window._novicePoseTimestamp   — Date.now() at last successful detection
//   window._novicePoseVideoReady  — true once a real frame has been detected
//   window._novicePoseReady       — true once a real frame has been detected
//   window._novicePoseVideoWidth  — live <video> pixel width
//   window._novicePoseVideoHeight — live <video> pixel height
//   window._novicePoseFailed      — true once recovery attempts are exhausted
//   window._novicePoseGeneration  — bumped on every (re)init

window._novicePoseLandmarks   = null;
window._novicePoseTimestamp   = 0;
window._novicePoseVideoReady  = false;
window._novicePoseReady       = false;
window._novicePoseVideoWidth  = 0;
window._novicePoseVideoHeight = 0;
window._novicePoseFailed      = false;
window._novicePoseGeneration  = 0;

const TASKS_VISION_VERSION = '0.10.14';
const WASM_BASE_URL =
  `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@${TASKS_VISION_VERSION}/wasm`;
// Google-hosted model asset. Same CDN-reliance pattern already used for
// tfjs and the old pose.js bundle — the app is web-only/no-offline already
// (see README), so this doesn't introduce a new class of dependency. If
// you later want this self-hosted for reliability, drop the .task file in
// web/assets/models/ and point modelAssetPath at that instead.
const MODEL_ASSET_URL =
  'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task';

const REQUIRED_STABLE_FRAMES = 5;
const WATCHDOG_MS = 3000;
const MAX_RESTART_ATTEMPTS = 2;

// FIX vs. legacy bridge: this must be module-scoped, NOT declared inside
// findVideoAndStart(). In the old file it was re-declared as a local
// `let restartAttempts = 0` on every recovery reinit, so it reset to 0
// every time and MAX_RESTART_ATTEMPTS never actually capped anything —
// the graph would crash-loop forever, always logging "attempt 1/2" and
// never reaching the "giving up" branch. Keeping the counter here means a
// real session-level cap and a real _novicePoseFailed signal to Dart.
let restartAttempts = 0;

async function createLandmarker() {
  const { PoseLandmarker, FilesetResolver } = await import(
    `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@${TASKS_VISION_VERSION}`
  );
  const vision = await FilesetResolver.forVisionTasks(WASM_BASE_URL);

  try {
    return await PoseLandmarker.createFromOptions(vision, {
      baseOptions: { modelAssetPath: MODEL_ASSET_URL, delegate: 'GPU' },
      runningMode: 'VIDEO',
      numPoses: 1,
    });
  } catch (e) {
    // GPU delegate can fail on some driver/browser combos (and wants
    // cross-origin-isolation headers on some Chrome versions) — fall back
    // to CPU rather than leaving the bridge dead.
    console.warn('[NovicePose] GPU delegate failed, falling back to CPU:', e);
    return await PoseLandmarker.createFromOptions(vision, {
      baseOptions: { modelAssetPath: MODEL_ASSET_URL, delegate: 'CPU' },
      runningMode: 'VIDEO',
      numPoses: 1,
    });
  }
}

async function initPoseBridge() {
  const myGeneration = ++window._novicePoseGeneration;
  window._novicePoseReady = false;
  window._novicePoseLandmarks = null;

  let landmarker;
  try {
    landmarker = await createLandmarker();
  } catch (e) {
    console.error('[NovicePose] Failed to create PoseLandmarker:', e);
    window._novicePoseFailed = true;
    return;
  }

  if (myGeneration !== window._novicePoseGeneration) {
    // Superseded while loading — release this instance's WASM/GPU
    // resources immediately rather than leaking it, and don't start its
    // detect loop.
    try { landmarker.close(); } catch (_) {}
    return;
  }

  let watchdogTimer = null;
  function clearWatchdog() {
    if (watchdogTimer) { clearTimeout(watchdogTimer); watchdogTimer = null; }
  }

  function armWatchdog() {
    clearWatchdog();
    watchdogTimer = setTimeout(() => {
      if (myGeneration !== window._novicePoseGeneration) return;
      if (window._novicePoseReady) return; // got a result recently, fine

      // Stop advertising the last-good frame as current while we recover —
      // see pose_service_web.dart's staleness gate, which relies on
      // _novicePoseTimestamp aging out rather than on these flags alone,
      // but clearing them here still prevents a brief inconsistent state.
      window._novicePoseReady = false;
      window._novicePoseLandmarks = null;

      restartAttempts++;
      if (restartAttempts <= MAX_RESTART_ATTEMPTS) {
        console.warn(
          `[NovicePose] No results ${WATCHDOG_MS}ms after starting detection ` +
          `— reinitialising (attempt ${restartAttempts}/${MAX_RESTART_ATTEMPTS})…`
        );
        try { landmarker.close(); } catch (e) {
          console.warn('[NovicePose] close() failed during recovery:', e);
        }
        initPoseBridge();
      } else {
        try { landmarker.close(); } catch (_) {}
        window._novicePoseFailed = true;
        console.error(
          `[NovicePose] Still no results after ${MAX_RESTART_ATTEMPTS} reinit ` +
          `attempts — giving up. Live pose tracking unavailable this session.`
        );
      }
    }, WATCHDOG_MS);
  }

  // FIX (overlay tracking a completely different frame than what's on
  // screen): document.querySelector('video') silently returns the FIRST
  // <video> element in DOM order, with no regard for whether it's the one
  // actually rendering the live camera feed. Flutter web's camera plugin
  // can leave a stale/detached <video> element behind (0×0 bounding rect,
  // no longer attached to the visible render tree) alongside the real one
  // that's actively displaying frames — e.g. across a camera
  // reinitialisation. Landmarks computed against the wrong element don't
  // just look "off", they're relative to an entirely unrelated frame, which
  // is why no scale/crop transform on the Dart side could ever fix it.
  //
  // pickVisibleVideo() instead selects the <video> that is actually
  // rendering: playing, ready, with real pixel dimensions, AND with a
  // non-zero on-screen bounding rect (proof it's actually laid out/visible,
  // not a detached leftover). Among multiple candidates, the one with the
  // largest rendered area wins — the real preview is normally
  // full-screen-ish, while stale/hidden elements report 0×0.
  //
  // Called fresh every frame (not cached once) so a later camera
  // reinitialisation that creates a *new* <video> element is picked up
  // automatically instead of the bridge staying locked onto a now-stale
  // reference — cheap DOM query, and it's what actually prevents this bug
  // from silently recurring after a session restart.
  function pickVisibleVideo() {
    const candidates = Array.from(document.querySelectorAll('video'));
    let best = null;
    let bestArea = 0;
    for (const v of candidates) {
      if (v.paused || v.ended) continue;
      if (v.readyState < 2) continue;
      if (v.videoWidth <= 0 || v.videoHeight <= 0) continue;
      const rect = v.getBoundingClientRect();
      const area = rect.width * rect.height;
      if (area <= 0) continue; // detached/invisible — not a real candidate
      if (area > bestArea) {
        best = v;
        bestArea = area;
      }
    }
    return best;
  }

  function findVideoAndStart() {
    if (myGeneration !== window._novicePoseGeneration) return;

    const video = pickVisibleVideo();
    if (!video) {
      setTimeout(findVideoAndStart, 500);
      return;
    }

    let sendStarted = false;
    let stableFrames = 0;
    let lastW = 0, lastH = 0;

    function detectFrame() {
      if (myGeneration !== window._novicePoseGeneration) return; // superseded

      // Re-resolve the visible video every frame rather than trusting the
      // closed-over `video` reference for the whole session — see
      // pickVisibleVideo()'s comment above for why.
      const activeVideo = pickVisibleVideo() || video;

      if (
        !activeVideo.paused &&
        !activeVideo.ended &&
        activeVideo.readyState >= 2 &&
        activeVideo.videoWidth > 0 &&   // wait for real dimensions, same as before
        activeVideo.videoHeight > 0
      ) {
        if (!sendStarted) {
          if (activeVideo.videoWidth === lastW && activeVideo.videoHeight === lastH) {
            stableFrames++;
          } else {
            stableFrames = 0;
            lastW = activeVideo.videoWidth;
            lastH = activeVideo.videoHeight;
          }
          if (stableFrames < REQUIRED_STABLE_FRAMES) {
            requestAnimationFrame(detectFrame);
            return;
          }
          sendStarted = true;
          armWatchdog();
        }

        window._novicePoseVideoWidth  = activeVideo.videoWidth;
        window._novicePoseVideoHeight = activeVideo.videoHeight;

        try {
          const result = landmarker.detectForVideo(activeVideo, performance.now());
          if (myGeneration !== window._novicePoseGeneration) return;

          window._novicePoseVideoReady = true;
          window._novicePoseReady      = true;

          if (result.landmarks && result.landmarks[0]) {
            window._novicePoseLandmarks = result.landmarks[0];
            window._novicePoseTimestamp = Date.now();
          }
          // Re-arm on every successful detection so a stall LATER in the
          // session (not just at startup) is still caught — the legacy
          // bridge only ever armed the watchdog once, before the first
          // result, and never again for the rest of the session.
          armWatchdog();
        } catch (e) {
          // Catchable per-frame error. tasks-vision surfaces most failures
          // this way instead of a native abort, but the watchdog above is
          // still the backstop for anything that hangs silently instead.
          console.warn('[NovicePose] detectForVideo error:', e);
        }
      }
      requestAnimationFrame(detectFrame);
    }

    detectFrame();
    console.log('[NovicePose] tasks-vision bridge active — detecting frames');
  }

  findVideoAndStart();
}

// Exposed so Dart can request a clean slate when a new training session
// starts in the same tab (mirrors InferenceServiceWeb.resetSession() —
// see its comment on why per-session state can't just carry over silently).
// Not required for the crash/spam fixes above, but keeps the failure
// counter and generation from a previous participant's session bleeding
// into the next one during back-to-back field-study sessions.
window._noviceResetPoseBridge = function () {
  restartAttempts = 0;
  window._novicePoseFailed = false;
  initPoseBridge();
};

initPoseBridge();