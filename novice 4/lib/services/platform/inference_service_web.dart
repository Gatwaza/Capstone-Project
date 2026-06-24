// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Web ML inference — calls hosted TCN API.
// Returns isSimulated=true (no accumulation) when the TCN API is unreachable.

import 'dart:async';
import 'dart:collection';

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import '../../models/session_model.dart';
import 'cpr_api_service.dart';

class InferenceServiceWeb {
  final _frameBuffer   = ListQueue<List<double>>();
  final _wristYHistory = ListQueue<_TimedSample>();
  final _api           = CprApiService();

  // ── FIX: the real model's prediction was being computed and thrown away ──
  // `infer()` (called every frame) used to fire `inferAsync()` without
  // awaiting it, then immediately return a rule-based result regardless of
  // what the trained BiLSTM API said. That meant:
  //   1. The actual ML model never drove feedback on web — only the rule
  //      fallback did, even when `modelAvailable` was true.
  //   2. Every single frame sent a full (60×12) HTTP POST to the hosted
  //      Hugging Face Space, fire-and-forget, regardless of how fast the
  //      caller polled — at 25 Hz that's 25 overlapping requests/sec.
  // Fix: cache the latest real prediction and use it when fresh; only issue
  // a new API call when the previous one has resolved and enough time has
  // passed (the 60-frame window doesn't change meaningfully frame-to-frame).
  InferenceResult? _lastApiResult;
  DateTime? _lastApiCallAt;
  bool _apiCallInFlight = false;
  static const Duration _apiCallInterval = Duration(milliseconds: 600);
  static const Duration _apiResultMaxAge = Duration(milliseconds: 1500);

  // ── FIX: Depth calibration ─────────────────────────────────────────────────
  // Track wrist Y range within the session to normalise depth dynamically.
  // On first frames we have no range yet — we use a conservative fixed scale
  // until we have enough history (>= _depthCalibFrames samples).
  //
  // Physical basis: typical adult torso is ~50–60 cm tall when seated/kneeling.
  // Sternum compression target = 5–6 cm ≈ 9–11% of torso height.
  // normalizedWristDisplacement() returns a value in [0,1] relative to torso.
  // So: depthCm = normDisp * torsoHeightCm
  // We estimate torsoHeightCm from shoulderWidth (roughly 1:1 in adults).
  double _shoulderWidthPxSum = 0;
  int _shoulderWidthSamples  = 0;
  static const int _depthCalibFrames = 30; // ~1.2s at 25fps before depth is live

  bool get isModelLoaded => _api.isReachable;

  Future<void> init() async {
    await _api.checkHealth();
  }

