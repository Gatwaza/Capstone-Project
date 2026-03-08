// web/src/utils/landmarkMath.js
// Port of lib/core/utils/landmark_math.dart
// MediaPipe Web returns landmarks as an array of {x, y, z, visibility} objects.

import { CONST } from './constants.js';
const { LM } = CONST;

// ── Geometry helpers ──────────────────────────────────────────────────────────

/**
 * Angle in degrees at joint B, formed by vectors B→A and B→C.
 */
export function angleDegrees(a, b, c) {
  const baX = a.x - b.x, baY = a.y - b.y;
  const bcX = c.x - b.x, bcY = c.y - b.y;
  const dot = baX * bcX + baY * bcY;
  const magBA = Math.sqrt(baX ** 2 + baY ** 2);
  const magBC = Math.sqrt(bcX ** 2 + bcY ** 2);
  const cosA = Math.max(-1, Math.min(1, dot / (magBA * magBC + 1e-8)));
  return Math.acos(cosA) * 180 / Math.PI;
}

/**
 * Check a single landmark has sufficient visibility.
 */
function vis(lm, idx, threshold = CONST.LANDMARK_MIN_VISIBILITY) {
  return lm[idx] && (lm[idx].visibility ?? 1) >= threshold;
}

// ── Elbow angles ──────────────────────────────────────────────────────────────

export function leftElbowAngle(lm) {
  if (!vis(lm, LM.LEFT_SHOULDER) || !vis(lm, LM.LEFT_ELBOW) || !vis(lm, LM.LEFT_WRIST)) return null;
  return angleDegrees(lm[LM.LEFT_SHOULDER], lm[LM.LEFT_ELBOW], lm[LM.LEFT_WRIST]);
}

export function rightElbowAngle(lm) {
  if (!vis(lm, LM.RIGHT_SHOULDER) || !vis(lm, LM.RIGHT_ELBOW) || !vis(lm, LM.RIGHT_WRIST)) return null;
  return angleDegrees(lm[LM.RIGHT_SHOULDER], lm[LM.RIGHT_ELBOW], lm[LM.RIGHT_WRIST]);
}

export function meanElbowAngle(lm) {
  const l = leftElbowAngle(lm), r = rightElbowAngle(lm);
  if (l == null && r == null) return null;
  if (l == null) return r;
  if (r == null) return l;
  return (l + r) / 2;
}

export function elbowsLocked(lm, threshold = 155) {
  const l = leftElbowAngle(lm), r = rightElbowAngle(lm);
  if (l != null && l < threshold) return false;
  if (r != null && r < threshold) return false;
  return true;
}

// ── Spine verticality ─────────────────────────────────────────────────────────

/**
 * Returns lean angle from vertical in degrees.
 * 0° = perfect posture. Values > 25° trigger the posture cue.
 */
export function spineVerticality(lm) {
  if (!vis(lm, LM.LEFT_SHOULDER) || !vis(lm, LM.RIGHT_SHOULDER) ||
      !vis(lm, LM.LEFT_HIP)      || !vis(lm, LM.RIGHT_HIP)) return null;
  const shoulderMidX = (lm[LM.LEFT_SHOULDER].x + lm[LM.RIGHT_SHOULDER].x) / 2;
  const shoulderMidY = (lm[LM.LEFT_SHOULDER].y + lm[LM.RIGHT_SHOULDER].y) / 2;
  const hipMidX = (lm[LM.LEFT_HIP].x + lm[LM.RIGHT_HIP].x) / 2;
  const hipMidY = (lm[LM.LEFT_HIP].y + lm[LM.RIGHT_HIP].y) / 2;
  const dx = shoulderMidX - hipMidX;
  const dy = shoulderMidY - hipMidY;
  return Math.atan2(Math.abs(dx), Math.abs(dy) + 1e-8) * 180 / Math.PI;
}

// ── Wrist Y (normalised, 0–1) ─────────────────────────────────────────────────

export function meanWristY(lm) {
  const lw = vis(lm, LM.LEFT_WRIST)  ? lm[LM.LEFT_WRIST].y  : null;
  const rw = vis(lm, LM.RIGHT_WRIST) ? lm[LM.RIGHT_WRIST].y : null;
  if (lw == null && rw == null) return null;
  if (lw == null) return rw;
  if (rw == null) return lw;
  return (lw + rw) / 2;
}

// ── Shoulder width (normalised) ───────────────────────────────────────────────

export function shoulderWidth(lm) {
  if (!vis(lm, LM.LEFT_SHOULDER) || !vis(lm, LM.RIGHT_SHOULDER)) return null;
  const dx = lm[LM.LEFT_SHOULDER].x - lm[LM.RIGHT_SHOULDER].x;
  const dy = lm[LM.LEFT_SHOULDER].y - lm[LM.RIGHT_SHOULDER].y;
  return Math.sqrt(dx ** 2 + dy ** 2);
}

