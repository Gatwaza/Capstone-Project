// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../models/landmark_frame.dart';
import 'pose_service_interface.dart';

class PoseServiceWeb implements PoseServiceInterface {
  DateTime? _lastFrameTime;
  double _prevWristY  = 0;
  double _prevWristVY = 0;

  @override
  Future<LandmarkFrame?> processFrame(CameraImage image, dynamic rotation) async {
    try {
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
      final dt  = _lastFrameTime != null
          ? now.difference(_lastFrameTime!).inMilliseconds / 1000.0
          : 0.033;
      _lastFrameTime = now;

      final wristVY = dt > 0 ? (wmy - _prevWristY)  / dt : 0.0;
      final wristAY = dt > 0 ? (wristVY - _prevWristVY) / dt : 0.0;
      _prevWristY   = wmy;
      _prevWristVY  = wristVY;

      double elbowAngle(double ax, double ay, double bx, double by, double cx, double cy) {
        final v1x = ax-bx; final v1y = ay-by;
        final v2x = cx-bx; final v2y = cy-by;
        final dot = v1x*v2x + v1y*v2y;
        final mag = (v1x*v1x + v1y*v1y) * (v2x*v2x + v2y*v2y);
        if (mag <= 0) return 180;
        return (180/3.14159265) * (dot / mag.abs()).clamp(-1.0, 1.0).abs();
      }

      final smx = (lsx+rsx)/2; final smy = (lsy+rsy)/2;
      final hmx = (lhx+rhx)/2; final hmy = (lhy+rhy)/2;
      final spineVerticality = (smx-hmx).abs() / ((smy-hmy).abs() + 0.001) * 90;

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
        leftElbowAngle:         elbowAngle(lsx,lsy,lex,ley,lwx,lwy),
        rightElbowAngle:        elbowAngle(rsx,rsy,rex,rey,rwx,rwy),
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