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

That last point matters: these tests run against an **unconfigured** backend on purpose
(no `SUPABASE_URL`/`SUPABASE_ANON_KEY` via `--dart-define`), because that's a real,
reachable state of the app — not a shortcut. They do **not** cover the happy path
(a participant actually getting registered, reaching "Participant Enrolled", the
returning-participant dropdown populated with real IDs).

## Why the happy path isn't here yet

`ParticipantService` (`lib/services/participant_service.dart`) builds its own
`http.Client` internally and has no constructor seam to inject one. That means a
test can't hand it a `MockClient` that returns a fake `201` — there's nothing to swap.
Two ways to unblock this, pick one before writing happy-path tests:

1. Add an `http.Client` parameter to `ParticipantService`'s constructor (defaulting to
   `http.Client()`), then register a `MockClient` via a `test_helpers.dart` override
   before pumping `ConsentScreen`/`ParticipantGateScreen`.
2. Point `SUPABASE_URL`/`SUPABASE_ANON_KEY` at a real (or local) Supabase instance for
   the test run and accept that these become slower, network-dependent tests.

(1) is the standard pattern and is what `test_helpers.dart` already assumes — it's just
not built into `ParticipantService` yet.

## Screens not yet covered: training / results / history / settings

Training in particular needs its own pass, not a quick add:

- `TrainingScreen` drives the camera + pose bridge (`PoseServiceWeb`) and
  `InferenceServiceWeb` (hosted TCN API) through `SessionProvider`'s
  `LiveSessionNotifier` — a real integration test needs a fake `InferenceServiceWeb`
  registered in place of the real one (same GetIt-override pattern as
  `test_helpers.dart`, but `InferenceServiceWeb` is a concrete class too, so faking it
  needs the same kind of injectable seam discussed above, or a `noSuchMethod`-based fake
  like `NoopTelemetryService`).
- Results/History/Settings mostly read from `StorageService` (real
  `SharedPreferences`, no network) plus Riverpod providers, so they're more
  straightforward once a session actually exists to read back — which depends on
  training working first.

Want these built next? Training is the highest-value one but also the one that needs
the InferenceServiceWeb fake sorted out first — worth doing as its own step rather than
bolting it onto this batch.

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