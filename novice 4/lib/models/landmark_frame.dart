// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:freezed_annotation/freezed_annotation.dart';

part 'landmark_frame.freezed.dart';

/// Single-frame output from PoseService.
/// Contains raw landmark positions + derived metrics for one video frame.
@freezed
class LandmarkFrame with _$LandmarkFrame {
  const factory LandmarkFrame({
    required DateTime capturedAt,

    // ── Raw MediaPipe landmark coordinates (normalized 0.0–1.0) ──
    required double leftShoulderX,  required double leftShoulderY,
    required double rightShoulderX, required double rightShoulderY,
    required double leftElbowX,     required double leftElbowY,
    required double rightElbowX,    required double rightElbowY,
    required double leftWristX,     required double leftWristY,
    required double rightWristX,    required double rightWristY,
    required double leftHipX,       required double leftHipY,
    required double rightHipX,      required double rightHipY,

    // ── Visibility scores from MediaPipe ─────────────────────────
    required double leftElbowVisibility,
    required double rightElbowVisibility,
    required double leftWristVisibility,
    required double rightWristVisibility,

    // ── Derived metrics (computed by LandmarkMath) ────────────────
    required double leftElbowAngle,   // degrees
    required double rightElbowAngle,  // degrees
    required double spineVerticality, // degrees from vertical
    required double wristMidX,
    required double wristMidY,
    required double shoulderWidth,    // normalised distance

    // ── Temporal derivatives (computed across consecutive frames) ─
    @Default(0.0) double wristVelocityY,
    @Default(0.0) double wristAccelerationY,

    // ── Quality flags ─────────────────────────────────────────────
    @Default(false) bool allLandmarksVisible,
    @Default(0.0) double meanLandmarkConfidence,

    // ── Native camera frame size the landmarks are normalized against ─
    // (video.videoWidth / video.videoHeight — NOT the on-screen widget
    // size, which is usually cropped/scaled via CSS object-fit: cover).
    // Needed by PoseOverlayPainter to correctly map normalized 0–1
    // landmark coordinates onto the displayed canvas.
    @Default(0.0) double sourceVideoWidth,
    @Default(0.0) double sourceVideoHeight,
  }) = _LandmarkFrame;
}