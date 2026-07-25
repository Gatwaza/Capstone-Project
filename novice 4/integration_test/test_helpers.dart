// Test-only overrides for services `configureDependencies()` (injection.dart)
// registers as real, network/browser-backed singletons.
//
// Deliberately NOT touching injection.dart. main() still runs unmodified —
// call these AFTER app.main() to swap specific GetIt registrations before
// pumping a fresh screen that reads from them.
//
// Honest scope: TtsService and TelemetryService are concrete classes with
// no interface, so "override" here means re-registering a lightweight real
// instance where possible, not a mock.
//
// ParticipantService (as of the http.Client constructor seam added below)
// CAN now be faked: pass an `http.MockClient` — from `package:http/testing.dart`,
// already shipped inside the `http` package, no extra dependency — via the
// `client:` constructor parameter, then re-register it with GetIt before
// pumping ConsentScreen/ParticipantGateScreen. See
// overrideParticipantServiceForTesting() below and
// enrollment_flow_test.dart for the happy-path test that uses it.
// participant_gate_flow_test.dart and consent_flow_test.dart intentionally
// still leave Env unconfigured and assert on the "not configured" UI path —
// that's a real, reachable state of the app, not a stand-in for the mock.

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:novice/core/di/injection.dart';
import 'package:novice/models/landmark_frame.dart';
import 'package:novice/models/session_model.dart';
import 'package:novice/services/participant_service.dart';
import 'package:novice/services/platform/inference_service_web.dart';
import 'package:novice/services/platform/pose_service_interface.dart';
import 'package:novice/services/platform/telemetry_service.dart';

/// Replaces the TelemetryService singleton with a no-op so tests don't
/// write real rows to Supabase on every run.
class NoopTelemetryService implements TelemetryService {
  final List<String> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString());
    return null;
  }
}

void overrideTelemetryForTesting() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<TelemetryService>()) {
    getIt.unregister<TelemetryService>();
  }
  getIt.registerSingleton<TelemetryService>(NoopTelemetryService());
}

/// Replaces the ParticipantService singleton with one backed by a
/// MockClient that simulates Supabase's REST response for a successful
/// registration (201, returning a fake assigned participant_id).
///
/// [supabaseUrl]/[anonKey] are dummy non-empty values so
/// `ParticipantService.isConfigured` is true — otherwise
/// `registerParticipant()` throws before ever reaching the mock client,
/// same as the real "not configured" path the other flow tests cover.
void overrideParticipantServiceForTesting({
  String assignedParticipantId = 'P999',
}) {
  final getIt = GetIt.instance;
  final mockClient = MockClient((request) async {
    if (request.method == 'POST') {
      return http.Response(
        jsonEncode([
          {'participant_id': assignedParticipantId},
        ]),
        201,
      );
    }
    // GET (listParticipants / participantExists) — empty result is enough
    // for tests that only exercise the registration path.
    return http.Response(jsonEncode([]), 200);
  });

  if (getIt.isRegistered<ParticipantService>()) {
    getIt.unregister<ParticipantService>();
  }
  getIt.registerSingleton<ParticipantService>(
    ParticipantService(
      supabaseUrl: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
      client: mockClient,
    ),
  );
}

// ── Training-flow fakes ──────────────────────────────────────────────────
//
// InferenceServiceWeb is a concrete class with no interface (same problem
// ParticipantService had before its http.Client seam) — but unlike
// ParticipantService, adding a constructor seam here would mean threading a
// fake through the hosted-TCN-API call chain, dart:js globals, and several
// stateful rolling-window buffers. Faking the whole class via `implements`
// + noSuchMethod (same pattern as NoopTelemetryService above) is far less
// invasive: only the methods session_provider.dart actually calls
// (infer/resetSession/notifyCompressionCompleted/isModelLoaded/init/dispose)
// are given real bodies below; anything else falls through to noSuchMethod.
// Dart allows a class to `implements` a concrete type without overriding
// every member as long as it also defines noSuchMethod — the analyzer
// treats the noSuchMethod override as satisfying the rest of the interface
// (the same mechanism mockito's `Mock` base class relies on).
class FakeInferenceService implements InferenceServiceWeb {
  final List<String> calls = [];

  @override
  bool get isModelLoaded => true;

  @override
  Future<void> init() async {
    calls.add('init');
  }

  @override
  void resetSession() {
    calls.add('resetSession');
  }

  @override
  void notifyCompressionCompleted() {
    calls.add('notifyCompressionCompleted');
  }

  /// Always reports a confident "Correct" 3-task result so a training-flow
  /// test can exercise the real accuracy-accumulation path in
  /// session_provider.dart (isCompressionMotion-gated rate/depth/recoil
  /// accumulation, modelAvailable, taskAccuracies) without depending on the
  /// hosted TCN API being reachable.
  @override
  InferenceResult infer(LandmarkFrame frame) {
    calls.add('infer');
    return InferenceResult(
      timestamp: DateTime.now(),
      topClassIndex: 0,
      topClassLabel: 'correct_compression',
      topClassConfidence: 0.95,
      allClassScores: const {
        'rate_Correct': 0.95,
        'depth_Correct': 0.95,
        'recoil_Complete': 0.95,
      },
      currentBpm: 110,
      estimatedDepthCm: 5.5,
      elbowAngleMean: (frame.leftElbowAngle + frame.rightElbowAngle) / 2,
      spineVerticalityDeg: frame.spineVerticality,
      rateAccuracy: 1.0,
      rateConfidence: 0.95,
      depthAccuracy: 1.0,
      depthConfidence: 0.95,
      recoilAccuracy: 1.0,
      recoilConfidence: 0.95,
      rateLabel: 'Correct',
      depthLabel: 'Correct',
      recoilLabel: 'Complete',
      isSimulated: false,
      isFreshPrediction: true,
    );
  }

