# Novice — First Aid Assessment
### *Real-time web-based first aid technique evaluation*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow.js](https://img.shields.io/badge/TF.js-Web-FF6F00?logo=tensorflow)](https://www.tensorflow.org/js)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)](https://python.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Web-blue)](https://flutter.dev/web)
[![Phase](https://img.shields.io/badge/Phase-Web%20Deployment-00E5A0)](SETUP.md)

---

## Overview

**Novice** is a web-first first aid assessment application that runs real-time pose estimation and model inference to evaluate technique and deliver corrective feedback in the browser.

The active assessment model is a **CNN-BiLSTM** classifier that outperformed other sequence architectures in validation and drives the connected web inference flow.

- Focused on **real-time web deployment**, not standalone demo mode
- Uses pose landmarks + TF.js to run connected model assessment in-browser
- Built for easy access in low-bandwidth settings and research-aware deployment

---

## Current Status
 
| Change | Detail |
|---|---|
| Web-only deployment | No native iOS/Android folders; Flutter compiles to `build/web` |
| CNN-BiLSTM inference | `InferenceServiceWeb` → Hugging Face Spaces API; falls back to rule-based thresholds |
| No `--web-renderer html` flag | Removed — the flag was dropped in Flutter 3.22 and caused Vercel build exit 64 |
| MediaPipe pose bridge | JS bridge (`flutter_pose_bridge.js`) with `_novicePoseReady` guard to prevent zero-dimension frame crash |
| Depth calibration | `normToPhysicalCmScale=20`, `fallbackTorsoHeightCm=8` — calibrated for ~1 m webcam distance |
| AI MODEL tile | Shows `CNN-BiLSTM` when API reachable, `Rule-based` when not (no longer "Demo mode") |
| Research logging | Frame NDJSON export + researcher review panel in results screen |
| Multilingual TTS | EN via Web Speech API · RW via Umuganda HTTP endpoint |
| ML pipeline preserved | Python `ml_pipeline/` for training new model versions and TFJS/TFLite export |
 
---

## Running locally
 
```bash
git clone git@github.com:Gatwaza/Capstone-Project.git
cd "Capstone Project/novice 4"
 
# Install Flutter deps
flutter pub get
dart run build_runner build --delete-conflicting-outputs
 
# Run on web (Chrome recommended for WebGL + WASM)
flutter run -d chrome
 
# Or build and serve statically
flutter build web --release --dart-define=RESEARCHER_PIN=2026
cd build/web && python3 -m http.server 8080
```
 
---

## Key Features
 
| Feature | Status | Notes |
|---|---|---|
| Real-time pose estimation | ✓ | `@mediapipe/pose` WASM via `flutter_pose_bridge.js` |
| CNN-BiLSTM inference | ✓ | Hosted on Hugging Face Spaces; `(60 × 12)` input shape |
| Rule-based fallback | ✓ | Activates automatically when API unreachable |
| Live audio coaching | ✓ | 13 TTS prompts in EN + RW; 4 s cooldown per prompt |
| Compression metrics | ✓ | Rate (bpm), depth (cm), CPR fraction, quality score |
| Session persistence | ✓ | IndexedDB via `StorageService`; NDJSON frame export |
| Researcher review panel | ✓ | Label sessions correct/partial/incorrect; export raw frames |
| Multilingual UI | ✓ | English + Kinyarwanda (Kinyarwanda TTS prompts pending native speaker validation) |
| ML training pipeline | ✓ | Python `ml_pipeline/` → TFJS + TFLite export |
 
---


## Architecture at a glance
 
```
Browser (Flutter Web)
│
├─ MediaPipe Pose WASM  →  33 landmarks @ 25 fps
│      (flutter_pose_bridge.js)
│
├─ LandmarkMath (Dart)  →  12-dim feature vector per frame
│      elbow angles · spine lean · wrist Y & velocity · shoulder width
│
├─ InferenceServiceWeb  →  60-frame window → CNN-BiLSTM
│      (flutter_inference_bridge.js)       API: jeanrobert-novice.hf.space
│      ↳ falls back to rule-based thresholds when API unreachable
│
├─ FeedbackEngine       →  priority queue · 4 s cooldown gating
│
├─ TtsService           →  Web Speech API (EN) · Umuganda HTTP (RW)
│
└─ StorageService       →  IndexedDB session log · NDJSON frame export
```
 
**Hosted inference API:** `https://jeanrobert-novice.hf.space`
The API runs the CNN-BiLSTM model server-side. `InferenceServiceWeb` polls `/health` at startup and streams `(60 × 12)` sequences to `/predict`.
 
---
## Project Structure
 
```
novice/                                ← repo root
│
├── README.md                          ← this file
├── SETUP.md                           ← complete local + Vercel setup guide
├── pubspec.yaml                       ← Flutter 3.29.3, Dart ≥3.0.0
├── pubspec.lock
├── analysis_options.yaml
├── vercel.json                        ← Vercel build + CORS/cache headers
├── LICENSE                            ← GNU GPL v3
│
├── lib/                               ← Flutter app source
│   ├── main.dart                      ← app entry point; calls setupDI()
│   ├── core/
│   │   ├── constants/app_constants.dart   ← CPR thresholds (ERC 2021), TTS prompts, model paths
│   │   ├── theme/app_theme.dart           ← dark palette; accent green #00E5A0
│   │   ├── di/injection.dart              ← GetIt DI bootstrap; loads model, registers services
│   │   ├── router/app_router.dart         ← GoRouter: /, /training, /results/:id, /history, /demo, /settings
│   │   └── utils/landmark_math.dart       ← 12-dim feature vector builder (pure Dart)
│   ├── models/
│   │   ├── session_model.dart             ← Freezed SessionModel (stored in IndexedDB)
│   │   ├── landmark_frame.dart            ← Freezed per-frame pose snapshot
│   │   └── research_models.dart           ← Freezed consent + survey models
│   ├── services/
│   │   ├── inference_service.dart         ← Mobile TFLite BiLSTM (stub on web)
│   │   ├── feedback_engine.dart           ← Priority queue; 4 s TTS cooldown
│   │   ├── tts_service.dart               ← Web Speech API (EN) + Umuganda HTTP (RW)
│   │   ├── session_logger.dart            ← SQLite on mobile; IndexedDB on web
│   │   ├── research_logger.dart           ← Research consent + survey logging
│   │   └── platform/
│   │       ├── pose_service_interface.dart    ← abstract PoseServiceInterface
│   │       ├── pose_service_web.dart          ← calls flutter_pose_bridge.js JS interop
│   │       ├── pose_service_mobile.dart       ← google_mlkit_pose_detection
│   │       ├── inference_service_web.dart     ← CNN-BiLSTM API client (60×12 sequences)
│   │       ├── cpr_api_service.dart           ← HTTP client → jeanrobert-novice.hf.space
│   │       └── storage_service.dart           ← IndexedDB session CRUD + NDJSON export
│   ├── providers/
│   │   └── session_provider.dart          ← Riverpod LiveSessionNotifier; bpm/depth/compression state
│   ├── features/
│   │   ├── splash/                        ← animated entry with model preload
│   │   ├── home/                          ← landing; Start Training · Demo · History
│   │   ├── training/                      ← camera + MediaPipe + inference + feedback
│   │   ├── results/                       ← post-session metrics (CNN-BiLSTM / Rule-based tile)
│   │   ├── history/                       ← past sessions list
│   │   ├── demo/                          ← animated CPR technique guide (Flutter CustomPainter)
│   │   ├── settings/                      ← language toggle, data export, about
│   │   └── research/                      ← consent + survey + researcher dashboard
│   └── widgets/
│       ├── bpm_indicator.dart             ← animated arc ring
│       ├── compression_gauge.dart         ← vertical depth bar with target markers
│       ├── feedback_banner.dart           ← slide-in corrective prompt banner
│       └── pose_overlay.dart             ← CustomPainter skeleton overlay
│
├── web/                               ← Compiled Flutter web output root
│   ├── index.html                     ← Flutter bootstrap (loads flutter_service_worker.js)
│   ├── manifest.json                  ← PWA manifest
│   ├── flutter_pose_bridge.js         ← MediaPipe Pose WASM → Dart JS interop
│   ├── flutter_inference_bridge.js    ← TF.js in-browser bridge (supplementary)
│   ├── demo_standalone_reference.html ← standalone HTML reference demo (not deployed)
│   └── assets/
│       └── models/                    ← TFJS model shards (model.json + *.bin via Git LFS)
│
├── assets/                            ← Flutter asset bundle
│   ├── models/                        ← novice_cpr_classifier.tflite (Git LFS)
│   ├── animations/                    ← cpr_instructor.riv (Phase 2 placeholder)
│   ├── audio/en/                      ← pre-recorded EN prompts (optional TTS override)
│   └── audio/rw/                      ← pre-recorded RW prompts (TODO)
│
├── ml_pipeline/                       ← Python training pipeline
│   ├── requirements.txt               ← pinned for M1 Max + Metal GPU
│   ├── CPR_Coach_Training.ipynb       ← full training notebook (Colab-ready)
│   └── src/ (see docs/ML_PIPELINE.md for full structure)
│
├── docs/                              ← Technical documentation
│   ├── ARCHITECTURE.md                ← system design, data flow, inference pipeline
│   ├── ML_PIPELINE.md                 ← training, evaluation, export guide
│   ├── DEPLOYMENT.md                  ← Vercel config, env vars, known issues
│   └── API.md                         ← CNN-BiLSTM Hugging Face API reference
│
├── test/
│   ├── unit/landmark_math_test.dart
│   ├── unit/feedback_engine_test.dart
│   └── widget_test.dart
│
└── scripts/
    └── clean_repo.sh                  ← removes ghost folders + root duplicates
```
 
---

## Getting Started

See **[SETUP.md](SETUP.md)** for the complete web deployment and training guide.

Quick start:
```bash
git clone git@github.com:Gatwaza/Capstone-Project.git
cd "Capstone Project/novice 4"
./scripts/clean_repo.sh
flutter pub get
cd web
npm install
npm run dev
```

---

### Dataset
- `train_keypoints.pkl`: 1,344 entries
- `test_keypoints.pkl`: 1,008 entries
- Total unique physical videos: 2,352
- Public dataset: [Google Drive](https://drive.google.com/drive/folders/1zJoJYrmvIv9TgNd5ZmVYVq7odkB5wI5e?usp=drive_link)


## ML Pipeline
 
### Model architecture
```
Input: (batch, 60, 12)   ← 60-frame window × 12 landmark features
  → Conv1D encoder        ← local temporal pattern extraction
  → Bidirectional LSTM    ← long-range sequence context
  → Dense + Dropout
  → Softmax (8 classes)
```
 
### Error classes (Wang et al., 2023)
| Index | Label |
|---|---|
| 0 | `correct_compression` |
| 1 | `hand_too_high` |
| 2 | `hand_too_low` |
| 3 | `bent_elbows` |
| 4 | `body_lean` |
| 5 | `too_shallow` |
| 6 | `too_deep` |
| 7 | `incomplete_decomp` |

### Model
Production inference uses the **CNN-BiLSTM** model, which outperformed alternate architectures in sequence validation.

### Evaluation targets
| Metric | Target |
|---|---|
| F1-weighted | ≥ 0.80 |
| TFJS inference latency | < 100 ms per frame |
| Model size | < 10 MB |

---
## CPR Clinical Thresholds
 
All thresholds sourced from **Perkins et al. (2021) — ERC Guidelines 2021** (DOI: 10.1016/j.resuscitation.2021.02.009).
 
| Parameter | Target |
|---|---|
| Compression rate | 100–120 bpm |
| Compression depth | 5.0–6.0 cm |
| Elbow lock angle | ≥ 160° |
| Max spine lean | ≤ 15° from vertical |
 
---

## License

**GNU General Public License v3.0** — see [LICENSE](LICENSE).

---