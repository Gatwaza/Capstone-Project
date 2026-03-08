import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class LandmarkFrame {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final int frameIndex;
  final DateTime timestamp;

  // Extracted features
  final double? leftElbowAngle;
  final double? rightElbowAngle;
  final double? spineVerticality;
  final double? wristY;
  final double? shoulderWidth;

  const LandmarkFrame({
    required this.landmarks,
    required this.frameIndex,
    required this.timestamp,
    this.leftElbowAngle,
    this.rightElbowAngle,
    this.spineVerticality,
    this.wristY,
    this.shoulderWidth,
  });

  bool get hasSufficientVisibility {
    final required = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];
    return required.every((t) =>
        landmarks[t] != null && (landmarks[t]!.likelihood) > 0.6);
  }

  double? get meanElbowAngle {
    if (leftElbowAngle != null && rightElbowAngle != null) {
      return (leftElbowAngle! + rightElbowAngle!) / 2;
    }
    return leftElbowAngle ?? rightElbowAngle;
  }
}
