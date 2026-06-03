// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

// ignore: avoid_web_libraries_in_flutter
import 'package:camera/camera.dart';
import 'package:flutter/painting.dart' show Size;
// google_mlkit is mobile-only. Stub provides types on web so this file compiles.
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    if (dart.library.html) '../../core/utils/mlkit_stub.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import 'pose_service_interface.dart';

/// Mobile pose estimation via google_mlkit_pose_detection (MediaPipe BlazePose).
/// Used on iOS and Android only — NOT imported on web.
///
/// Registered in injection.dart when kIsWeb == false.
class PoseServiceMobile implements PoseServiceInterface {
  PoseServiceMobile() {
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
  }

  late final PoseDetector _detector;
  final _log = Logger();
  LandmarkFrame? _previousFrame;

  @override
  Future<LandmarkFrame?> processFrame(
    CameraImage? image,   // ← nullable to satisfy interface
    dynamic rotation,
  ) async {
    if (image == null) return null; // ← web guard — never called with null on mobile

    final inputImage = _buildInputImage(image, rotation as InputImageRotation);
    if (inputImage == null) return null;

    List<Pose> poses;
    try {
      poses = await _detector.processImage(inputImage);
    } catch (e) {
      _log.w('PoseServiceMobile: $e');
      return null;
    }
    if (poses.isEmpty) return null;
    return _buildFrame(poses.first);
  }

  InputImage? _buildInputImage(CameraImage image, InputImageRotation rotation) {
    try {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888, // iOS; Android uses nv21 — TODO verify
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      _log.w('PoseServiceMobile: InputImage build failed — $e');
      return null;
    }
  }

  LandmarkFrame? _buildFrame(Pose pose) {
    final lm = pose.landmarks;
    final ls = lm[PoseLandmarkType.leftShoulder];
    final rs = lm[PoseLandmarkType.rightShoulder];
    final le = lm[PoseLandmarkType.leftElbow];
    final re = lm[PoseLandmarkType.rightElbow];
    final lw = lm[PoseLandmarkType.leftWrist];
    final rw = lm[PoseLandmarkType.rightWrist];
    final lh = lm[PoseLandmarkType.leftHip];
    final rh = lm[PoseLandmarkType.rightHip];

    if (ls == null || rs == null || le == null || re == null ||
        lw == null || rw == null || lh == null || rh == null) {
      return null;
    }

    final visibilities = [ls.likelihood, rs.likelihood, le.likelihood,
                          re.likelihood, lw.likelihood, rw.likelihood];
    final meanConf = visibilities.reduce((a, b) => a + b) / visibilities.length;
    if (meanConf < AppConstants.minLandmarkVisibility) return null;

    final leAngle = LandmarkMath.jointAngleDeg(ls.x, ls.y, le.x, le.y, lw.x, lw.y);
    final reAngle = LandmarkMath.jointAngleDeg(rs.x, rs.y, re.x, re.y, rw.x, rw.y);
    final shoulderMidX = (ls.x + rs.x) / 2;
    final shoulderMidY = (ls.y + rs.y) / 2;
    final hipMidX = (lh.x + rh.x) / 2;
    final hipMidY = (lh.y + rh.y) / 2;
    final spineAngle = LandmarkMath.spineVerticalityDeg(
        shoulderMidX, shoulderMidY, hipMidX, hipMidY);
    final wristMidX = (lw.x + rw.x) / 2;
    final wristMidY = (lw.y + rw.y) / 2;
    final shoulderWidth = LandmarkMath.distance2d(ls.x, ls.y, rs.x, rs.y);

    double velY = 0, accY = 0;
    final prev = _previousFrame;
    if (prev != null) {
      velY = LandmarkMath.wristVelocity(wristMidY, prev.wristMidY);
      accY = velY - prev.wristVelocityY;
    }

    final frame = LandmarkFrame(
      capturedAt: DateTime.now(),
      leftShoulderX: ls.x,   leftShoulderY: ls.y,
      rightShoulderX: rs.x,  rightShoulderY: rs.y,
      leftElbowX: le.x,      leftElbowY: le.y,
      rightElbowX: re.x,     rightElbowY: re.y,
      leftWristX: lw.x,      leftWristY: lw.y,
      rightWristX: rw.x,     rightWristY: rw.y,
      leftHipX: lh.x,        leftHipY: lh.y,
      rightHipX: rh.x,       rightHipY: rh.y,
      leftElbowVisibility: le.likelihood,
      rightElbowVisibility: re.likelihood,
      leftWristVisibility: lw.likelihood,
      rightWristVisibility: rw.likelihood,
      leftElbowAngle: leAngle,
      rightElbowAngle: reAngle,
      spineVerticality: spineAngle,
      wristMidX: wristMidX,
      wristMidY: wristMidY,
      shoulderWidth: shoulderWidth,
      wristVelocityY: velY,
      wristAccelerationY: accY,
      allLandmarksVisible: meanConf >= AppConstants.minLandmarkVisibility,
      meanLandmarkConfidence: meanConf,
    );
    _previousFrame = frame;
    return frame;
  }

  @override
  Future<void> dispose() async => _detector.close();
}