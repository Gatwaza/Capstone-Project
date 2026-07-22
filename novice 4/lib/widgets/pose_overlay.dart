// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/landmark_math.dart' show HandPlacementResult;
import '../models/landmark_frame.dart';
import '../models/session_model.dart';

/// Draws the real-time pose skeleton on top of the camera feed, built from
/// the same shoulder/elbow/wrist/hip landmarks the model is trained on. It
/// draws the actual tracked joints and limb segments every frame from live
/// landmark data (not just the aggregate [InferenceResult]), so the overlay
/// moves with the person in real time.
///
/// Connections are coloured by clinical importance:
///   Green  = correct technique (elbow angle ≥ [AppConstants.elbowLockAngleDeg])
///   Red    = error detected (bent elbow on that side)
///   White  = structural (shoulders, torso, hips)
///
/// Landmark coordinates from MediaPipe/MLKit are normalized (0.0–1.0)
/// against the *native* camera frame (`LandmarkFrame.sourceVideoWidth/
/// Height` — e.g. a landscape 1280x720 sensor frame), NOT against this
/// painter's canvas size. The camera preview is shown with CSS
/// `object-fit: cover`, which scales and crops that native frame to fill
/// the (usually portrait) canvas. `_pt()` replicates that same cover-fit
/// transform before scaling into canvas space, so a landmark that's e.g.
/// dead-center of the native frame lands dead-center of what's on screen,
/// rather than drifting into a corner whenever the native and canvas
/// aspect ratios differ (which, on phones, is basically always). No
/// horizontal flip is applied — camera preview and pose detector both
/// read the same unmirrored frame.
class PoseOverlayPainter extends CustomPainter {
  const PoseOverlayPainter({
    required this.frame,
    required this.inference,
    this.handPlacement,
    this.videoSize,
  });

  /// Per-frame landmarks to draw. As of training_screen.dart's wiring,
  /// callers pass the display-only, one-euro-filtered copy produced by
  /// landmark_smoother.dart (LiveSessionState.smoothedFrame) rather than
  /// the raw frame the ML feature path uses — this painter never itself
  /// assumes one or the other, it just draws whatever LandmarkFrame it's
  /// given. Null only in the brief window before the first valid pose has
  /// been detected (or before the first smoothed frame exists).
  final LandmarkFrame? frame;

  /// Aggregate classification/depth/bpm for this moment. Used only for the
  /// depth bar — the skeleton itself is driven entirely by [frame].
  final InferenceResult? inference;

  /// Latest geometric hand-placement read (session_provider.dart). Drives
  /// the chest guide zone color and the red wrist highlight below. Null
  /// while unassessed (low landmark confidence) — the guide zone still
  /// draws, just in its neutral color.
  final HandPlacementResult? handPlacement;