// ── Has sufficient visibility for processing ───────────────────────────────────

export function hasSufficientLandmarks(lm) {
  const required = [
    LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER,
    LM.LEFT_ELBOW,    LM.RIGHT_ELBOW,
    LM.LEFT_WRIST,    LM.RIGHT_WRIST,
  ];
  return required.every(idx => vis(lm, idx));
}

// ── 12-dim feature vector for BiLSTM ─────────────────────────────────────────

function norm(v, lo, hi) {
  return Math.max(0, Math.min(1, (v - lo) / (hi - lo + 1e-8)));
}

/**
 * Returns a 12-element Float32Array or null if insufficient landmarks.
 *
 * Features (same order as training pipeline):
 *  0: left  elbow angle (norm)
 *  1: right elbow angle (norm)
 *  2: mean  elbow angle (norm)
 *  3: spine verticality (norm)
 *  4: mean  wrist Y (raw normalised image coord)
 *  5: wrist Y velocity (clamped ±1)
 *  6: wrist Y acceleration (clamped ±1)
 *  7: compression depth proxy (clamped 0–1)
 *  8: shoulder width (norm)
 *  9: mean landmark visibility
 * 10: left  wrist visible flag
 * 11: right wrist visible flag
 */
export function featureVector(lm, { prevWristY, prevVelY, baselineWristY, refShoulderWidth }) {
  const elbL = leftElbowAngle(lm);
  const elbR = rightElbowAngle(lm);
  const wristY = meanWristY(lm);
  const sw = shoulderWidth(lm);

  if ((elbL == null && elbR == null) || wristY == null || sw == null) return null;

  const elbMean = elbL != null && elbR != null ? (elbL + elbR) / 2 : (elbL ?? elbR);
  const spine = spineVerticality(lm) ?? 0;
  const velY = wristY - prevWristY;
  const accY = velY - prevVelY;
  const depth = Math.min(1, Math.abs(wristY - baselineWristY) / (refShoulderWidth + 1e-8));

  const visScores = [
    LM.LEFT_SHOULDER, LM.RIGHT_SHOULDER,
    LM.LEFT_ELBOW, LM.RIGHT_ELBOW,
    LM.LEFT_WRIST, LM.RIGHT_WRIST,
  ].map(i => lm[i]?.visibility ?? 0);
  const meanVis = visScores.reduce((a, b) => a + b, 0) / visScores.length;

  return [
    norm(elbL  ?? elbMean, 0, 180),  // 0
    norm(elbR  ?? elbMean, 0, 180),  // 1
    norm(elbMean,          0, 180),  // 2
    norm(spine,            0,  90),  // 3
    wristY,                          // 4
    Math.max(-1, Math.min(1, velY)), // 5
    Math.max(-1, Math.min(1, accY)),// 6
    depth,                           // 7
    norm(sw, 0.05, 0.6),             // 8
    meanVis,                         // 9
    vis(lm, LM.LEFT_WRIST)  ? 1 : 0,// 10
    vis(lm, LM.RIGHT_WRIST) ? 1 : 0,// 11
  ];
}

// ── BPM via peak detection ─────────────────────────────────────────────────────

/**
 * Mirrors LandmarkMath.estimateBpm in Dart.
 * Detects peaks in wristYBuffer (wrist moves DOWN = compression).
 * Returns BPM or null.
 */
export function estimateBpm(wristYBuffer, fps = 25, minDistance = CONST.PEAK_MIN_DISTANCE) {
  if (wristYBuffer.length < minDistance * 2) return null;
  const peaks = [];
  for (let i = minDistance; i < wristYBuffer.length - minDistance; i++) {
    let isPeak = true;
    for (let j = i - minDistance; j < i; j++) {
      if (wristYBuffer[j] >= wristYBuffer[i]) { isPeak = false; break; }
    }
    if (!isPeak) continue;
    for (let j = i + 1; j <= i + minDistance; j++) {
      if (wristYBuffer[j] >= wristYBuffer[i]) { isPeak = false; break; }
    }
    if (isPeak && (peaks.length === 0 || i - peaks[peaks.length - 1] >= minDistance)) {
      peaks.push(i);
    }
  }
  if (peaks.length < 2) return null;
  const intervals = [];
  for (let i = 1; i < peaks.length; i++) intervals.push(peaks[i] - peaks[i - 1]);
  const meanInterval = intervals.reduce((a, b) => a + b, 0) / intervals.length;
  return meanInterval > 0 ? (fps * 60) / meanInterval : null;
}
