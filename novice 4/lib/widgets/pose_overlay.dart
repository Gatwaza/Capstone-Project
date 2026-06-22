// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';

/// Draws the real-time pose skeleton on top of the camera feed, built from
/// the same shoulder/elbow/wrist/hip landmarks the model is trained on.
///
/// FIX: this painter used to be a placeholder — it drew a fixed dashed
/// circle at a hardcoded 50%/55% screen position regardless of where the
/// person actually was. It never received landmark data at all (only the
/// aggregate [InferenceResult]), so nothing on screen tracked the user's
/// real hands, elbows, or body. This version draws the actual tracked
/// joints and limb segments every frame, so the overlay moves with the
/// person instead of sitting still while they move around it.
///
/// Connections are coloured by clinical importance:
///   Green  = correct technique (elbow angle ≥ [AppConstants.elbowLockAngleDeg])
///   Red    = error detected (bent elbow on that side)
///   White  = structural (shoulders, torso, hips)
///
/// Landmark coordinates from MediaPipe/MLKit are normalized to the source
/// video frame (0.0–1.0). The camera preview and the pose detector both read
/// from the same unmirrored frame, so mapping x*width / y*height directly
/// onto the canvas lines up correctly with what's on screen — no horizontal
/// flip is applied here.
class PoseOverlayPainter extends CustomPainter {
  const PoseOverlayPainter({required this.frame, required this.inference});

  /// Raw per-frame landmarks. Null only in the brief window before the
  /// first valid pose has been detected.
  final LandmarkFrame? frame;

  /// Aggregate classification/depth/bpm for this moment. Used only for the
  /// depth bar — the skeleton itself is driven entirely by [frame].
  final InferenceResult? inference;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f != null) {
      _drawSkeleton(canvas, size, f);
      _drawCompressionTarget(canvas, size, f);
    }
    if (inference != null) {
      _drawDepthIndicator(canvas, size, inference!);
    }
  }

  // ── Skeleton ─────────────────────────────────────────────

  Offset _pt(Size size, double nx, double ny) =>
      Offset(nx * size.width, ny * size.height);

  void _drawSkeleton(Canvas canvas, Size size, LandmarkFrame f) {
    final leftLocked = f.leftElbowAngle >= AppConstants.elbowLockAngleDeg;
    final rightLocked = f.rightElbowAngle >= AppConstants.elbowLockAngleDeg;

    final leftArmColor = leftLocked ? AppTheme.accent : AppTheme.accentWarn;
    final rightArmColor = rightLocked ? AppTheme.accent : AppTheme.accentWarn;
    const structuralColor = Color(0xB3FFFFFF); // ~70% white

    final ls = _pt(size, f.leftShoulderX, f.leftShoulderY);
    final rs = _pt(size, f.rightShoulderX, f.rightShoulderY);
    final le = _pt(size, f.leftElbowX, f.leftElbowY);
    final re = _pt(size, f.rightElbowX, f.rightElbowY);
    final lw = _pt(size, f.leftWristX, f.leftWristY);
    final rw = _pt(size, f.rightWristX, f.rightWristY);
    final lh = _pt(size, f.leftHipX, f.leftHipY);
    final rh = _pt(size, f.rightHipX, f.rightHipY);

    void bone(Offset a, Offset b, Color color, {double width = 3}) {
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    // Structural frame (shoulders, torso, hips)
    bone(ls, rs, structuralColor, width: 2.5);
    bone(ls, lh, structuralColor, width: 2.5);
    bone(rs, rh, structuralColor, width: 2.5);
    bone(lh, rh, structuralColor, width: 2.5);

    // Arms — color-coded by elbow lock state, the thing the coaching
    // feedback is actually about, so the overlay visually agrees with
    // whatever the voice is saying.
    bone(ls, le, leftArmColor);
    bone(le, lw, leftArmColor);
    bone(rs, re, rightArmColor);
    bone(re, rw, rightArmColor);
    bone(lw, rw,
        leftLocked && rightLocked ? AppTheme.accent : AppTheme.accentWarn);

    void joint(Offset p, Color color, double r) {
      canvas.drawCircle(p, r, Paint()..color = color);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    joint(ls, structuralColor, 4);
    joint(rs, structuralColor, 4);
    joint(le, leftArmColor, 4);
    joint(re, rightArmColor, 4);
    joint(lh, structuralColor, 3.5);
    joint(rh, structuralColor, 3.5);
    // Wrists are the compression point — make them the most prominent.
    joint(lw, leftArmColor, 6);
    joint(rw, rightArmColor, 6);
  }

  /// Small pulsing ring centered on the actual wrist midpoint (the real
  /// compression point this person is using), not a fixed screen position.
  void _drawCompressionTarget(Canvas canvas, Size size, LandmarkFrame f) {
    final center = _pt(size, f.wristMidX, f.wristMidY);
    canvas.drawCircle(
      center,
      16,
      Paint()
        ..color = AppTheme.accent.withOpacity(0.45)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  // ── Depth bar ────────────────────────────────────────────

  void _drawDepthIndicator(
      Canvas canvas, Size size, InferenceResult inference) {
    final depth = inference.estimatedDepthCm;
    if (depth <= 0) return;

    final isGood = depth >= AppConstants.cprMinDepthCm &&
        depth <= AppConstants.cprMaxDepthCm;
    final color = isGood ? AppTheme.accent : AppTheme.accentWarn;

    // Depth bar on left edge
    const barX = 32.0;
    const barTop = 100.0;
    const barHeight = 120.0;
    const maxDepthCm = 10.0; // matches the clamp in InferenceServiceWeb

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
    final fillPct = (depth / maxDepthCm).clamp(0.0, 1.0);
    final fillHeight = barHeight * fillPct;

    canvas.drawLine(
      const Offset(barX, barTop + barHeight),
      Offset(barX, barTop + barHeight - fillHeight),
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Target zone markers (ERC 2021: 5–6 cm)
    final targetTop =
        barTop + barHeight * (1 - AppConstants.cprMaxDepthCm / maxDepthCm);
    final targetBottom =
        barTop + barHeight * (1 - AppConstants.cprMinDepthCm / maxDepthCm);

    for (final y in [targetTop, targetBottom]) {
      canvas.drawLine(
        Offset(barX - 8, y),
        Offset(barX + 8, y),
        Paint()
          ..color = AppTheme.accent.withOpacity(0.6)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.frame != frame || old.inference != inference;
}
