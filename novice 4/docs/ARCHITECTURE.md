# Novice — System Architecture

**GNU GPL v3 · Jean Robert Gatwaza / African Leadership University**

---

## High-Level Overview

Novice is a Flutter Web application. All ML inference runs via a hosted REST API (Hugging Face Spaces). The Flutter mobile code (`pose_service_mobile.dart`, `inference_service.dart`) is preserved for future native builds but is not in the current deployed path.

The app has two distinct runtime modes:

| Mode | Entry point | ML involved |
|------|------------|-------------|
| **Procedures hub** | `/procedures` (DemoScreen, `isHub: true`) | None — animated SVG guides |
| **CPR live training** | `/training/:participantId` (TrainingScreen) | MediaPipe Pose + TCN API |

---

## Navigation / Routing

Routes are defined in `lib/core/router/app_router.dart` using GoRouter with **path URL strategy** (no hash — see `main.dart`: `usePathUrlStrategy()` called before `runApp`).

```
/                   SplashScreen         → auto-navigates to /procedures after 2.4 s
/procedures         DemoScreen(isHub)    → procedures hub (post-splash landing)
/home               HomeScreen           → session history dashboard
/participant        ParticipantGateScreen
/training/:id       TrainingScreen
/results/:id        ResultsScreen
/history            HistoryScreen
/demo               DemoScreen           → standalone demo mode
/settings           SettingsScreen
/research/consent   ConsentScreen
/research/survey/pre/:id   SurveyScreen(preSession)
/research/survey/post/:id  SurveyScreen(postSession)
/research/dashboard ResearcherDashboard
```

### JS ↔ Flutter navigation bridge

The landing page HTML (inside `web/index.html`) can trigger Flutter navigation before Flutter has mounted. The bridge works as follows:

1. `main.dart` registers `window._noviceFlutterNavigate(route)` via `dart:js` interop once Flutter is up.
2. The landing page calls `window._noviceFlutterNavigate('/participant')` when a CTA is tapped.
3. `_GoRouterWrapper.navigateTo(route)` calls `router.go(route)`.
4. `window._noviceShowBackButton()` is registered in parallel — the landing page calls it to reveal a back-to-landing chevron after navigating into Flutter.

---

## Runtime Data Flow — CPR Live Training

```
┌─────────────────────────────────────────────────────────────────────────┐
│  web/index.html                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  window.__NOVICE_CONFIG__ = {supabaseUrl, supabaseAnonKey, pin}    │ │
│  │  (injected by scripts/vercel_build.sh from Vercel env vars;        │ │
│  │   for local dev: manually added inside <head>)                     │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │  flutter_pose_bridge.js                                            │ │
│  │  @mediapipe/pose WASM                                              │ │
│  │  → writes window._novicePoseLandmarks  (33 landmark objects)      │ │
│  │  → sets   window._novicePoseReady = true  after 1st valid frame   │ │
│  │  → sets   window._novicePoseVideoReady = true  once video.width>0 │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
        │ JS globals
        ▼
┌───────────────────┐   ~25 fps    ┌──────────────────────────────────┐
│  TrainingScreen   │─────────────►│  PoseServiceWeb                  │
│  (poll loop,      │              │  reads _novicePoseLandmarks       │
│   starts only     │              │  guards: _novicePoseVideoReady    │
│   after Pose-     │              │  computes per-frame Δ (velocity,  │
│   Ready flag)     │              │  acceleration) in Dart            │
└───────────────────┘              └──────────────┬───────────────────┘
                                                  │ LandmarkFrame
                                                  ▼
                                   ┌──────────────────────────────────┐
                                   │  LandmarkMath.buildFeatureVector  │
                                   │  12 dims per frame               │
                                   └──────────────┬───────────────────┘
                                                  │ [12 floats]
                                                  ▼
                                   ┌──────────────────────────────────┐
                                   │  InferenceServiceWeb             │
                                   │  60-frame sliding window buffer  │
                                   │  throttle: 1 API call / 600 ms   │
                                   │  cache TTL: 1500 ms              │
                                   │  isFreshPrediction flag          │
                                   └──────────────┬───────────────────┘
                                        │ HTTP POST (60×12)
                                        ▼
                          ┌─────────────────────────────┐
                          │  jeanrobert-novice.hf.space  │
                          │  FastAPI / TCN (Python)      │
                          │  → rate   {label, conf}      │
                          │  → depth  {label, conf}      │
                          │  → recoil {label, conf}      │
                          └─────────────┬───────────────┘
                                        │ InferenceResult
                                        ▼
                        ┌───────────────────────────────────────┐
                        │  LiveSessionNotifier (Riverpod)        │
                        │  onFrame():                            │
                        │    accumulate rate/depth/recoil        │
                        │    accuracy — isFreshPrediction only   │
                        │    count compressions (velocity gate)  │
                        │    update bpm, depthCm, cprFraction   │
                        │  stopSession():                        │
                        │    build SessionModel v2               │
                        │    StorageService.saveSession()        │
                        │    TelemetryService.uploadSession() ↗  │
                        └─────────────┬─────────────────────────┘
                                      │ InferenceResult
                                      ▼
                        ┌───────────────────────────────────────┐
                        │  FeedbackEngine                        │
                        │  error cooldown: 4 s                   │
                        │  same-error repeat: 8 s               │
                        │  correct: silent (praise @ 10-streak) │
                        └─────────────┬─────────────────────────┘
                                      │ FeedbackPrompt (when shouldSpeak)
                                      ▼
                        ┌───────────────────────────────────────┐
                        │  TtsService                            │
                        │  EN: Web Speech API                    │
                        │  RW: Umuganda HTTP (→ EN fallback)    │
                        │  non-interrupting: skips if speaking   │
                        └───────────────────────────────────────┘
```

