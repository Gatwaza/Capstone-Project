// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Web stub for google_mlkit_pose_detection.
// Provides all types used by pose_service_mobile.dart and training_screen.dart
// so those files compile on web. Never instantiated on web.
// Imported conditionally:
//   import 'package:google_mlkit_pose_detection/...'
//       if (dart.library.html) '../../core/utils/mlkit_stub.dart';

import 'package:flutter/painting.dart' show Size;

// ── Enums ─────────────────────────────────────────────────
enum InputImageRotation { rotation0deg, rotation90deg, rotation180deg, rotation270deg }
enum InputImageFormat   { bgra8888, nv21, yuv420, yv12 }
enum PoseDetectionMode  { stream, singleImage }
enum PoseDetectionModel { accurate, base }

// ── PoseLandmarkType (indices used in pose_service_mobile.dart) ────────────
enum PoseLandmarkType {
  nose, leftEyeInner, leftEye, leftEyeOuter,
  rightEyeInner, rightEye, rightEyeOuter,
  leftEar, rightEar, mouthLeft, mouthRight,
  leftShoulder, rightShoulder, leftElbow, rightElbow,
  leftWrist, rightWrist, leftPinky, rightPinky,
  leftIndex, rightIndex, leftThumb, rightThumb,
  leftHip, rightHip, leftKnee, rightKnee,
  leftAnkle, rightAnkle, leftHeel, rightHeel,
  leftFootIndex, rightFootIndex,
}

// ── InputImageMetadata ────────────────────────────────────
class InputImageMetadata {
  final Size size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;
  const InputImageMetadata({
    required this.size, required this.rotation,
    required this.format, required this.bytesPerRow,
  });
}

// ── InputImage ────────────────────────────────────────────
class InputImage {
  const InputImage._();
  static InputImage fromBytes({
    required dynamic bytes, required InputImageMetadata metadata,
  }) => const InputImage._();
}

// ── PoseLandmark ─────────────────────────────────────────
class PoseLandmark {
  final double x, y, z, likelihood;
  const PoseLandmark({
    this.x = 0, this.y = 0, this.z = 0, this.likelihood = 0,
  });
}

// ── Pose ─────────────────────────────────────────────────
class Pose {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  const Pose({this.landmarks = const {}});
}

// ── PoseDetectorOptions ───────────────────────────────────
class PoseDetectorOptions {
  final PoseDetectionMode mode;
  final PoseDetectionModel model;
  const PoseDetectorOptions({
    this.mode  = PoseDetectionMode.stream,
    this.model = PoseDetectionModel.base,
  });
}

// ── PoseDetector ─────────────────────────────────────────
class PoseDetector {
  const PoseDetector({PoseDetectorOptions? options});
  Future<List<Pose>> processImage(InputImage image) async => [];
  Future<void> close() async {}
}
