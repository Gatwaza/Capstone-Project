// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:collection';
import 'dart:math' as math;

import '../../models/landmark_frame.dart';

/// Pure mathematical utilities for landmark geometry.
///
/// All calculations use normalized coordinate space (0.0–1.0) as output
/// by MediaPipe BlazePose. Angles are in degrees unless suffixed with Rad.
///
/// This file is intentionally free of Flutter / ML-Kit imports so it can
/// be unit-tested without device hardware.
class LandmarkMath {
  LandmarkMath._();

  // ── Vector primitives ────────────────────────────────────

  /// Euclidean distance between two 2D points.
  static double distance2d(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Dot product of two 2D vectors.
  static double dot2d(double ax, double ay, double bx, double by) =>
      ax * bx + ay * by;

  /// Magnitude of a 2D vector.
  static double magnitude2d(double x, double y) =>
      math.sqrt(x * x + y * y);

  // ── Joint angles ─────────────────────────────────────────

  /// Angle at joint B formed by segments A→B and B→C, in degrees [0, 180].
  ///
  /// Used for:
  ///   • Elbow angle: shoulder → elbow → wrist
  ///   • Spine angle: hip midpoint → shoulder midpoint → vertical reference
  static double jointAngleDeg(
    double ax, double ay,
    double bx, double by,
    double cx, double cy,
  ) {
    final v1x = ax - bx;
    final v1y = ay - by;
    final v2x = cx - bx;
    final v2y = cy - by;

    final d = dot2d(v1x, v1y, v2x, v2y);
    final m = magnitude2d(v1x, v1y) * magnitude2d(v2x, v2y);

    if (m < 1e-9) return 0.0;

    // Clamp to [-1, 1] to handle floating-point drift before acos
    final cosAngle = (d / m).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180.0 / math.pi;
  }

  // ── Spine verticality ────────────────────────────────────

  /// Angle between the torso midline and the vertical axis, in degrees.
  ///
  /// [shoulderMidX/Y]: midpoint of left and right shoulder
  /// [hipMidX/Y]:      midpoint of left and right hip
  ///
  /// Returns 0° when perfectly vertical (ideal for compressions).
  /// ERC 2021: rescuer body should be directly above hands (≤ 15° lean).
  static double spineVerticalityDeg(
    double shoulderMidX, double shoulderMidY,
    double hipMidX, double hipMidY,
  ) {
    // Torso vector (hip → shoulder, upward)
    final tx = shoulderMidX - hipMidX;
    final ty = shoulderMidY - hipMidY;

    // Vertical reference vector (straight up in image space = dy=-1)
    // Note: in normalized coordinates, Y increases downward, so vertical = (0, -1)
    const vx = 0.0;
    const vy = -1.0;

    final d = dot2d(tx, ty, vx, vy);
    final m = magnitude2d(tx, ty);

    if (m < 1e-9) return 0.0;
    final cosAngle = (d / m).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * 180.0 / math.pi;
  }

  // ── Wrist position utilities ─────────────────────────────

  /// Normalized vertical displacement of wrist from shoulder baseline.
  /// Used as a proxy for compression depth when depth sensor is unavailable.
  ///
  /// Returns value in [0, 1] where 1 = wrist at shoulder level (max displacement).
  static double normalizedWristDisplacement(
    double wristY,
    double shoulderY,
    double hipY,
  ) {
    final torsoHeight = (hipY - shoulderY).abs();
    if (torsoHeight < 1e-6) return 0.0;
    return ((wristY - shoulderY) / torsoHeight).clamp(0.0, 1.0);
  }

  /// Wrist Y velocity (pixels/frame or normalized/frame depending on input scale).
  /// Used for compression rate detection via peak finding.
  static double wristVelocity(double currentY, double previousY) =>
      currentY - previousY;

  // ── Hand placement assessment ────────────────────────────

  /// Determines whether wrist midpoint is at the sternum center.
  ///
  /// [wristMidY]: average Y of left+right wrist
  /// [shoulderMidY]: average Y of left+right shoulder
  /// [hipMidY]: average Y of left+right hip
  ///
  /// Returns a [HandPlacementResult] with qualitative assessment.
  ///
  /// Clinical reference: hands should be on the lower half of the sternum,
  /// roughly at the nipple line (ERC 2021 §3.3).
  ///
  /// TODO: Refine thresholds once pilot study calibration data is available.
  static HandPlacementResult assessHandPlacement(
    double wristMidY,
    double shoulderMidY,
    double hipMidY,
  ) {
    final torsoHeight = hipMidY - shoulderMidY;
    if (torsoHeight < 1e-6) return HandPlacementResult.unknown;

    // Normalized position: 0 = shoulders, 1 = hips
    final normPos = (wristMidY - shoulderMidY) / torsoHeight;

    // Ideal range: 45–65% down the torso (sternum lower half)
    if (normPos < 0.35) return HandPlacementResult.tooHigh;
    if (normPos > 0.75) return HandPlacementResult.tooLow;
    return HandPlacementResult.correct;
  }

  // ── Feature vector construction ──────────────────────────

  /// Builds the 12-dimensional feature vector for one frame.
  ///
  /// Output order matches ml_pipeline/src/data/extract_landmarks.py.
  /// Changing order here requires retraining the model.
  ///
  /// Parameters are normalized MediaPipe landmark coordinates.
  static List<double> buildFeatureVector({
    required double leftElbowAngle,
    required double rightElbowAngle,
    required double spineVerticality,
    required double wristY,
    required double wristVelocityY,
    required double wristAccelerationY,
    required double normalizedDepth,
    required double shoulderWidth,
    required double meanConfidence,
    required bool leftElbowVisible,
    required bool rightElbowVisible,
  }) {
    return [
      leftElbowAngle,                        // 0
      rightElbowAngle,                       // 1
      (leftElbowAngle + rightElbowAngle) / 2, // 2 — mean
      spineVerticality,                      // 3
      wristY,                                // 4
      wristVelocityY,                        // 5
      wristAccelerationY,                    // 6
      normalizedDepth,                       // 7
      shoulderWidth,                         // 8
      meanConfidence,                        // 9
      leftElbowVisible  ? 1.0 : 0.0,        // 10
      rightElbowVisible ? 1.0 : 0.0,        // 11
    ];
  }
}

/// Qualitative hand placement assessment.
enum HandPlacementResult {
  correct,
  tooHigh,
  tooLow,
  unknown,
}

// ── Causal feature extractor (train/live parity fix) ──────────────────────
//
// [LandmarkMath.buildFeatureVector] above is kept unchanged for backward
// compatibility (existing unit tests + any other callers depend on its
// signature). It is no longer what feeds the live model.
//
// This extractor replaces it. It mirrors
// ml_pipeline/CPR_Coach_Training.ipynb Stage 4's `extract_features_full()`
// AFTER the train/live feature-mismatch fix, feature-for-feature:
//
//   idx  training (Stage 4)                          live (here)
//   0-2  elbow angles, raw AlphaPose pixel coords     same formula, on
//                                                      MediaPipe coords
//                                                      converted to pixel
//                                                      space first (see
//                                                      [update])
//   3    spine lean, degrees(atan2(|dx|,|dy|+eps))    identical formula
//   4    wristY_px / shoulderWidth_px (ratio)          identical formula
//   5    causal backward diff of the ratio             identical formula
//   6    causal backward diff of #5                    identical formula
//   7    abs(ratio - ROLLING 60-frame mean)             identical formula
//   8    shoulder width, pixel space (MIN_SHOULDER_PX   identical formula
//        floor guards near-zero degenerate frames)
//   9    real per-joint confidence mean (upper body)     frame.meanLandmarkConfidence
//                                                         (already the same
//                                                         6-joint mean)
//   10-11 left/right elbow confidence < 0.3              frame.leftElbowVisibility /
//                                                         rightElbowVisibility < 0.3
//
// Construct ONE instance per session (or per continuous recording) and
// feed frames in capture order via [update] — the rolling window and
// backward-difference state are only meaningful across a single
// continuous stream. Do not reuse an instance across sessions; call
// [reset] instead if you must.
class CprCausalFeatureExtractor {
  CprCausalFeatureExtractor({this.rollingWindow = 60});