---

## Feature Vector (12 dimensions)

Built by `lib/core/utils/landmark_math.dart` → `buildFeatureVector()`. This is the exact shape sent to the TCN API:

| Index | Name | Description |
|-------|------|-------------|
| 0 | `leftElbowAngle` | Left shoulder–elbow–wrist joint angle (degrees, [0,180]) |
| 1 | `rightElbowAngle` | Right shoulder–elbow–wrist joint angle (degrees, [0,180]) |
| 2 | `spineVerticality` | Hip-midpoint → shoulder-midpoint lean from vertical (degrees, 0 = upright) |
| 3 | `wristY` | Normalised mid-wrist Y position (0 = top of frame, 1 = bottom) |
| 4 | `wristVelocityY` | Δ wristY per frame (per-frame units — NOT per-second) |
| 5 | `wristAccelerationY` | Δ velocity per frame |
| 6 | `normalizedDepth` | Wrist Y displacement relative to torso span (shoulder → hip) |
| 7 | `shoulderWidth` | Normalised biacromial width (used for depth calibration) |
| 8 | `meanConfidence` | Mean MediaPipe landmark visibility score |
| 9 | `leftElbowVisible` | 0 or 1 (visibility > 0.5) |
| 10 | `rightElbowVisible` | 0 or 1 (visibility > 0.5) |
| 11 | _(reserved)_ | 0.0 padding — matches API input shape |

> **Velocity units**: wristVelocityY is a per-frame delta (Δy only). It must NOT be divided by Δt. The compression counting threshold (0.012) and BPM peak detector in both `InferenceService` and `InferenceServiceWeb` are all calibrated to per-frame units.

---

## Dependency Injection

All services are registered by `configureDependencies()` in `lib/core/di/injection.dart` before `runApp`. GetIt is used as a service locator.

**Platform service matrix:**

| Service | Web | Mobile |
|---------|-----|--------|
| Pose estimation | `PoseServiceWeb` (JS interop) | `PoseServiceMobile` (MLKit) |
| ML inference | `InferenceServiceWeb` (TCN REST API) | `InferenceService` (TFLite INT8) |
| Session storage | `StorageService` (SharedPreferences) | `StorageService` + `SessionLogger` (SQLite) |
| Research logging | `ResearchLoggerWeb` (SharedPreferences + CSV download) | `ResearchLogger` (SQLite) |
| TTS | `TtsService` (Web Speech API / Umuganda HTTP) | `TtsService` (flutter_tts offline) |
| Feedback | `FeedbackEngine` (same Dart — no platform split) | same |
| Telemetry | `TelemetryService` (Supabase REST) | same |
| Participants | `ParticipantService` (Supabase REST) | same |

`ResearchLoggerAdapter` provides a platform-transparent facade over `ResearchLoggerWeb` / `ResearchLogger` so all research screens (`ConsentScreen`, `SurveyScreen`, `ResearcherDashboard`) are free of `kIsWeb` checks.

