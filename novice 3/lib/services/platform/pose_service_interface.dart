// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:camera/camera.dart';
import '../../models/landmark_frame.dart';

/// Abstract pose estimation interface.
/// Mobile: implemented by PoseServiceMobile (google_mlkit_pose_detection)
/// Web:    implemented by PoseServiceWeb    (JS interop → @mediapipe/pose)
///
/// The DI container (injection.dart) selects the correct implementation
/// at runtime using kIsWeb.
abstract class PoseServiceInterface {
  /// Process one camera frame and return a LandmarkFrame, or null
  /// if no person is detected or confidence is too low.
  Future<LandmarkFrame?> processFrame(
    CameraImage image,
    dynamic rotation, // InputImageRotation on mobile, ignored on web
  );

  /// Release resources.
  Future<void> dispose();
}
