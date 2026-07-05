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
      );
    } catch (e) {
      debugPrint('[PoseServiceWeb] frame error: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {}
}