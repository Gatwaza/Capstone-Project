// Novice — CPR-AI Coach
// MediaPipe Pose bridge — runs BlazePose in the browser and exposes
// landmarks to Flutter via window._novicePoseLandmarks

window._novicePoseLandmarks = null;
window._novicePoseTimestamp = 0;

async function initPoseBridge() {
  const { Pose } = await import(
    'https://cdn.jsdelivr.net/npm/@mediapipe/pose@0.5.1675469404/pose.js'
  );

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
    if (results.poseLandmarks) {
      window._novicePoseLandmarks = results.poseLandmarks;
      window._novicePoseTimestamp = Date.now();
    }
  });

  // Connect to the camera stream Flutter already opened
  const video = document.querySelector('video');
  if (!video) {
    // Retry until Flutter's CameraPreview renders the <video> element
    setTimeout(initPoseBridge, 500);
    return;
  }

  async function sendFrame() {
    if (!video.paused && !video.ended && video.readyState >= 2) {
      await pose.send({ image: video });
    }
    requestAnimationFrame(sendFrame);
  }
  sendFrame();
  console.log('[NovicePose] MediaPipe bridge active');
}

initPoseBridge();