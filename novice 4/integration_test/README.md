# Novice — integration_test suite

## Run it

Web is a special case: `flutter test -d chrome` only supports mobile/desktop
integration tests. Web still goes through the older `flutter drive` command, which
needs `chromedriver` running alongside it and the `test_driver/integration_test.dart`
bridge file (already added).

**One-time setup — install chromedriver** (must match your installed Chrome's major
version; check yours at `chrome://version`):

```bash
brew install chromedriver
# or download the matching version directly:
# https://googlechromelabs.github.io/chrome-for-testing/
```

macOS will likely block it the first run as an unverified developer. If so:

```bash
xattr -d com.apple.quarantine $(which chromedriver)
```

**Every run — two terminals, both from inside `novice 4/`:**

Terminal 1 — start chromedriver and leave it running:

```bash
chromedriver --port=4444
```

Terminal 2 — drive the test:

```bash
flutter pub get
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome
```

Get that one green first — it's the baseline. Then, same pattern, swap `--target`:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/participant_gate_flow_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/consent_flow_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/enrollment_flow_test.dart -d chrome
```

There's no single "run the whole `integration_test/` folder" command on web the way
`flutter test integration_test -d chrome` would work on mobile — `--target` takes one
file per `flutter drive` invocation, so each spec above is its own command.

**Expected output** on success ends with something like:

```
00:03 +1: All tests passed!
```

If `flutter drive` hangs immediately with no output, chromedriver isn't running or is
on the wrong port — confirm Terminal 1 shows `Only local connections are allowed` and
`ChromeDriver was started successfully` before running Terminal 2.

## What's actually covered right now

- **app_test.dart** — the app boots via the real `main()` and reaches the home screen.
- **participant_gate_flow_test.dart** — the unconfigured-backend state: warning banner
  shown, "Register as a new participant" disabled, "Continue to training" disabled with
  nothing selected.
- **consent_flow_test.dart** — info step → form step → consent checkbox unlocking
  submit → the "Enrolment failed" snackbar when the backend isn't configured.
- **enrollment_flow_test.dart** — the happy path: info step → form step → submit →
  "Participant Enrolled" with the assigned ID shown, using a `ParticipantService`
  backed by an `http.MockClient` (see `test_helpers.dart`) instead of a real
  Supabase call.

The unconfigured-backend tests (participant_gate_flow_test.dart, consent_flow_test.dart)
still run against a real unconfigured Env on purpose — that's a real, reachable state of
the app, not a shortcut, and it's a genuinely different code path from the mocked one in
enrollment_flow_test.dart (both are worth keeping).

## Happy-path enrolment — now unblocked

`ParticipantService` (`lib/services/participant_service.dart`) now takes an optional
`http.Client` in its constructor (defaults to a real `http.Client()`), so tests can pass
an `http.MockClient` — from `package:http/testing.dart`, already shipped inside the
`http` package, no extra dependency needed. `test_helpers.dart`'s
`overrideParticipantServiceForTesting()` re-registers `ParticipantService` in GetIt with
a `MockClient` that fakes Supabase's `201` response, then `enrollment_flow_test.dart`
exercises the real UI flow against it.

Run it the same way as the others:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/enrollment_flow_test.dart -d chrome
```

## Training — now covered, with a caveat on the camera

`training_flow_test.dart` covers `TrainingScreen`'s happy path: start a session,
let a fake pose stream drive several confirmed compression cycles through the real
`LiveSessionNotifier` state machine, and assert `compressions > 0`,
`modelAvailable == true`, and `taskAccuracies` all read back 100% — read straight off
the real `ProviderScope` container rather than parsed from HUD text.

Two GetIt overrides in `test_helpers.dart` make this possible:

- **`overridePoseServiceForTesting()`** swaps `PoseServiceInterface` for
  `FakePoseService` — a normal interface swap, since `PoseServiceWeb` already
  implements `PoseServiceInterface`.
- **`overrideInferenceServiceForTesting()`** swaps `InferenceServiceWeb` for
  `FakeInferenceService` — `InferenceServiceWeb` is a concrete class with no
  interface, so this uses the same `noSuchMethod`-based fake technique as
  `NoopTelemetryService` above, with real overrides only for the methods
  `session_provider.dart` actually calls (`infer`, `resetSession`,
  `notifyCompressionCompleted`, `isModelLoaded`, `init`, `dispose`).

Both fakes bypass `dart:js`/MediaPipe/the hosted TCN API entirely — this test does
**not** exercise real pose estimation or ML inference. What it does exercise: the real
widget, the real debounced compression state machine (hand-placement gating,
amplitude/interval checks), and the real GetIt/Riverpod wiring connecting them.

**The camera itself is not faked** — `CameraController` has no injectable seam, so
`TrainingScreen._initCamera()` makes a real `getUserMedia()` call. Run this file with a
synthetic camera device or it will hang on a permission prompt nothing answers:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/training_flow_test.dart \
  -d chrome \
  --web-browser-flag="--use-fake-device-for-media-stream" \
  --web-browser-flag="--use-fake-ui-for-media-stream"
```

(`--use-fake-ui-for-media-stream` auto-accepts the permission prompt; without it,
Chrome still asks and the test has no way to grant it.) These two flags are harmless to
add to the other `flutter drive` commands above too, if you'd rather standardize on one
invocation.

## Screens not yet covered: results / history / settings

These mostly read from `StorageService` (real `SharedPreferences`, no network) plus
Riverpod providers, so they're more straightforward now that training produces a real
session to read back.

## Does this replace Cypress?

For Novice specifically — yes, effectively. Flutter web renders to a `<canvas>`
(CanvasKit/Skwasm), so Cypress's `cy.get()` has no DOM to grab unless
`Semantics(label: ...)` wrappers are added across the app and the accessibility tree is
forced on for the test build. `integration_test` drives the real widget tree directly —
no DOM, no labels, no translation layer — which is also the more defensible choice to
cite in a capstone's system-testing chapter, since it's Flutter's own tool for this job
rather than a browser-testing tool retrofitted onto a canvas app. The earlier Cypress
scaffold and its `Semantics` requirements can be set aside unless a specific reason comes
up to test through the DOM instead.