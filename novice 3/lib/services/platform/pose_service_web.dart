// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

// Web-only file — only compiled when targeting Flutter Web.
// Registers JavaScript interop with @mediapipe/pose loaded in web/index.html.

@JS()
library novice_pose_web;

import 'package:js/js.dart';
import 'package:camera/camera.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/landmark_math.dart';
import '../../models/landmark_frame.dart';
import 'pose_service_interface.dart';

// ── JS interop declarations ───────────────────────────────
// These match the @mediapipe/pose JavaScript API loaded via
// <script src="https://cdn.jsdelivr.net/npm/@mediapipe/pose/pose.js">
// in web/index.html.

@JS('NovicePoseBridge.getLatestFrame')
external _JsLandmarkFrame? _getLatestFrame();

@JS('NovicePoseBridge.isReady')
external bool _isPoseReady();

// Minimal JS landmark structure (normalized 0–1 coords)
@JS()
@anonymous
class _JsLandmark {
  external double get x;
  external double get y;
  external double get visibility;
}

@JS()
@anonymous
class _JsLandmarkFrame {
  external List<dynamic> get landmarks;
  external double get timestamp;
}

/// Web pose estimation — reads frames written by the JS bridge
/// (web/flutter_pose_bridge.js) into a shared JS object.
///
/// Architecture:
///   Flutter Web ──JS interop──► NovicePoseBridge (JS)
///                                     │
///                              @mediapipe/pose WASM
///                                     │
///                              camera feed (getUserMedia)
///
/// The JS bridge is injected via web/index.html and runs
/// MediaPipe in a web worker, writing results to window.NovicePoseBridge.
///
/// TODO: Implement web/flutter_pose_bridge.js (Phase 2 web integration).
/// For Phase 1 demo, this returns null and the training screen
/// shows the simulation overlay.
class PoseServiceWeb implements PoseServiceInterface {
  LandmarkFrame? _previousFrame;

  @override
  Future<LandmarkFrame?> processFrame(CameraImage image, dynamic rotation) async {
    // Check if JS bridge is available (Phase 2)
    try {
      if (!_isPoseReady()) return null;
      final jsFrame = _getLatestFrame();
      if (jsFrame == null) return null;
      return _convertJsFrame(jsFrame);
    } catch (_) {
      // JS bridge not yet loaded — Phase 1 demo mode
      return null;
    }
  }

  LandmarkFrame? _convertJsFrame(_JsLandmarkFrame jsFrame) {
    // MediaPipe landmark indices (same as mobile)
    const LS = 11; const RS = 12;
    const LE = 13; const RE = 14;
    const LW = 15; const RW = 16;
    const LH = 23; const RH = 24;

    final lms = jsFrame.landmarks;
    if (lms.length < 25) return null;

    _JsLandmark lm(int i) => lms[i] as _JsLandmark;

    final ls = lm(LS); final rs = lm(RS);
    final le = lm(LE); final re = lm(RE);
    final lw = lm(LW); final rw = lm(RW);
    final lh = lm(LH); final rh = lm(RH);

    final visScores = [ls.visibility, rs.visibility, le.visibility,
                       re.visibility, lw.visibility, rw.visibility];
    final meanConf = visScores.reduce((a, b) => a + b) / visScores.length;
    if (meanConf < AppConstants.minLandmarkVisibility) return null;

    final leAngle = LandmarkMath.jointAngleDeg(ls.x, ls.y, le.x, le.y, lw.x, lw.y);
    final reAngle = LandmarkMath.jointAngleDeg(rs.x, rs.y, re.x, re.y, rw.x, rw.y);
    final shoulderMidX = (ls.x + rs.x) / 2;
    final shoulderMidY = (ls.y + rs.y) / 2;
    final spineAngle = LandmarkMath.spineVerticalityDeg(
      shoulderMidX, shoulderMidY,
      (lh.x + rh.x) / 2, (lh.y + rh.y) / 2,
    );
    final wristMidY = (lw.y + rw.y) / 2;
    double velY = 0, accY = 0;
    final prev = _previousFrame;
    if (prev != null) {
      velY = LandmarkMath.wristVelocity(wristMidY, prev.wristMidY);
      accY = velY - prev.wristVelocityY;
    }

    final frame = LandmarkFrame(
      capturedAt: DateTime.fromMillisecondsSinceEpoch(jsFrame.timestamp.toInt()),
      leftShoulderX: ls.x,  leftShoulderY: ls.y,
      rightShoulderX: rs.x, rightShoulderY: rs.y,
      leftElbowX: le.x,     leftElbowY: le.y,
      rightElbowX: re.x,    rightElbowY: re.y,
      leftWristX: lw.x,     leftWristY: lw.y,
      rightWristX: rw.x,    rightWristY: rw.y,
      leftHipX: lh.x,       leftHipY: lh.y,
      rightHipX: rh.x,      rightHipY: rh.y,
      leftElbowVisibility: le.visibility,
      rightElbowVisibility: re.visibility,
      leftWristVisibility: lw.visibility,
      rightWristVisibility: rw.visibility,
      leftElbowAngle: leAngle,
      rightElbowAngle: reAngle,
      spineVerticality: spineAngle,
      wristMidX: (lw.x + rw.x) / 2,
      wristMidY: wristMidY,
      shoulderWidth: LandmarkMath.distance2d(ls.x, ls.y, rs.x, rs.y),
      wristVelocityY: velY,
      wristAccelerationY: accY,
      allLandmarksVisible: meanConf >= AppConstants.minLandmarkVisibility,
      meanLandmarkConfidence: meanConf,
    );
    _previousFrame = frame;
    return frame;
  }

  @override
  Future<void> dispose() async {}
}
