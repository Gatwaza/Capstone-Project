// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:camera/camera.dart';
import '../../models/landmark_frame.dart';

abstract class PoseServiceInterface {
  Future<LandmarkFrame?> processFrame(CameraImage? image, dynamic rotation);
  Future<void> dispose();
}