  /// Rolling-window length (frames) for the amplitude-deviation feature
  /// (index 7). Should match the model's temporal window (SEQ_LEN=60 in
  /// the notebook / AppConstants.temporalWindowFrames in the app) so a
  /// live inference call and a training window see the same amount of
  /// "recent history" when computing the deviation.
  final int rollingWindow;

  /// Degenerate-frame guard for shoulder width, mirrors
  /// `MIN_SHOULDER_PX` in the notebook's Stage 4 cell. Real shoulder
  /// widths at typical rescuer-to-camera distance run well into the tens
  /// of pixels at minimum; anything below this indicates a failed
  /// detection for that frame, not a genuinely close camera.
  static const double _minShoulderPx = 5.0;

  /// Must match the notebook's Stage 4 literal threshold exactly
  /// (`conf[...] < 0.3`) — this is a fixed model-input convention, not a
  /// UI/UX tunable, so it intentionally does NOT reuse
  /// AppConstants.minLandmarkVisibility (0.5), which serves a different
  /// purpose (excluding a frame's *display* rather than a training label).
  static const double _lowConfidenceThreshold = 0.3;

  final ListQueue<double> _ratioHistory = ListQueue<double>();
  double? _prevRatio;
  double? _prevVelocity;

  /// Builds the causal 12-D feature vector for one frame.
  ///
  /// [frame] supplies MediaPipe's normalized (0.0–1.0 per axis) landmark
  /// coordinates, unchanged. [videoWidthPx]/[videoHeightPx] are the
  /// source video's real pixel dimensions (from the JS bridge's
  /// `_novicePoseVideoWidth`/`_novicePoseVideoHeight`) — required to
  /// undo MediaPipe's per-axis normalization before running angle/ratio
  /// formulas that assume square-pixel geometry, exactly as the training
  /// data (raw AlphaPose pixel coordinates) does.
  List<double> update(
    LandmarkFrame frame, {
    required double videoWidthPx,
    required double videoHeightPx,
  }) {
    double px(double normX) => normX * videoWidthPx;
    double py(double normY) => normY * videoHeightPx;

    final lsx = px(frame.leftShoulderX),  lsy = py(frame.leftShoulderY);
    final rsx = px(frame.rightShoulderX), rsy = py(frame.rightShoulderY);
    final lex = px(frame.leftElbowX),     ley = py(frame.leftElbowY);
    final rex = px(frame.rightElbowX),    rey = py(frame.rightElbowY);
    final lwx = px(frame.leftWristX),     lwy = py(frame.leftWristY);
    final rwx = px(frame.rightWristX),    rwy = py(frame.rightWristY);
    final lhx = px(frame.leftHipX),       lhy = py(frame.leftHipY);
    final rhx = px(frame.rightHipX),      rhy = py(frame.rightHipY);

    // idx 0-2: elbow angles, pixel space (matches Stage 4's angle_deg).
    final leftElbowAngle  = LandmarkMath.jointAngleDeg(lsx, lsy, lex, ley, lwx, lwy);
    final rightElbowAngle = LandmarkMath.jointAngleDeg(rsx, rsy, rex, rey, rwx, rwy);
    final meanElbowAngle  = (leftElbowAngle + rightElbowAngle) / 2;

    // idx 3: spine lean — degrees(atan2(|dx|, |dy| + eps)), matches
    // Stage 4 exactly (deliberately NOT LandmarkMath.spineVerticalityDeg,
    // which uses a different formula and would reintroduce a mismatch).
    final midSx = (lsx + rsx) / 2, midSy = (lsy + rsy) / 2;
    final midHx = (lhx + rhx) / 2, midHy = (lhy + rhy) / 2;
    final dx = (midHx - midSx).abs();
    final dy = (midHy - midSy).abs();
    final spineLean = math.atan2(dx, dy + 1e-8) * 180.0 / math.pi;

    // idx 8: shoulder width, pixel space, with degenerate-frame floor.
    final rawShoulderWidth = LandmarkMath.distance2d(lsx, lsy, rsx, rsy);
    final shoulderWidthPx =
        rawShoulderWidth < _minShoulderPx ? _minShoulderPx : rawShoulderWidth;

    // idx 4: wrist/shoulder-width ratio.
    final wristMidYPx = (lwy + rwy) / 2;
    final ratio = wristMidYPx / shoulderWidthPx;

    // idx 5, 6: causal backward difference — per-frame (not per-second),
    // matching pose_service_web.dart's existing wristVelocityY convention.
    final velocity = _prevRatio == null ? 0.0 : ratio - _prevRatio!;
    final acceleration = _prevVelocity == null ? 0.0 : velocity - _prevVelocity!;
    _prevRatio = ratio;
    _prevVelocity = velocity;

    // idx 7: causal rolling-window amplitude deviation (replaces the
    // notebook's old whole-video mean, which live inference can never
    // know ahead of time).
    _ratioHistory.addLast(ratio);
    while (_ratioHistory.length > rollingWindow) {
      _ratioHistory.removeFirst();
    }
    final rollingMean =
        _ratioHistory.reduce((a, b) => a + b) / _ratioHistory.length;
    final wristAmp = (ratio - rollingMean).abs();

    // idx 9-11: real confidence — frame.meanLandmarkConfidence is already
    // the mean of exactly the same 6 upper-body joints
    // (shoulders+elbows+wrists) as Stage 4's `conf[t, upper_joints].mean()`.
    // TEMP DEBUG — remove after diagnosing recoil bias
// ignore: avoid_print
    return [
      leftElbowAngle,
      rightElbowAngle,
      meanElbowAngle,
      spineLean,
      ratio,
      velocity,
      acceleration,
      wristAmp,
      shoulderWidthPx,
      frame.meanLandmarkConfidence,
      frame.leftElbowVisibility  < _lowConfidenceThreshold ? 1.0 : 0.0,
      frame.rightElbowVisibility < _lowConfidenceThreshold ? 1.0 : 0.0,
    ];
  }

  /// Clears rolling-window and finite-difference state. Call this when
  /// starting a new session with a reused extractor instance (normally
  /// unnecessary — prefer constructing a fresh instance per session).
  void reset() {
    _ratioHistory.clear();
    _prevRatio = null;
    _prevVelocity = null;
  }
}