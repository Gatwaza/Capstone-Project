// Covers TrainingScreen (lib/features/training/training_screen.dart) — the
// screen flagged in integration_test/README.md as "highest-value but needs
// work first" because it drives the camera + pose bridge (PoseServiceWeb)
// and InferenceServiceWeb (hosted TCN API) through SessionProvider's
// LiveSessionNotifier.
//
// Unlocked by two GetIt overrides in test_helpers.dart:
//   - overridePoseServiceForTesting()      — swaps PoseServiceInterface for
//     FakePoseService, a normal interface swap (PoseServiceWeb already
//     implements PoseServiceInterface).
//   - overrideInferenceServiceForTesting() — swaps InferenceServiceWeb for
//     FakeInferenceService, a noSuchMethod-based fake (InferenceServiceWeb
//     is a concrete class with no interface — same technique as
//     NoopTelemetryService).
//
// Both fakes bypass dart:js/MediaPipe/the hosted TCN API entirely, so this
// test does NOT exercise the real pose-estimation or ML-inference pipeline
// — it exercises the real widget, the real LiveSessionNotifier state
// machine (hand-placement gating, compression debouncing, accuracy
// accumulation), and the real GetIt/Riverpod wiring around them.
//
// The camera itself is NOT faked (CameraController has no injectable seam)
// — TrainingScreen's _initCamera() calls the real `camera` plugin, which on
// web means a real getUserMedia() call. Running this file therefore
// requires Chrome to be launched with a synthetic camera device, or
// _initCamera() will hang on a real permission prompt with nothing to grant
// it against in a headless run:
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/training_flow_test.dart \
//     -d chrome \
//     --web-browser-flag="--use-fake-device-for-media-stream" \
//     --web-browser-flag="--use-fake-ui-for-media-stream"
//
// (the second flag auto-accepts the camera permission prompt; without it
// Chrome will still ask, and nothing here answers that dialog).
//
// TIMING NOTE (the fix that makes this test actually pass):
// TrainingScreen's web pose loop (_startWebPoseLoop, the Timer.periodic
// that calls PoseServiceInterface.processFrame()/onFrame() every ~40ms)
// does NOT start the moment the camera is ready. It only starts after
// _waitForPoseBridgeReady() resolves — and that poller waits for
// `window._novicePoseReady` to be set by the REAL MediaPipe JS bridge's
// onResults callback, which never fires under FakePoseService (MediaPipe
// never runs). So that poller always falls through to its full 4-second
// `maxWait` timeout before _startWebPoseLoop() is ever called.
//
// "Start Session" becomes tappable as soon as the camera itself is ready
// (independent of the pose-bridge poller), so tapping it happens well
// before the pose loop has started firing. Any pump budget after tapping
// Start must therefore cover that ~4s dead time FIRST, and only THEN a few
// FakePoseService cycles (~640ms/cycle) on top — not just cycles alone, or
// compressions will read 0 even though the state machine and the fake are
// both working correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/di/injection.dart';
import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/training/training_screen.dart';
import 'package:novice/providers/session_provider.dart';
import 'package:novice/services/participant_service.dart';
import 'package:novice/services/platform/inference_service_web.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  setUpAll(() async {
    // Same eager-read-in-field-initializer problem ConsentScreen has (see
    // enrollment_flow_test.dart) — TrainingScreen reads
    // getIt<PoseServiceInterface>() in initState, so GetIt needs a real
    // registration in place before configureDependencies() is skipped on a
    // second run in the same test process.
    if (!GetIt.instance.isRegistered<ParticipantService>()) {
      await configureDependencies();
    }
    overridePoseServiceForTesting();
    overrideInferenceServiceForTesting();
  });

  testWidgets(
      'start session -> confirmed compressions accumulate -> task accuracy readout',
      (tester) async {
    await tester.pumpWidget(wrap(const TrainingScreen(participantId: 'P999')));

    // Camera init (real getUserMedia against the fake device) runs on real
    // timers under IntegrationTestWidgetsFlutterBinding. "Start Session"
    // appears as soon as _cameraReady flips true — this is independent of
    // (and typically much faster than) the pose-bridge readiness poller
    // below, so this loop settles quickly; it is NOT the thing waiting out
    // the 4s pose-bridge timeout. Once the pose loop starts it drives
    // continuous state updates, so pumpAndSettle() would never settle —
    // pump a fixed number of times instead, same approach app_test.dart
    // uses for the splash-screen redirect.
    var settled = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Start Session').evaluate().isNotEmpty) {
        settled = true;
        break;
      }
    }
    expect(settled, isTrue,
        reason: 'Camera never reached _cameraReady — if this fails, confirm '
            'Chrome was launched with --use-fake-device-for-media-stream '
            'and --use-fake-ui-for-media-stream (see file header).');
    expect(find.text('Start Session'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Start Session'));
    await tester.pump();

    expect(find.text('Stop Session'), findsOneWidget);

    // Read live state straight from the real ProviderScope container rather
    // than parsing HUD text — robust to copy changes and exercises exactly
    // what LiveSessionNotifier.onFrame() actually computed.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrainingScreen)),
    );

    expect(container.read(liveSessionProvider).isActive, isTrue);
    expect(container.read(liveSessionProvider).participantId, 'P999');

    // Budget: ~4s for _waitForPoseBridgeReady's real-time timeout to elapse
    // (window._novicePoseReady is never set under FakePoseService, so this
    // poller always runs out its full maxWait before _startWebPoseLoop()
    // is even called) PLUS several full FakePoseService cycles once the
    // loop actually starts (~640ms/cycle — see FakePoseService's class doc
    // in test_helpers.dart). 45 x 200ms = 9000ms covers the 4s dead time
    // with margin, plus ~6 full cycles afterward — comfortably clears the
    // _minConfirmedCompressionsForScore-adjacent debounce/amplitude/timing
    // gates in session_provider.dart even accounting for pump-cadence
    // jitter.
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final session = container.read(liveSessionProvider);
    expect(session.compressions, greaterThan(0),
        reason: 'No confirmed compressions after the pose-bridge timeout + '
            'several fake cycles — if this fails, check whether '
            '_waitForPoseBridgeReady\'s maxWait in training_screen.dart '
            'changed (currently assumed ~4s), or whether the debounced '
            'state machine in session_provider.dart changed its amplitude/'
            'interval thresholds.');
    expect(session.modelAvailable, isTrue,
        reason: 'FakeInferenceService always returns isSimulated=false; '
            'modelAvailable should track that.');
    expect(session.taskAccuracies['rate'], closeTo(1.0, 0.01));
    expect(session.taskAccuracies['depth'], closeTo(1.0, 0.01));
    expect(session.taskAccuracies['recoil'], closeTo(1.0, 0.01));

    // Confirms LiveSessionNotifier is really talking to the overridden
    // FakeInferenceService (not a stale real singleton): resetSession() runs
    // once at startSession(), and infer() runs once per assessed frame.
    final fakeInference =
        GetIt.instance<InferenceServiceWeb>() as FakeInferenceService;
    expect(fakeInference.calls, contains('resetSession'));
    expect(fakeInference.calls.where((c) => c == 'infer').length,
        greaterThan(0));
  });
}