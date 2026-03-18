// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/session_model.dart';

/// Draws the MediaPipe pose skeleton and CPR-specific overlays on the camera.
///
/// Connections are coloured by clinical importance:
///   Green  = correct technique (elbow ≥ 160°)
///   Red    = error detected (bent elbows, wrong depth)
///   White  = structural (torso, hips)
///
/// The compression target circle pulses during active compressions.
class PoseOverlayPainter extends CustomPainter {
  const PoseOverlayPainter({required this.inference});

  final InferenceResult inference;

  @override
  void paint(Canvas canvas, Size size) {
    // NOTE: Landmark positions from PoseService are normalized 0–1.
    // The LandmarkFrame is not directly on InferenceResult in Phase 1 —
    // TODO: pass LandmarkFrame here once pose overlay is wired in Phase 2.
    // For Phase 1 demo, this painter is a visual placeholder.
    _drawCompressionTarget(canvas, size);
    _drawDepthIndicator(canvas, size);
  }

  void _drawCompressionTarget(Canvas canvas, Size size) {
    // Approximate sternum position for placeholder overlay
    final cx = size.width  * 0.5;
    final cy = size.height * 0.55;

    // Outer dashed ring
    final dashedPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy), 20, dashedPaint);

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      5,
      Paint()..color = AppTheme.accent.withOpacity(0.8),
    );
  }

  void _drawDepthIndicator(Canvas canvas, Size size) {
    final depth = inference.estimatedDepthCm;
    if (depth <= 0) return;

    final isGood = depth >= 5.0 && depth <= 6.0;
    final color = isGood ? AppTheme.accent : AppTheme.accentWarn;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Depth bar on left edge
    const barX = 32.0;
    const barTop = 100.0;
    const barHeight = 120.0;

    // Background track
    canvas.drawLine(
      const Offset(barX, barTop),
      const Offset(barX, barTop + barHeight),
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Fill to current depth
    final fillPct = (depth / 6.0).clamp(0.0, 1.0);
    final fillHeight = barHeight * fillPct;

    canvas.drawLine(
      Offset(barX, barTop + barHeight),
      Offset(barX, barTop + barHeight - fillHeight),
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Target zone markers (5–6 cm = 83–100% of 6 cm max)
    final targetTop    = barTop + barHeight * (1 - 6.0 / 6.0); // 0%
    final targetBottom = barTop + barHeight * (1 - 5.0 / 6.0); // 17%

    canvas.drawLine(
      Offset(barX - 8, targetTop),
      Offset(barX + 8, targetTop),
      Paint()
        ..color = AppTheme.accent.withOpacity(0.6)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(barX - 8, targetBottom),
      Offset(barX + 8, targetBottom),
      Paint()
        ..color = AppTheme.accent.withOpacity(0.6)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.inference != inference;
}
