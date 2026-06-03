// Novice — CPR-AI Coach
// MediaPipe Pose bridge — BlazePose via CDN global (not ES module import)

window._novicePoseLandmarks  = null;
window._novicePoseTimestamp  = 0;
// FIX: readiness flags read by Dart (PoseServiceWeb + TrainingScreen poller).
// Set to true only after the first onResults with valid video dimensions.
window._novicePoseVideoReady = false;
window._novicePoseReady      = false;

function initPoseBridge() {
  // Use the global Pose already available from CDN script tag
  if (typeof Pose === 'undefined') {
    console.warn('[NovicePose] Pose not loaded yet, retrying...');
    setTimeout(initPoseBridge, 300);
    return;
  }

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

  pose.onResults((results) => {
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
    const video = document.querySelector('video');
    if (!video) {
      setTimeout(findVideoAndStart, 500);
      return;
    }

    async function sendFrame() {
      try {
        // FIX: Guard on videoWidth/videoHeight in addition to readyState.
        // readyState >= 2 (HAVE_CURRENT_DATA) does NOT guarantee non-zero
        // dimensions on Chrome+WebGL — the browser can report current data
        // before the GPU has decoded the first frame dimensions. Sending a
        // zero-dimension frame into MediaPipe's ImageToTensorCalculator
        // triggers a fatal RET_CHECK: "roi->width > 0 && roi->height > 0".
        if (
          !video.paused &&
          !video.ended &&
          video.readyState >= 2 &&
          video.videoWidth > 0 &&    // ← key fix: wait for real dimensions
          video.videoHeight > 0      // ← key fix
        ) {
          await pose.send({ image: video });
        }
      } catch (e) {
        // ignore single-frame errors
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