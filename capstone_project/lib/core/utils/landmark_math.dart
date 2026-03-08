import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class LandmarkMath {
  LandmarkMath._();

  /// Angle in degrees at joint [b] formed by vectors b→a and b→c
  static double angleDegrees(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final baX = a.x - b.x, baY = a.y - b.y;
    final bcX = c.x - b.x, bcY = c.y - b.y;
    final dot = baX * bcX + baY * bcY;
    final magBA = math.sqrt(baX * baX + baY * baY);
    final magBC = math.sqrt(bcX * bcX + bcY * bcY);
    final cos = dot / (magBA * magBC + 1e-8);
    return math.acos(cos.clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  static double distance2D(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x, dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double? leftElbowAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final le = lm[PoseLandmarkType.leftElbow];
    final lw = lm[PoseLandmarkType.leftWrist];
    if (ls == null || le == null || lw == null) return null;
    if (ls.likelihood < 0.55 || le.likelihood < 0.55 || lw.likelihood < 0.55) return null;
    return angleDegrees(ls, le, lw);
  }

  static double? rightElbowAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final rs = lm[PoseLandmarkType.rightShoulder];
    final re = lm[PoseLandmarkType.rightElbow];
    final rw = lm[PoseLandmarkType.rightWrist];
    if (rs == null || re == null || rw == null) return null;
    if (rs.likelihood < 0.55 || re.likelihood < 0.55 || rw.likelihood < 0.55) return null;
    return angleDegrees(rs, re, rw);
  }

  static double? meanElbowAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final l = leftElbowAngle(lm), r = rightElbowAngle(lm);
    if (l == null && r == null) return null;
    if (l == null) return r;
    if (r == null) return l;
    return (l + r) / 2;
  }

  static bool elbowsLocked(Map<PoseLandmarkType, PoseLandmark> lm, {double threshold = 155}) {
    final l = leftElbowAngle(lm), r = rightElbowAngle(lm);
    if (l != null && l < threshold) return false;
    if (r != null && r < threshold) return false;
    return true;
  }

  /// Spine lean angle from vertical (0° = perfect vertical posture)
  static double? spineVerticality(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];
    final lh = lm[PoseLandmarkType.leftHip];
    final rh = lm[PoseLandmarkType.rightHip];
    if (ls == null || rs == null || lh == null || rh == null) return null;
    final shoulderMidX = (ls.x + rs.x) / 2, shoulderMidY = (ls.y + rs.y) / 2;
    final hipMidX = (lh.x + rh.x) / 2, hipMidY = (lh.y + rh.y) / 2;
    final dx = shoulderMidX - hipMidX, dy = shoulderMidY - hipMidY;
    return math.atan2(dx.abs(), dy.abs() + 1e-8) * 180 / math.pi;
  }

  /// Mean wrist Y in normalised image coords (0–1)
  static double? meanWristY(Map<PoseLandmarkType, PoseLandmark> lm) {
    final lw = lm[PoseLandmarkType.leftWrist];
    final rw = lm[PoseLandmarkType.rightWrist];
    if (lw == null && rw == null) return null;
    if (lw == null) return rw!.y;
    if (rw == null) return lw.y;
    return (lw.y + rw.y) / 2;
  }

  static double? shoulderWidth(Map<PoseLandmarkType, PoseLandmark> lm) {
    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];
    if (ls == null || rs == null) return null;
    return distance2D(ls, rs);
  }

  /// Assemble 12-dim feature vector for the BiLSTM model.
  /// Returns null if not enough landmarks are visible.
  static List<double>? featureVector(
    Map<PoseLandmarkType, PoseLandmark> lm, {
    required double prevWristY,
    required double prevVelY,
    required double baselineWristY,
    required double refShoulderWidth,
  }) {
    final elbowL = leftElbowAngle(lm);
    final elbowR = rightElbowAngle(lm);
    final wristY = meanWristY(lm);
    final sw = shoulderWidth(lm);
    final spine = spineVerticality(lm) ?? 0.0;

    if ((elbowL == null && elbowR == null) || wristY == null || sw == null) {
      return null;
    }

    final elbowMean = meanElbowAngle(lm) ?? 170.0;
    final velY = wristY - prevWristY;
    final accY = velY - prevVelY;
    final depth = ((wristY - baselineWristY).abs() / (refShoulderWidth + 1e-8)).clamp(0.0, 1.0);

    double norm(double v, double lo, double hi) =>
        ((v - lo) / (hi - lo + 1e-8)).clamp(0.0, 1.0);

    final visScores = [
      lm[PoseLandmarkType.leftShoulder]?.likelihood ?? 0.0,
      lm[PoseLandmarkType.rightShoulder]?.likelihood ?? 0.0,
      lm[PoseLandmarkType.leftElbow]?.likelihood ?? 0.0,
      lm[PoseLandmarkType.rightElbow]?.likelihood ?? 0.0,
      lm[PoseLandmarkType.leftWrist]?.likelihood ?? 0.0,
      lm[PoseLandmarkType.rightWrist]?.likelihood ?? 0.0,
    ];
    final meanVis = visScores.reduce((a, b) => a + b) / visScores.length;

    return [
      norm(elbowL ?? elbowMean, 0, 180),  // 0
      norm(elbowR ?? elbowMean, 0, 180),  // 1
      norm(elbowMean, 0, 180),            // 2
      norm(spine, 0, 90),                 // 3
      wristY,                             // 4
      velY.clamp(-1.0, 1.0),             // 5
      accY.clamp(-1.0, 1.0),             // 6
      depth,                              // 7
      norm(sw, 0.05, 0.6),               // 8
      meanVis,                            // 9
      elbowL != null ? 1.0 : 0.0,        // 10
      elbowR != null ? 1.0 : 0.0,        // 11
    ];
  }

  /// Simple peak detection for BPM — mirrors the Python scipy logic
  static double? estimateBpm(
    List<double> wristYBuffer, {
    int minDistance = 12,
    int fps = 25,
  }) {
    if (wristYBuffer.length < minDistance * 2) return null;
    final peaks = <int>[];
    for (var i = minDistance; i < wristYBuffer.length - minDistance; i++) {
      var isPeak = true;
      for (var j = i - minDistance; j < i; j++) {
        if (wristYBuffer[j] >= wristYBuffer[i]) { isPeak = false; break; }
      }
      if (!isPeak) continue;
      for (var j = i + 1; j <= i + minDistance; j++) {
        if (wristYBuffer[j] >= wristYBuffer[i]) { isPeak = false; break; }
      }
      if (isPeak) {
        if (peaks.isEmpty || i - peaks.last >= minDistance) {
          peaks.add(i);
        }
      }
    }
    if (peaks.length < 2) return null;
    final intervals = List.generate(peaks.length - 1, (i) => peaks[i + 1] - peaks[i]);
    final meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    return meanInterval > 0 ? (fps * 60) / meanInterval : null;
  }
}
