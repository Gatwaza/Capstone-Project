// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Web pose service — MediaPipe via browser camera.
// Uses dart:js_interop (Dart SDK 3.x) instead of deprecated package:js.

import 'package:camera/camera.dart';
import '../../models/landmark_frame.dart';
import 'pose_service_interface.dart';

class PoseServiceWeb implements PoseServiceInterface {
  @override
  Future<LandmarkFrame?> processFrame(
    CameraImage image,
    dynamic rotation,
  ) async {
    // Web pose estimation handled by MediaPipe JS bridge in web/flutter_pose_bridge.js
    // Returns null for Phase 1 — rule-based inference used as fallback
    return null;
  }

  @override
  Future<void> dispose() async {}
}