---

## Session State Machine

`LiveSessionNotifier` (Riverpod `StateNotifier`) manages the in-progress session:

```
[idle]
  │  startSession(participantId)
  │    clears all history lists, resets feedback engine
  │    speaks "start" TTS prompt
  │    starts 1 Hz elapsed-time ticker
  ▼
[active]  ◄── onFrame(LandmarkFrame) called ~25 fps
  │              runs inference (web: InferenceServiceWeb, mobile: InferenceService)
  │              accumulates bpm/depth/rate/depth/recoil histories
  │              counts compressions (wristVelocityY direction reversal)
  │              updates LiveSessionState for TrainingScreen UI
  │              fires TTS if FeedbackEngine.shouldSpeak()
  │
  │  stopSession()
  ▼
[saving]
  │  builds SessionModel with all accumulated metrics
  │  StorageService.saveSession() — awaited (blocks navigation)
  │  TelemetryService.uploadSession() — unawaited (fire-and-forget)
  ▼
[idle]  →  navigate to /results/:sessionId
```

---

## Compression Counting

Compressions are counted via wrist Y velocity direction reversal in `LiveSessionNotifier._updateCompressionCount()`:

- A compression cycle = wristVelocityY transitions from **descending** (`v > +0.012`) to **ascending** (`v < −0.012`)
- Minimum 300 ms between counted compressions (hard cap at ~200 bpm physical ceiling)
- Threshold 0.012 is above MediaPipe landmark jitter noise floor (~0.002–0.005) and below real compression velocity (~0.03–0.08 at 25 fps for a 5–6 cm press)

---

## Depth Estimation

Depth is estimated from wrist Y motion range (not absolute position):

```
normDisp = (wristMidY − shoulderMidY) / (hipMidY − shoulderMidY)
torsoHeightCm = (meanShoulderWidthNorm × normToPhysicalCmScale)
                / shoulderWidthToTorsoRatio
depthCm = normDisp × torsoHeightCm          [clamped 0–10 cm]
```

Current calibration constants (`app_constants.dart`):

| Constant | Value | Rationale |
|----------|-------|-----------|
| `normToPhysicalCmScale` | 20.0 | Calibrated for ~1 m webcam-to-rescuer distance |
| `shoulderWidthToTorsoRatio` | 1.0 | Direct 1:1 mapping of motion range |
| `fallbackTorsoHeightCm` | 8.0 | Used for first ~1.2 s before 30 calibration frames accumulate |

> **TODO**: Replace with a delta-depth estimator once pilot-study frame data is labelled and retraining runs. The current proxy over-estimates because `normDisp` reflects absolute wrist position relative to the torso span, not the compression delta.

---

## MediaPipe Pose Bridge Readiness Guard

A MediaPipe WASM crash (`roi->width > 0 && roi->height > 0`) occurs when the pose model processes a frame before the `<video>` element has non-zero dimensions. The fix uses two layers:

**Layer 1 — `TrainingScreen._waitForPoseBridgeReady()`**:
- Polls `window._novicePoseReady` every 100 ms after camera initializes.
- `_novicePoseReady` is set to `true` by `flutter_pose_bridge.js` inside its first successful `onResults` callback (i.e. after the WASM has confirmed a valid frame).
- The 25 fps pose loop only starts once this flag is `true`, or after a 4 s safety timeout.

**Layer 2 — `PoseServiceWeb.processFrame()`**:
- Secondary guard: checks `window._novicePoseVideoReady` before accessing landmark data.
- `_novicePoseVideoReady` is set to `true` by the JS bridge once `video.videoWidth > 0`.
- Returns `null` (frame skipped) if not yet ready.

---

## InferenceServiceWeb — API Throttling & Cache

Calling the TCN API every frame (25 fps) would generate 25 overlapping HTTP POST requests per second and ignore responses. The service throttles and caches:

```
_apiCallInterval = 600 ms   (≈ 1 API call per 15 frames at 25 fps)
_apiResultMaxAge = 1500 ms  (cached result is used for up to 37 frames)

isFreshPrediction = true    set only when a new API response is stored
isFreshPrediction = false   set on all cache-replay frames via copyWith()
```

