import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../core/theme/app_theme.dart';

class PoseOverlay extends StatelessWidget {
  final Map<PoseLandmarkType, PoseLandmark>? landmarks;
  final Size imageSize;
  final bool mirror;

  const PoseOverlay({
    super.key,
    required this.landmarks,
    required this.imageSize,
    this.mirror = true,
  });

  @override
  Widget build(BuildContext context) {
    if (landmarks == null || landmarks!.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _PosePainter(
        landmarks: landmarks!,
        imageSize: imageSize,
        mirror: mirror,
      ),
    );
  }
}

class _PosePainter extends CustomPainter {
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Size imageSize;
  final bool mirror;

  _PosePainter({required this.landmarks, required this.imageSize, required this.mirror});

  static const _connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow,    PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder,PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow,   PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder,PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip,      PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip,      PoseLandmarkType.leftKnee],
    [PoseLandmarkType.rightHip,     PoseLandmarkType.rightKnee],
  ];

  static const _highlightedJoints = {
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.skeletonLine.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final wristPaint = Paint()
      ..color = AppColors.accentRed
      ..style = PaintingStyle.fill;

    Offset _toCanvas(PoseLandmark lm) {
      double x = lm.x * size.width;
      double y = lm.y * size.height;
      if (mirror) x = size.width - x;
      return Offset(x, y);
    }

    // Draw connections
    for (final conn in _connections) {
      final a = landmarks[conn[0]];
      final b = landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.likelihood < 0.4 || b.likelihood < 0.4) continue;
      canvas.drawLine(_toCanvas(a), _toCanvas(b), linePaint);
    }

    // Draw joints
    for (final entry in landmarks.entries) {
      if (entry.value.likelihood < 0.4) continue;
      final pos = _toCanvas(entry.value);
      final isHighlighted = _highlightedJoints.contains(entry.key);
      final paint = isHighlighted ? wristPaint : jointPaint;
      final radius = isHighlighted ? 8.0 : 5.0;

      if (isHighlighted) {
        canvas.drawCircle(pos, radius + 3,
            Paint()..color = AppColors.accentRed.withOpacity(0.3));
      }
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PosePainter old) => true;
}
