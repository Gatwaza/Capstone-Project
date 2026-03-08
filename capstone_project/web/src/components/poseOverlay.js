// web/src/components/poseOverlay.js
// Draws MediaPipe pose landmarks and skeleton on an HTML5 Canvas element.
// Mirrors lib/widgets/pose_overlay.dart.

import { CONST } from '../utils/constants.js';
const { LM } = CONST;

// ── Connection pairs (landmark index pairs) ───────────────────────────────────
const CONNECTIONS = [
  [LM.LEFT_SHOULDER,  LM.RIGHT_SHOULDER],
  [LM.LEFT_SHOULDER,  LM.LEFT_ELBOW],
  [LM.LEFT_ELBOW,     LM.LEFT_WRIST],
  [LM.RIGHT_SHOULDER, LM.RIGHT_ELBOW],
  [LM.RIGHT_ELBOW,    LM.RIGHT_WRIST],
  [LM.LEFT_SHOULDER,  LM.LEFT_HIP],
  [LM.RIGHT_SHOULDER, LM.RIGHT_HIP],
  [LM.LEFT_HIP,       LM.RIGHT_HIP],
  [LM.LEFT_HIP,       LM.LEFT_KNEE],
  [LM.RIGHT_HIP,      LM.RIGHT_KNEE],
];

// Joints to highlight (wrists + elbows)
const HIGHLIGHT = new Set([
  LM.LEFT_WRIST, LM.RIGHT_WRIST,
  LM.LEFT_ELBOW, LM.RIGHT_ELBOW,
]);

// ── Colours ───────────────────────────────────────────────────────────────────
const LINE_COLOR    = 'rgba(255,255,255,0.75)';
const JOINT_COLOR   = 'rgba(255,255,255,0.9)';
const WRIST_COLOR   = '#E53935';
const WRIST_GLOW    = 'rgba(229,57,53,0.3)';

/**
 * Draw the skeleton onto a canvas element, mirroring the video horizontally.
 *
 * @param {HTMLCanvasElement} canvas
 * @param {HTMLVideoElement}  video   – used for sizing only
 * @param {Array|null}        landmarks – 33-element MediaPipe landmark array, or null
 */
export function drawPose(canvas, video, landmarks) {
  // Size canvas to match video display size
  canvas.width  = video.videoWidth  || video.clientWidth  || 640;
  canvas.height = video.videoHeight || video.clientHeight || 480;

  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  if (!landmarks) return;

  const w = canvas.width;
  const h = canvas.height;

  /**
   * Convert normalised [0,1] landmark to canvas pixel coords.
   * X is mirrored so the user sees themselves as in a mirror.
   */
  const toCanvas = (lm) => ({
    x: (1 - lm.x) * w,   // mirror X
    y: lm.y * h,
  });

  const MIN_VIS = 0.40;

  // ── Draw bone connections ─────────────────────────────────────────────────
  ctx.lineWidth   = 2.5;
  ctx.strokeStyle = LINE_COLOR;
  ctx.lineCap     = 'round';

  for (const [ia, ib] of CONNECTIONS) {
    const a = landmarks[ia], b = landmarks[ib];
    if (!a || !b) continue;
    if ((a.visibility ?? 1) < MIN_VIS || (b.visibility ?? 1) < MIN_VIS) continue;
    const pa = toCanvas(a), pb = toCanvas(b);
    ctx.beginPath();
    ctx.moveTo(pa.x, pa.y);
    ctx.lineTo(pb.x, pb.y);
    ctx.stroke();
  }

  // ── Draw joints ───────────────────────────────────────────────────────────
  landmarks.forEach((lm, idx) => {
    if (!lm || (lm.visibility ?? 1) < MIN_VIS) return;
    const { x, y } = toCanvas(lm);
    const isHighlight = HIGHLIGHT.has(idx);

    if (isHighlight) {
      // Glow ring
      ctx.beginPath();
      ctx.arc(x, y, 11, 0, Math.PI * 2);
      ctx.fillStyle = WRIST_GLOW;
      ctx.fill();
      // Filled circle
      ctx.beginPath();
      ctx.arc(x, y, 7, 0, Math.PI * 2);
      ctx.fillStyle = WRIST_COLOR;
      ctx.fill();
    } else {
      ctx.beginPath();
      ctx.arc(x, y, 4.5, 0, Math.PI * 2);
      ctx.fillStyle = JOINT_COLOR;
      ctx.fill();
    }
  });
}

/**
 * Draw a "no pose detected" indicator on the canvas.
 */
export function drawNoPose(canvas) {
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Dashed border to indicate searching
  ctx.strokeStyle = 'rgba(255,255,255,0.2)';
  ctx.lineWidth   = 2;
  ctx.setLineDash([10, 6]);
  const pad = 20;
  ctx.strokeRect(pad, pad, canvas.width - pad * 2, canvas.height - pad * 2);
  ctx.setLineDash([]);

  // Centred message
  ctx.fillStyle  = 'rgba(255,255,255,0.35)';
  ctx.font       = '14px -apple-system, sans-serif';
  ctx.textAlign  = 'center';
  ctx.fillText('Position yourself in frame', canvas.width / 2, canvas.height / 2);
}