`LiveSessionNotifier.onFrame()` only accumulates into `_rateAccuracies`, `_depthAccuracies`, `_recoilAccuracies` when `inference.isFreshPrediction == true`. This prevents the 14–36 cache-replay frames between real API calls from inflating accuracy metrics with a stale label paired with live-but-drifted bpm/depth values.

---

## Quality Score Formula

Computed in `LiveSessionNotifier._computeQualityScore()`:

```dart
// TCN AUC-ROC weights (Stage 9 evaluate(), CPR_Coach_Training.ipynb)
const rateWeight   = 0.983;
const depthWeight  = 0.993;
const recoilWeight = 0.959;

// TCN F1_w test-set baselines (sliding-window retrain)
const rateF1Baseline   = 91.7;
const depthF1Baseline  = 98.3;
const recoilF1Baseline = 88.5;

rateScore   = clamp(rateAcc   × 100 / rateF1Baseline,   0, 2) × 100
depthScore  = clamp(depthAcc  × 100 / depthF1Baseline,  0, 2) × 100
recoilScore = clamp(recoilAcc × 100 / recoilF1Baseline, 0, 2) × 100

weightedScore = (rateScore×rateWeight + depthScore×depthWeight + recoilScore×recoilWeight)
                / (rateWeight + depthWeight + recoilWeight)

if cprFraction < 0.6: weightedScore -= 10
if meanConfidence ≥ 0.8: weightedScore += 5

qualityScore = clamp(weightedScore, 0, 100).round()
```

---

## Credential Injection — Why `--dart-define` Isn't Used

In Flutter 3.29.3, `--dart-define=KEY=VALUE` values are silently dropped by dart2js during `flutter build web --release`. The values are embedded in the compiled JavaScript as string constants, but the minifier drops them when it cannot prove they are reachable.

The workaround (`scripts/vercel_build.sh`):
1. Build with `flutter build web --release --no-tree-shake-icons` (no `--dart-define` for secrets).
2. After the build, use Python regex to inject `window.__NOVICE_CONFIG__ = {...}` directly into `build/web/index.html`.
3. `lib/core/constants/env.dart` reads this global via `dart:js_interop` external declarations (resolved at compile time — not subject to tree-shaking).

---

## Design Token Parity (Flutter ↔ HTML)

`AppTheme` constants map 1:1 to CSS variables in the landing page:

| Flutter constant | CSS variable | Hex value |
|------------------|-------------|-----------|
| `AppTheme.bg` | `--bg` | `#0A0D0F` |
| `AppTheme.surface` | `--surface` | `#111518` |
| `AppTheme.card` | `--card` | `#161C20` |
| `AppTheme.accent` | `--mint` | `#00E5A0` |
| `AppTheme.accentWarn` | `--coral` | `#FF4D6D` |
| `AppTheme.accentAmber` | `--amber` | `#FFC947` |
| `AppTheme.cprRed` | `--red` | `#C84B25` |
| `AppTheme.chokingAmber` | `--amberM` | `#A8660E` |
| `AppTheme.strokePurple` | `--purple` | `#4840A8` |
| `AppTheme.recoveryTeal` | `--teal` | `#0F9070` |
| `AppTheme.aedBlue` | `--blue` | `#2B7FD4` |

---

## Key Third-Party Dependencies

| Package | Version | Role |
|---------|---------|------|
| `flutter_riverpod` | 2.4.9 | State management (LiveSessionNotifier) |
| `get_it` | 9.2.1 | Service locator (DI) |
| `go_router` | 17.0.0 | Declarative routing with path URL strategy |
| `freezed` / `freezed_annotation` | 2.5.7 / 2.4.1 | Immutable data models with `copyWith` |
| `camera` | 0.11.2+1 | Camera access (web + mobile) |
| `flutter_tts` | 4.2.5 | TTS (Web Speech API on web, offline on mobile) |
| `shared_preferences` | 2.2.3 | Web session + research data storage |
| `sqflite` | 2.3.2 | Mobile SQLite session + research storage |
| `http` | 1.2.1 | TCN API, Supabase REST, Umuganda TTS |
| `logger` | 2.0.2+1 | Structured logging throughout services |
| `google_mlkit_pose_detection` | 0.14.0 | Mobile pose estimation (conditionally imported) |
| `tflite_flutter` | 0.12.1 | Mobile TFLite INT8 inference (conditionally imported) |

---

*GNU GPL v3 · ALU Capstone 2024–2025 · Jean Robert Gatwaza*