  @override
  void dispose() {
    calls.add('dispose');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void overrideInferenceServiceForTesting() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<InferenceServiceWeb>()) {
    getIt.unregister<InferenceServiceWeb>();
  }
  getIt.registerSingleton<InferenceServiceWeb>(FakeInferenceService());
}

/// Fakes the pose bridge entirely, bypassing dart:js / MediaPipe / the
/// hosted TCN API's real camera pipeline. PoseServiceWeb already implements
/// PoseServiceInterface (see pose_service_interface.dart) so — unlike
/// InferenceServiceWeb — this one is a normal interface swap, no
/// noSuchMethod needed.
///
/// Emits a repeating, geometrically-valid compression cycle (correct hand
/// placement, wrist oscillating between two points a fixed torso-relative
/// distance apart) so LiveSessionNotifier's real state machine —
/// _classifyActivity / _updateCompressionCount / hand-placement gating in
/// session_provider.dart — has real motion to debounce into confirmed
/// compressions, the same way it would from a real MediaPipe stream.
///
/// Cycle shape (16 calls to processFrame — TrainingScreen's web loop calls
/// this every ~40ms/25fps, so ~640ms/cycle, ~94 "compressions"/min):
///   frames 0-7   descend  wristMidY 0.44 -> 0.55 (Δ=0.01375/frame, > the
///                0.012 compressionVelocityThreshold session_provider.dart
///                gates on)
///   frames 8-15  ascend   wristMidY 0.55 -> 0.44
/// A completed cycle is registered by session_provider.dart's own debounced
/// state machine on the first ascending frame — this fake only supplies the
/// raw landmark motion, it doesn't count compressions itself.
class FakePoseService implements PoseServiceInterface {
  int _tick = 0;
  double _prevWristY = _restY;
  double _prevVelocityY = 0;

  static const double _shoulderMidX = 0.50;
  static const double _shoulderWidth = 0.20; // rightShoulderX - leftShoulderX
  static const double _shoulderY = 0.30;
  static const double _hipY = 0.65; // torsoHeight = 0.35
  static const double _restY = 0.44; // normPosY ≈ 0.40 — inside [0.35,0.75]
  static const double _pressY = 0.55; // normPosY ≈ 0.71 — inside [0.35,0.75]
  static const int _halfCycleFrames = 8;

  @override
  Future<LandmarkFrame?> processFrame(CameraImage? image, dynamic rotation) async {
    final phase = _tick % (2 * _halfCycleFrames);
    final descending = phase < _halfCycleFrames;
    final step = (_pressY - _restY) / _halfCycleFrames;
    final wristY = descending
        ? _restY + step * phase
        : _pressY - step * (phase - _halfCycleFrames);
    _tick++;

    const leftShoulderX = _shoulderMidX - _shoulderWidth / 2;
    const rightShoulderX = _shoulderMidX + _shoulderWidth / 2;
    const leftHipX = _shoulderMidX - 0.08;
    const rightHipX = _shoulderMidX + 0.08;
    const leftWristX = _shoulderMidX - 0.01;
    const rightWristX = _shoulderMidX + 0.01;

    final velocityY = wristY - _prevWristY;
    final accelerationY = velocityY - _prevVelocityY;
    _prevWristY = wristY;
    _prevVelocityY = velocityY;

    final frame = LandmarkFrame(
      capturedAt: DateTime.now(),
      leftShoulderX: leftShoulderX, leftShoulderY: _shoulderY,
      rightShoulderX: rightShoulderX, rightShoulderY: _shoulderY,
      leftElbowX: leftShoulderX - 0.02, leftElbowY: _shoulderY + 0.12,
      rightElbowX: rightShoulderX + 0.02, rightElbowY: _shoulderY + 0.12,
      leftWristX: leftWristX, leftWristY: wristY,
      rightWristX: rightWristX, rightWristY: wristY,
      leftHipX: leftHipX, leftHipY: _hipY,
      rightHipX: rightHipX, rightHipY: _hipY,
      leftElbowVisibility: 1.0,
      rightElbowVisibility: 1.0,
      leftWristVisibility: 1.0,
      rightWristVisibility: 1.0,
      leftElbowAngle: 175.0,
      rightElbowAngle: 175.0,
      spineVerticality: 5.0,
      wristMidX: (leftWristX + rightWristX) / 2,
      wristMidY: wristY,
      shoulderWidth: _shoulderWidth,
      wristVelocityY: velocityY,
      wristAccelerationY: accelerationY,
      allLandmarksVisible: true,
      meanLandmarkConfidence: 1.0,
      sourceVideoWidth: 640,
      sourceVideoHeight: 480,
    );
    return frame;
  }

  @override
  Future<void> dispose() async {}
}

void overridePoseServiceForTesting() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<PoseServiceInterface>()) {
    getIt.unregister<PoseServiceInterface>();
  }
  getIt.registerSingleton<PoseServiceInterface>(FakePoseService());
}