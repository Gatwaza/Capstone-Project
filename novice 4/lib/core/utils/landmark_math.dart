// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:math' as math;

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
