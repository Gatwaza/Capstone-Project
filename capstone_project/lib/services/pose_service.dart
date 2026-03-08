import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/landmark_math.dart';
import '../models/landmark_frame.dart';

class PoseService {
  late final PoseDetector _poseDetector;
  CameraController? _cameraController;
  bool _isProcessing = false;
  int _frameIndex = 0;

  final void Function(LandmarkFrame frame) onFrame;

  PoseService({required this.onFrame});

  Future<void> initialize() async {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    debugPrint('[PoseService] Pose detector initialized');
  }

  Future<CameraController?> startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('[PoseService] No cameras found');
        return null;
      }

      // Prefer front camera for CPR (user can see themselves)
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // 720p — balance between quality & speed
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_onCameraImage);
      debugPrint('[PoseService] Camera started: ${camera.lensDirection}');
      return _cameraController;
    } catch (e) {
      debugPrint('[PoseService] Camera error: $e');
      return null;
    }
  }

  Future<void> stopCamera() async {
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  void _onCameraImage(CameraImage image) {
    if (_isProcessing) return; // Drop frame if still processing
    _isProcessing = true;
    _frameIndex++;

    // Throttle to ~25 FPS
    if (_frameIndex % 1 != 0) {
      _isProcessing = false;
      return;
    }

    _detectPose(image, _frameIndex).then((_) {
      _isProcessing = false;
    }).catchError((e) {
      _isProcessing = false;
      debugPrint('[PoseService] Frame error: $e');
    });
  }

  Future<void> _detectPose(CameraImage image, int idx) async {
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) {
      onFrame(LandmarkFrame(
        landmarks: {},
        frameIndex: idx,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final pose = poses.first;
    final lm = {for (final l in pose.landmarks.values) l.type: l};

    onFrame(LandmarkFrame(
      landmarks: lm,
      frameIndex: idx,
      timestamp: DateTime.now(),
      leftElbowAngle: LandmarkMath.leftElbowAngle(lm),
      rightElbowAngle: LandmarkMath.rightElbowAngle(lm),
      spineVerticality: LandmarkMath.spineVerticality(lm),
      wristY: LandmarkMath.meanWristY(lm),
      shoulderWidth: LandmarkMath.shoulderWidth(lm),
    ));
  }

  InputImage? _buildInputImage(CameraImage image) {
    try {
      final camera = _cameraController!.description;
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null && Platform.isAndroid) return null;

      final plane = image.planes[0];
      final bytes = Platform.isAndroid
          ? _concatenatePlanes(image.planes)
          : plane.bytes;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format ?? InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final bytes = <int>[];
    for (final plane in planes) {
      bytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> dispose() async {
    await stopCamera();
    _poseDetector.close();
  }
}