  /// Fires the remote BiLSTM prediction when appropriate and caches the
  /// result. This is fire-and-forget by design (it updates `_lastApiResult`
  /// asynchronously) but — unlike before — that cached result is now
  /// actually consumed by `infer()` below instead of being thrown away.
  Future<void> _maybeCallApi(LandmarkFrame frame) async {
    if (!_api.isReachable) return;
    if (_apiCallInFlight) return;
    if (_frameBuffer.length < AppConstants.temporalWindowFrames) return;

    final now = DateTime.now();
    if (_lastApiCallAt != null &&
        now.difference(_lastApiCallAt!) < _apiCallInterval) {
      return;
    }

    _apiCallInFlight = true;
    _lastApiCallAt = now;
    try {
      final sequence   = _frameBuffer.toList();
      final prediction = await _api.predict(sequence);
      if (prediction != null) {
        print('[InferenceServiceWeb] API → ${prediction.resolvedLabel} '
              '(${prediction.resolvedConfidence.toStringAsFixed(2)})');
        // FIX: rate/depth/recoil accuracy + confidence were never being
        // read off `prediction` here — only `topClassLabel` and
        // `allClassScores` (which nothing downstream even consumes) were
        // set. session_provider.dart's onFrame() only accumulates into
        // _rateAccuracies / _depthAccuracies / _recoilAccuracies when the
        // corresponding field is non-null, so those histories stayed
        // empty all session → mean defaults to 0.0 → the Rate/Depth/Recoil
        // tiles and the final Quality Score were stuck at 0% regardless of
        // actual performance, even though the API was returning real
        // per-task predictions the whole time.
        // Per-task accuracy is 1.0 when that task's label is 'Correct',
        // 0.0 otherwise (mirrors the same 'Correct' check resolvedLabel
        // already uses to decide which error to surface).
        //
        // FIX (2026-06): allClassScores map keys are now namespaced with a
        // task prefix ('rate_', 'depth_', 'recoil_') to prevent Dart
        // map-literal duplicate-key collisions. When two or more tasks
        // simultaneously predict 'Correct', the bare-key version silently
        // dropped all but the last entry because Dart map literals use
        // last-write-wins for duplicate keys. rateLabel/depthLabel/
        // recoilLabel below are still set as plain 'Correct'/'Too_Fast' etc.
        // — those are the values compared for accuracy and never go through
        // allClassScores, so they're unaffected by the collision.
        _lastApiResult = InferenceResult(
          timestamp:           DateTime.now(),
          topClassIndex:       0,
          topClassLabel:       prediction.resolvedLabel,
          topClassConfidence:  prediction.resolvedConfidence,
          allClassScores: {
            // Prefixed keys — no collision even when all three are 'Correct'.
            'rate_${prediction.rateLabel}':     prediction.rateConfidence,
            'depth_${prediction.depthLabel}':   prediction.depthConfidence,
            'recoil_${prediction.recoilLabel}': prediction.recoilConfidence,
          },
          currentBpm:          _estimateBpm(),
          estimatedDepthCm:    _estimateDepthCm(frame),
          elbowAngleMean:      (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
          spineVerticalityDeg: frame.spineVerticality,
          rateAccuracy:        prediction.rateLabel   == 'Correct' ? 1.0 : 0.0,
          rateConfidence:      prediction.rateConfidence,
          depthAccuracy:       prediction.depthLabel  == 'Correct' ? 1.0 : 0.0,
          depthConfidence:     prediction.depthConfidence,
          // FIX: recoil's good-state label from the API is 'Complete', not
          // 'Correct' -- rate and depth use 'Correct' for their good state
          // (matches the notebook's LabelEncoder classes for those two
          // tasks), but recoil's LabelEncoder was only ever fit on
          // 'Complete'/'Incomplete' (see CPR_Coach_Training.ipynb Stage 2,
          // single_error_to_labels). This was previously checking
          // 'Correct', which the recoil API response would never actually
          // send -- it accidentally read as correct-ish before app.py's
          // RECOIL_CLASSES bug was fixed (that bug coincidentally mapped
          // model index 0 to the string "Correct" instead of "Complete").
          // Both sides were fixed together; do not change one without the
          // other.
          recoilAccuracy:      prediction.recoilLabel == 'Complete' ? 1.0 : 0.0,
          recoilConfidence:    prediction.recoilConfidence,
          // Plain labels — used for accuracy comparison and class-count
          // tallying in session_provider; they do NOT go into allClassScores.
          rateLabel:   prediction.rateLabel,
          depthLabel:  prediction.depthLabel,
          recoilLabel: prediction.recoilLabel,
          isSimulated:         false,
          isFreshPrediction:   true,
        );
      }
    } finally {
      _apiCallInFlight = false;
    }
  }

  InferenceResult infer(LandmarkFrame frame) {
    final features = _buildFeatures(frame);

    _frameBuffer.addLast(features);
    while (_frameBuffer.length > AppConstants.temporalWindowFrames) {
      _frameBuffer.removeFirst();
    }

    _wristYHistory.addLast(_TimedSample(frame.capturedAt, frame.wristMidY));
    while (_wristYHistory.length > AppConstants.bpmHistoryLength) {
      _wristYHistory.removeFirst();
    }

    _updateDepthCalibration(frame);

    final bpm   = _estimateBpm();
    final depth = _estimateDepthCm(frame);

    // Kick off (or skip, if throttled/in-flight) a real-model prediction.
    // This updates `_lastApiResult` in the background — it does not block
    // this frame's return, which is what keeps the UI/audio responsive.
    unawaited(_maybeCallApi(frame));

    // Return cached model result when fresh; otherwise return a null-signal
    // result (isSimulated=true) so the provider skips accumulation.
    // No rule-based fallback — model availability is tracked explicitly.
    final cached = _lastApiResult;
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _apiResultMaxAge) {
      // isFreshPrediction explicitly forced false -- this frame is reusing
      // a label/accuracy from a previous API call, not a new one. Without
      // this, copyWith() would carry forward the `true` set when
      // _lastApiResult was first constructed, and every one of the ~14-36
      // frames served from cache between real API calls would incorrectly
      // count toward the live rate/depth/recoil accuracy histories in
      // session_provider.dart, even though currentBpm/estimatedDepthCm
      // below are freshly computed for THIS frame and may have drifted
      // well away from what that stale label actually evaluated.
      return cached.copyWith(
        currentBpm: bpm,
        estimatedDepthCm: depth,
        isFreshPrediction: false,
      );
    }

    // Model not yet loaded or API call in flight — return a non-accumulating result.
    return InferenceResult(
      timestamp:           DateTime.now(),
      topClassIndex:       0,
      topClassLabel:       'model_unavailable',
      topClassConfidence:  0.0,
      allClassScores:      const {},
      currentBpm:          bpm,
      estimatedDepthCm:    depth,
      elbowAngleMean:      (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
      spineVerticalityDeg: frame.spineVerticality,
      isSimulated:         true,
    );
  }

  List<double> _buildFeatures(LandmarkFrame frame) {
    return LandmarkMath.buildFeatureVector(
      leftElbowAngle:     frame.leftElbowAngle,
      rightElbowAngle:    frame.rightElbowAngle,
      spineVerticality:   frame.spineVerticality,
      wristY:             frame.wristMidY,
      wristVelocityY:     frame.wristVelocityY,
      wristAccelerationY: frame.wristAccelerationY,
      normalizedDepth: LandmarkMath.normalizedWristDisplacement(
        frame.wristMidY, frame.leftShoulderY, frame.leftHipY,
      ),
      shoulderWidth:    frame.shoulderWidth,
      meanConfidence:   frame.meanLandmarkConfidence,
      leftElbowVisible:
          frame.leftElbowVisibility > AppConstants.minLandmarkVisibility,
      rightElbowVisible:
          frame.rightElbowVisibility > AppConstants.minLandmarkVisibility,
    );
  }


  // ── Depth calibration helpers ──────────────────────────────────────────────

  void _updateDepthCalibration(LandmarkFrame frame) {
    if (frame.shoulderWidth > 0.05) { // ignore frames with invisible shoulders
      _shoulderWidthPxSum += frame.shoulderWidth;
      _shoulderWidthSamples++;
    }
  }

  /// Estimates physical depth in cm from normalised wrist displacement.
  ///
  /// Strategy:
  ///   1. Compute normalised wrist displacement relative to torso height
  ///      (0 = at shoulder, 1 = at hip level).
  ///   2. Multiply by estimated torso height in cm.
  ///
  /// Torso height estimation:
  ///   We use mean shoulder width as a proxy (biacromial width ≈ torso height
  ///   in seated/kneeling adults, both ~40–48 cm for typical adults).
  ///   The scale factor (AppConstants.shoulderWidthToTorsoRatio) is calibrated
  ///   to a typical rescuer distance from the manikin camera.
  ///
  /// Before calibration frames accumulate, falls back to a fixed 45 cm torso.
  double _estimateDepthCm(LandmarkFrame frame) {
    final normDisp = LandmarkMath.normalizedWristDisplacement(
      frame.wristMidY,
      (frame.leftShoulderY + frame.rightShoulderY) / 2,
      (frame.leftHipY + frame.rightHipY) / 2,
    );

    // Estimate torso height in cm
    double torsoHeightCm;
    if (_shoulderWidthSamples >= _depthCalibFrames) {
      final meanShoulderWidthNorm = _shoulderWidthPxSum / _shoulderWidthSamples;
      // shoulderWidthToTorsoRatio: empirically ~0.85 (shoulder width ≈ 85% of torso height)
      torsoHeightCm = (meanShoulderWidthNorm * AppConstants.normToPhysicalCmScale)
                      / AppConstants.shoulderWidthToTorsoRatio;
    } else {
      // Conservative fallback until we have enough calibration data
      torsoHeightCm = AppConstants.fallbackTorsoHeightCm;
    }

    // Clamp to clinically plausible range [0, 10] cm
    return (normDisp * torsoHeightCm).clamp(0.0, 10.0);
  }

  // FIX: 0.005 was inside the landmark-jitter noise floor — small
  // frame-to-frame tracking wobble produced multiple false peaks per
  // second even with hands still, inflating BPM to physically impossible
  // values (200+ bpm) and feeding a falsely "too fast" signal into the
  // hosted rate classifier. Raised to match the same threshold used for
  // compression counting in session_provider.dart.
  double _estimateBpm() {
    if (_wristYHistory.length < 10) return 0;
    final samples    = _wristYHistory.toList();
    final velocities = <double>[];
    for (int i = 1; i < samples.length; i++) {
      velocities.add(samples[i].value - samples[i - 1].value);
    }
    final peaks = <DateTime>[];
    for (int i = 1; i < velocities.length - 1; i++) {
      if (velocities[i] > velocities[i - 1] &&
          velocities[i] > velocities[i + 1] &&
          velocities[i] > 0.012) {
        peaks.add(samples[i + 1].timestamp);
      }
    }
    if (peaks.length < 2) return 0;
    double totalMs = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalMs += peaks[i].difference(peaks[i - 1]).inMilliseconds;
    }
    final meanMs = totalMs / (peaks.length - 1);
    return meanMs <= 0 ? 0 : (60000 / meanMs).clamp(0, 200);
  }

  void dispose() {}
}

class _TimedSample {
  final DateTime timestamp;
  final double   value;
  _TimedSample(this.timestamp, this.value);
}