// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Display-only landmark smoothing for the live skeleton overlay.
//
// PoseOverlayPainter draws directly from raw per-frame MediaPipe landmarks
// (see pose_overlay.dart), which is correct for tracking accuracy but means
// ordinary detector jitter (sub-pixel wobble frame-to-frame) reads as a
// visibly shaky skeleton even when the person is holding still. This file
// smooths a COPY of the frame for display purposes only.
//
// Deliberately NOT used anywhere on the raw ML feature path:
// CprCausalFeatureExtractor (landmark_math.dart) and hand-placement
// assessment (LandmarkMath.assessHandPlacement2D) must keep consuming the
// untouched raw frame, since the model's feature vector and its training
// notebook counterpart (extract_features_full()) are defined against real,
// unsmoothed landmark motion — smoothing that path would reintroduce a
// train/live parity mismatch. LiveSessionState.smoothedFrame is a second,
// parallel field alongside lastFrame specifically so the two can diverge:
// lastFrame (raw) still feeds inference and compression counting;
// smoothedFrame (this file's output) only ever feeds the painter.
import 'dart:math' as math;

import '../../models/landmark_frame.dart';

/// One Euro Filter (Casiez, Roussel & Vogel, 2012) applied per landmark
/// coordinate. Two params trade off in opposite directions:
///   [minCutoff] — smoothing at rest. Lower = stiller when idle, more lag
///     when motion starts.
///   [beta]      — how fast smoothing backs off once motion starts. Higher
///     = less lag on fast motion, more visible jitter during it.
/// Defaults below are the paper's reference values, not tuned to this
/// app's 25fps/normalized-coordinate setup — expect to adjust beta up if
/// the overlay feels laggy on fast compressions, or minCutoff down if
/// it's still jittery at rest, against a real session.
class _OneEuroFilter {
  _OneEuroFilter({this.minCutoff = 1.0, this.beta = 0.02, this.dCutoff = 1.0});

  // Mutable (not final): LandmarkSmoother writes these on every _apply()
  // call so a caller retuning LandmarkSmoother.minCutoff/beta mid-session
  // (see class doc) takes effect on already-constructed per-joint filters
  // immediately, without needing to reset() and lose smoothing history.
  double minCutoff;
  double beta;
  final double dCutoff;

  double? _xPrev;
  double? _dxPrev;
  DateTime? _tPrev;

  static double _alpha(double cutoff, double dtSeconds) {
    final tau = 1.0 / (2 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dtSeconds);
  }

  /// Filters one new sample [x] captured at time [t]. The first call for a
  /// fresh filter (or after [reset]) has no history to smooth against, so
  /// it returns [x] unchanged and seeds internal state from it.
  double filter(double x, DateTime t) {
    final tPrev = _tPrev;
    if (tPrev == null) {
      _tPrev = t;
      _xPrev = x;
      _dxPrev = 0.0;
      return x;
    }

    final dtSeconds = t.difference(tPrev).inMicroseconds / 1e6;
    _tPrev = t;
    // Non-positive or degenerate dt (duplicate/out-of-order timestamps) —
    // hold the last smoothed value rather than dividing by ~0.
    if (dtSeconds <= 0) return _xPrev ?? x;

    final xPrev = _xPrev ?? x;
    final dx = (x - xPrev) / dtSeconds;

    final dAlpha = _alpha(dCutoff, dtSeconds);
    final dxPrev = _dxPrev ?? 0.0;
    final edx = dAlpha * dx + (1 - dAlpha) * dxPrev;
    _dxPrev = edx;

    final cutoff = minCutoff + beta * edx.abs();
    final a = _alpha(cutoff, dtSeconds);
    final xFiltered = a * x + (1 - a) * xPrev;
    _xPrev = xFiltered;
    return xFiltered;
  }

  void reset() {
    _xPrev = null;
    _dxPrev = null;
    _tPrev = null;
  }
}

/// Smooths every joint coordinate PoseOverlayPainter actually draws,
/// producing a display-only [LandmarkFrame] copy. One independent
/// [_OneEuroFilter] per coordinate (each joint's X and Y move somewhat
/// independently, so a shared filter would under- or over-smooth one axis).
///
/// Construct one instance per session (mirrors CprCausalFeatureExtractor's
/// per-session lifecycle) and call [reset] — or construct a fresh
/// instance — at the start of a new session, since filter state from a
/// previous session/participant is meaningless carried into a new one.
class LandmarkSmoother {
  LandmarkSmoother({this.minCutoff = 1.0, this.beta = 0.02});

  /// See [_OneEuroFilter.minCutoff]. Mutable so callers can retune while
  /// iterating against a real session without reconstructing the smoother
  /// (existing filters pick up the new value on their next sample).
  double minCutoff;

  /// See [_OneEuroFilter.beta].
  double beta;

  final Map<String, _OneEuroFilter> _filters = {};

  double _apply(String key, double value, DateTime t) {
    final filter = _filters.putIfAbsent(
      key,
      () => _OneEuroFilter(minCutoff: minCutoff, beta: beta),
    );
    // Sync in case minCutoff/beta were retuned since this filter was
    // constructed (see field docs above).
    filter.minCutoff = minCutoff;
    filter.beta = beta;
    return filter.filter(value, t);
  }

  /// Returns a display-only copy of [frame] with every drawn joint
  /// coordinate passed through its own one-euro filter. All other fields
  /// (angles, velocity, confidence, source video size, etc.) are carried
  /// over unchanged from [frame] — only PoseOverlayPainter's drawn
  /// coordinates are smoothed.
  LandmarkFrame smooth(LandmarkFrame frame) {
    final t = frame.capturedAt;
    return frame.copyWith(
      leftShoulderX: _apply('leftShoulderX', frame.leftShoulderX, t),
      leftShoulderY: _apply('leftShoulderY', frame.leftShoulderY, t),
      rightShoulderX: _apply('rightShoulderX', frame.rightShoulderX, t),
      rightShoulderY: _apply('rightShoulderY', frame.rightShoulderY, t),
      leftElbowX: _apply('leftElbowX', frame.leftElbowX, t),
      leftElbowY: _apply('leftElbowY', frame.leftElbowY, t),
      rightElbowX: _apply('rightElbowX', frame.rightElbowX, t),
      rightElbowY: _apply('rightElbowY', frame.rightElbowY, t),
      leftWristX: _apply('leftWristX', frame.leftWristX, t),
      leftWristY: _apply('leftWristY', frame.leftWristY, t),
      rightWristX: _apply('rightWristX', frame.rightWristX, t),
      rightWristY: _apply('rightWristY', frame.rightWristY, t),
      leftHipX: _apply('leftHipX', frame.leftHipX, t),
      leftHipY: _apply('leftHipY', frame.leftHipY, t),
      rightHipX: _apply('rightHipX', frame.rightHipX, t),
      rightHipY: _apply('rightHipY', frame.rightHipY, t),
      wristMidX: _apply('wristMidX', frame.wristMidX, t),
      wristMidY: _apply('wristMidY', frame.wristMidY, t),
    );
  }

  /// Clears all per-coordinate filter state. Call at the start of a new
  /// session if reusing an instance (prefer constructing a fresh
  /// [LandmarkSmoother] per session instead, mirroring
  /// CprCausalFeatureExtractor's convention).
  void reset() {
    _filters.clear();
  }
}