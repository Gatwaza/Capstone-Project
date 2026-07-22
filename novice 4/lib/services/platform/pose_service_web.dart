// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import 'pose_service_interface.dart';

class PoseServiceWeb implements PoseServiceInterface {
  double _prevWristY  = 0;
  double _prevWristVY = 0;

  // At AppConstants.poseEstimationTargetFps (25fps) a healthy graph updates
  // _novicePoseTimestamp roughly every 40ms. 300ms is ~7-8 missed frames --
  // generous enough to absorb ordinary jitter/GC pauses, but short enough to
  // stop feeding a frozen frame into the model long before the JS bridge's
  // own 3s crash watchdog even fires.
  static const int _maxLandmarkAgeMs = 300;

  @override
  Future<LandmarkFrame?> processFrame(CameraImage? image, dynamic rotation) async {
    try {
      // Guard against processing a frame before the <video> element has been
      // rendered by the browser — MediaPipe throws "roi->width > 0 &&
      // roi->height > 0" if it processes a frame too early. This is a
      // secondary guard to the readiness poller in TrainingScreen.
      // _novicePoseVideoReady is set to true by the bridge once videoWidth > 0.
      final videoReady = js.context['_novicePoseVideoReady'];
      if (videoReady != true) return null;

      // FIX (incomplete_decomp @ 1.00 spam): when the JS-side MediaPipe
      // graph crashes mid-session, flutter_pose_bridge.js's onResults stops
      // firing, so _novicePoseLandmarks simply stops updating -- it keeps
      // holding the *last real frame* from right before the crash.
      // Previously nothing here checked freshness, so this method kept
      // returning that one frozen frame ~25x/sec, filling the model's
      // 60-frame buffer with an identical motionless snapshot that gets
      // confidently (and uselessly) classified as incomplete decompression.
      // _novicePoseTimestamp is updated by the bridge only inside a real
      // onResults callback, so gating on its age here reliably detects a
      // dead/reinitialising graph well before the JS-side 3s watchdog even
      // fires, and without depending on the bridge's own recovery flags.
      final lastTimestampMs = js.context['_novicePoseTimestamp'];
      final tsMs = (lastTimestampMs is num) ? lastTimestampMs.toInt() : 0;
      if (tsMs == 0) return null;
      final ageMs = DateTime.now().millisecondsSinceEpoch - tsMs;
      if (ageMs > _maxLandmarkAgeMs) return null;

      // FIX: surfaced by the JS bridge once it's exhausted its own reinit
      // attempts and given up recovering the pose graph for this session --
      // treat it the same as "no landmarks" rather than silently returning
      // whatever stale data happens to be sitting in the globals.
      if (js.context['_novicePoseFailed'] == true) return null;

      final landmarks = js.context['_novicePoseLandmarks'];
      if (landmarks == null) return null;
      final length = landmarks['length'] as int? ?? 0;
      if (length < 33) return null;

      double x(int i) => (landmarks[i]['x'] as num).toDouble();
      double y(int i) => (landmarks[i]['y'] as num).toDouble();
      double v(int i) => (landmarks[i]['visibility'] as num? ?? 0).toDouble();

      final lsx = x(11); final lsy = y(11);
      final rsx = x(12); final rsy = y(12);
      final lex = x(13); final ley = y(13);
      final rex = x(14); final rey = y(14);
      final lwx = x(15); final lwy = y(15);
      final rwx = x(16); final rwy = y(16);
      final lhx = x(23); final lhy = y(23);
      final rhx = x(24); final rhy = y(24);

      final wmx = (lwx + rwx) / 2;
      final wmy = (lwy + rwy) / 2;

      final now = DateTime.now();

      // Velocity is a plain per-frame delta (Δy only, no /dt), matching the
      // units the compression state machine's thresholds in
      // session_provider.dart (_downThreshold = 0.006, _upThreshold =
      // -0.004) and LandmarkMath.wristVelocity are tuned for. Dividing by dt
      // would produce a per-second velocity ~25–30x larger at typical
      // camera frame rates, which would blow through both thresholds on
      // ordinary hand jitter.
      final wristVY = wmy - _prevWristY;
      final wristAY = wristVY - _prevWristVY;
      _prevWristY   = wmy;
      _prevWristVY  = wristVY;

      // Spine verticality is computed in true degrees via
      // LandmarkMath.spineVerticalityDeg (acos of the normalized dot
      // product, not a rescaled cosine), so it's directly comparable to the
      // elbow-lock and posture thresholds elsewhere in the pipeline.
      final smx = (lsx+rsx)/2; final smy = (lsy+rsy)/2;
      final hmx = (lhx+rhx)/2; final hmy = (lhy+rhy)/2;
      final spineVerticality = LandmarkMath.spineVerticalityDeg(smx, smy, hmx, hmy);

      // FIX (overlay misalignment): landmark x/y from MediaPipe are
      // normalized 0.0–1.0 against the <video> element's *native* pixel
      // buffer (video.videoWidth/videoHeight), NOT against the on-screen
      // widget size. Because CameraPreview is displayed with CSS
      // object-fit: cover (cropped/scaled to fill the portrait screen
      // while the camera itself streams a landscape frame), painting
      // these coordinates straight against the canvas size — as
      // PoseOverlayPainter used to — bunches the whole skeleton into a
      // corner instead of over the subject. The bridge already tracks
      // the native size in these globals; we just weren't reading them.
      final videoW = (js.context['_novicePoseVideoWidth'] as num?)?.toDouble() ?? 0.0;
      final videoH = (js.context['_novicePoseVideoHeight'] as num?)?.toDouble() ?? 0.0;

      return LandmarkFrame(
        capturedAt:             now,
        leftShoulderX:          lsx,  leftShoulderY:          lsy,
        rightShoulderX:         rsx,  rightShoulderY:         rsy,
        leftElbowX:             lex,  leftElbowY:             ley,
        rightElbowX:            rex,  rightElbowY:            rey,
        leftWristX:             lwx,  leftWristY:             lwy,
        rightWristX:            rwx,  rightWristY:            rwy,
        leftHipX:               lhx,  leftHipY:               lhy,
        rightHipX:              rhx,  rightHipY:              rhy,
        leftElbowVisibility:    v(13),
        rightElbowVisibility:   v(14),
        leftWristVisibility:    v(15),
        rightWristVisibility:   v(16),
        leftElbowAngle:         LandmarkMath.jointAngleDeg(lsx,lsy,lex,ley,lwx,lwy),
        rightElbowAngle:        LandmarkMath.jointAngleDeg(rsx,rsy,rex,rey,rwx,rwy),
        spineVerticality:       spineVerticality,
        wristMidX:              wmx,
        wristMidY:              wmy,
        shoulderWidth:          (rsx-lsx).abs(),
        wristVelocityY:         wristVY,
        wristAccelerationY:     wristAY,
        meanLandmarkConfidence: (v(11)+v(12)+v(13)+v(14)+v(15)+v(16))/6,
        sourceVideoWidth:       videoW,
        sourceVideoHeight:      videoH,
      );
    } catch (e) {
      debugPrint('[PoseServiceWeb] frame error: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {}
}