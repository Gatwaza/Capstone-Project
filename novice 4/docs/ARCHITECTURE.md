# Novice — System Architecture

**GNU GPL v3 · Jean Robert Gatwaza / African Leadership University**

---

## Overview

Novice is a Flutter Web application. All ML inference runs via a hosted REST API backed by the TCN model. There is no native mobile build in the current deployment; the Flutter mobile code (`pose_service_mobile.dart`, `inference_service.dart`) is preserved for future native builds.

---

## Runtime Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Browser Tab                                  │
│                                                                      │
│  ┌─────────────┐    JS interop     ┌──────────────────────────────┐ │
│  │  Flutter    │◄─────────────────►│  flutter_pose_bridge.js      │ │
│  │  (Dart/WASM)│                   │  @mediapipe/pose WASM        │ │
│  └──────┬──────┘                   └──────────────────────────────┘ │
│         │                                                            │
│         │  LandmarkFrame (33 pts → 12 features @ 25 fps)            │
│         ▼                                                            │
│  ┌──────────────────┐   HTTP POST    ┌───────────────────────────┐  │
│  │ InferenceService │───────────────►│ jeanrobert-novice.hf.space│  │
│  │ Web              │   /predict     │ TCN (Python/FastAPI)      │  │
│  │ (60×12 buffer)   │◄───────────────│ rate · depth · recoil     │  │
│  └──────┬───────────┘                └───────────────────────────┘  │
│         │  InferenceResult                                           │
│         ▼                                                            │
│  ┌──────────────────┐                                               │
│  │  FeedbackEngine  │  priority queue · 4 s TTS cooldown            │
│  └──────┬───────────┘                                               │
│         │                                                            │
│  ┌──────┴───────────┐   ┌────────────────────────────────────────┐  │
│  │  TtsService      │   │  StorageService (IndexedDB)            │  │
│  │  EN: Web Speech  │   │  - saveSession()                       │  │
│  │  RW: Umuganda    │   │  - exportFramesNdjson()                │  │
│  └──────────────────┘   └────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Key Files

| File | Role |
|---|---|
| `lib/main.dart` | App entry; calls `setupDI()` then `runApp()` |
| `lib/core/di/injection.dart` | GetIt DI: registers pose, inference, feedback, storage, TTS, research services |
| `lib/core/router/app_router.dart` | GoRouter routes: `/`, `/training`, `/results/:id`, `/history`, `/demo`, `/settings`, `/research/*` |
| `lib/providers/session_provider.dart` | Riverpod `LiveSessionNotifier`; holds bpm/depth/compressions state during active session |
| `lib/services/platform/inference_service_web.dart` | Buffers 60 frames, calls `CprApiService.predict()`, falls back to rule-based |
| `lib/services/platform/cpr_api_service.dart` | HTTP client to `jeanrobert-novice.hf.space`; `/health` + `/predict` |
| `lib/services/platform/pose_service_web.dart` | JS interop with `flutter_pose_bridge.js`; reads `window._novicePoseLandmarks` |
| `lib/services/feedback_engine.dart` | Priority queue; emits at most one TTS prompt per 4 s cooldown window |
| `lib/core/utils/landmark_math.dart` | Builds 12-dim feature vector from raw MediaPipe landmarks |
| `web/flutter_pose_bridge.js` | Initialises `@mediapipe/pose` WASM; writes landmarks to `window._novicePoseLandmarks`; sets `window._novicePoseReady` after first valid frame |

---

## Feature Vector (12 dimensions)

Built by `LandmarkMath.buildFeatureVector()`:

| Index | Feature | Description |
|---|---|---|
| 0 | `leftElbowAngle` | Shoulder–Elbow–Wrist angle, left arm (degrees) |
| 1 | `rightElbowAngle` | Shoulder–Elbow–Wrist angle, right arm (degrees) |
| 2 | `spineVerticality` | Hip–Shoulder vector angle from vertical (degrees) |
| 3 | `wristY` | Normalised mid-wrist Y (0=top of frame, 1=bottom) |
| 4 | `wristVelocityY` | Δ wristY per second |
| 5 | `wristAccelerationY` | Δ velocity per second |
| 6 | `normalizedDepth` | Wrist displacement relative to torso height |
| 7 | `shoulderWidth` | Normalised biacromial width |
| 8 | `meanConfidence` | Mean MediaPipe landmark confidence |
| 9 | `leftElbowVisible` | 0/1 — left elbow visibility > 0.5 |
| 10 | `rightElbowVisible` | 0/1 — right elbow visibility > 0.5 |
| 11 | _(reserved)_ | Padding to 12 dims (matches API shape) |

---

## Session State Machine

```
[idle]
  │  startSession()
  ▼
[active]  ─── onFrame(LandmarkFrame) ──►  update bpm/depth/compressions
  │  stopSession()
  ▼
[saving]  ─── StorageService.saveSession() ──►  IndexedDB
  │
  ▼
/results/:id
```

---

## Depth Calibration

Depth estimation uses the wrist Y motion range, not absolute position:

```
torsoHeightCm = (normShoulderWidth × normToPhysicalCmScale) / shoulderWidthToTorsoRatio
depthCm       = normalizedDepth × torsoHeightCm
```

Current constants (calibrated for ~1 m webcam distance):
- `normToPhysicalCmScale = 20.0`
- `shoulderWidthToTorsoRatio = 1.0`
- `fallbackTorsoHeightCm = 8.0` (used for first ~1.2 s before calibration)

**TODO:** Replace with a delta-depth estimator once pilot-study frame data is labelled.

---

## Pose Bridge Readiness Guard

The MediaPipe WASM bridge can receive frames before the `<video>` element has non-zero dimensions, causing a fatal `roi->width > 0` assertion. The fix:

1. `flutter_pose_bridge.js` sets `window._novicePoseReady = true` inside its first successful `onResults` callback.
2. `TrainingScreen._waitForPoseBridgeReady()` polls `window._novicePoseReady` every 100 ms.
3. The 200 ms pose loop starts only after the flag is true, or after a 4 s timeout.

---

*GNU GPL v3 · ALU Capstone 2024 · Jean Robert Gatwaza*