  /// Optional override for the native camera frame size (e.g. from a
  /// caller-side `_nativeVideoSize()` helper). When supplied, this takes
  /// priority over `frame.sourceVideoWidth/Height` in `_pt()` — useful if
  /// the caller has a fresher or more reliable read of the video element's
  /// dimensions than what's on the landmark frame itself. When null (the
  /// common case), `_pt()` falls back to `frame.sourceVideoWidth/Height`.
  final Size? videoSize;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame;
    if (f != null) {
      _drawChestGuideZone(canvas, size, f);
      _drawSkeleton(canvas, size, f);
      _drawCompressionTarget(canvas, size, f);
    }
    if (inference != null) {
      _drawDepthIndicator(canvas, size, inference!);
    }
  }

  bool get _handPlacementOk =>
      handPlacement == null || handPlacement == HandPlacementResult.correct;

  /// Draws the target zone for hand placement as a parallelogram anchored
  /// to the person's own shoulder/hip landmarks (not a fixed screen
  /// rectangle), so it tracks them as they move toward/away from camera.
  /// Green + hollow = hands currently correct or not yet assessed.
  /// Red + filled tint = a placement error is active right now — this is
  /// the visual half of the "hand issue" cue; TtsService.speakKey('hand_
  /// placement') is the spoken half.
  void _drawChestGuideZone(Canvas canvas, Size size, LandmarkFrame f) {
    final shoulderMidX = (f.leftShoulderX + f.rightShoulderX) / 2;
    final shoulderMidY = (f.leftShoulderY + f.rightShoulderY) / 2;
    final hipMidY = (f.leftHipY + f.rightHipY) / 2;
    final shoulderWidth = (f.rightShoulderX - f.leftShoulderX).abs();
    final torsoHeight = hipMidY - shoulderMidY;
    if (shoulderWidth < 1e-6 || torsoHeight < 1e-6) return;

    // Matches the ideal band from LandmarkMath.assessHandPlacement2D:
    // 35%–75% down the torso, centered laterally, half-width scaled to
    // the ±15% lateral tolerance plus a margin so the zone reads as a
    // believable "aim here" box rather than a hair-thin target.
    final zoneHalfWidth = shoulderWidth * 0.28;
    final topY = shoulderMidY + torsoHeight * 0.35;
    final bottomY = shoulderMidY + torsoHeight * 0.75;

    // A slight parallelogram skew (not a plain rectangle) toward the
    // shoulder line, which reads more like a chest-surface guide under
    // perspective than an axis-aligned box would.
    final skew = shoulderWidth * 0.06;

    final topLeft = _pt(size, shoulderMidX - zoneHalfWidth - skew, topY, f);
    final topRight = _pt(size, shoulderMidX + zoneHalfWidth - skew, topY, f);
    final bottomRight = _pt(size, shoulderMidX + zoneHalfWidth + skew, bottomY, f);
    final bottomLeft = _pt(size, shoulderMidX - zoneHalfWidth + skew, bottomY, f);

    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final ok = _handPlacementOk;
    final color = ok ? AppTheme.accent : AppTheme.accentWarn;

    if (!ok) {
      canvas.drawPath(path, Paint()..color = color.withOpacity(0.18));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(ok ? 0.55 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ok ? 1.5 : 2.5,
    );
  }

  // ── Skeleton ─────────────────────────────────────────────

  /// Maps a normalized (0.0–1.0) landmark coordinate — normalized against
  /// the native camera frame — onto this painter's canvas, replicating the
  /// CSS `object-fit: cover` transform the <video> element is displayed
  /// with. Without this, canvas coordinates are only correct when the
  /// native camera frame and the canvas happen to share an aspect ratio.
  Offset _pt(Size size, double nx, double ny, LandmarkFrame f) {
    // Prefer the frame's own dims: they're read straight from the JS
    // bridge's _novicePoseVideoWidth/Height globals on every single frame
    // (pose_service_web.dart), the same globals the pose detector itself
    // uses — guaranteed in sync with the landmarks being painted right
    // now. `videoSize` (an external override some callers pass in, e.g.
    // via a locally-computed _nativeVideoSize() helper) is only used as a
    // fallback before the first real landmark frame has dimensions —
    // trusting it over fresh per-frame data risks silently painting
    // against stale or incorrectly-computed dimensions (e.g. a cached
    // CameraController.value.previewSize, which can lag or mismatch the
    // <video> element's actual live pixel size on web).
    final vw = f.sourceVideoWidth > 0 ? f.sourceVideoWidth : (videoSize?.width ?? 0);
    final vh = f.sourceVideoHeight > 0 ? f.sourceVideoHeight : (videoSize?.height ?? 0);
    if (vw <= 0 || vh <= 0) {
      // Native dimensions not known yet (first frame or two) — fall back
      // to the naive mapping rather than drawing nothing.
      return Offset(nx * size.width, ny * size.height);
    }

    // `cover`: scale the native frame up (never down) until it fully
    // covers the canvas on both axes, then center it, cropping whichever
    // axis overflows.
    final scale = size.width / vw > size.height / vh
        ? size.width / vw
        : size.height / vh;
    final scaledW = vw * scale;
    final scaledH = vh * scale;
    final offsetX = (scaledW - size.width) / 2;
    final offsetY = (scaledH - size.height) / 2;

    return Offset(nx * scaledW - offsetX, ny * scaledH - offsetY);
  }

  void _drawSkeleton(Canvas canvas, Size size, LandmarkFrame f) {
    final leftLocked = f.leftElbowAngle >= AppConstants.elbowLockAngleDeg;
    final rightLocked = f.rightElbowAngle >= AppConstants.elbowLockAngleDeg;

    final leftArmColor = leftLocked ? AppTheme.accent : AppTheme.accentWarn;
    final rightArmColor = rightLocked ? AppTheme.accent : AppTheme.accentWarn;
    const structuralColor = Color(0xB3FFFFFF); // ~70% white

    final ls = _pt(size, f.leftShoulderX, f.leftShoulderY, f);
    final rs = _pt(size, f.rightShoulderX, f.rightShoulderY, f);
    final le = _pt(size, f.leftElbowX, f.leftElbowY, f);
    final re = _pt(size, f.rightElbowX, f.rightElbowY, f);
    final lw = _pt(size, f.leftWristX, f.leftWristY, f);
    final rw = _pt(size, f.rightWristX, f.rightWristY, f);
    final lh = _pt(size, f.leftHipX, f.leftHipY, f);
    final rh = _pt(size, f.rightHipX, f.rightHipY, f);

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
    // A hand-placement error overrides the elbow-lock coloring here
    // specifically, since a misplaced hand is the more urgent correction
    // and should read unambiguously as red regardless of arm angle.
    final wristColor = _handPlacementOk ? null : AppTheme.accentWarn;
    joint(lw, wristColor ?? leftArmColor, 6);
    joint(rw, wristColor ?? rightArmColor, 6);
  }

  /// Small pulsing ring centered on the actual wrist midpoint (the real
  /// compression point this person is using), not a fixed screen position.
  void _drawCompressionTarget(Canvas canvas, Size size, LandmarkFrame f) {
    final center = _pt(size, f.wristMidX, f.wristMidY, f);
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
      old.frame != frame ||
      old.inference != inference ||
      old.handPlacement != handPlacement;
}