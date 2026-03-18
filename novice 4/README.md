# Novice — CPR-AI Coach
### *Empowering Every Bystander in Sub-Saharan Africa*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-INT8-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![TensorFlow.js](https://img.shields.io/badge/TF.js-Web-FF6F00?logo=tensorflow)](https://www.tensorflow.org/js)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)](https://python.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey)](https://flutter.dev/multi-platform)
[![Phase](https://img.shields.io/badge/Phase-1%20Demo-00E5A0)](SETUP.md)

---

## Overview

**Novice** (formerly CPR-AI Coach) is a cross-platform real-time CPR coaching application that uses on-device pose estimation and a BiLSTM machine learning classifier to guide untrained bystanders through cardiopulmonary resuscitation — with **no internet connection required on mobile**.

Developed as the capstone project for **The African Leadership University, Rwanda**.

- **41%** of deaths in Sub-Saharan Africa are addressable by emergency interventions
- Bystander CPR can **triple** survival chances; each minute without CPR cuts survival by ~10%
- Smartphone penetration has grown from 32% (2012) to ~50% (2022) across SSA

---

## What's New in Phase 1

| Change | Detail |
|---|---|
| App renamed | **Novice** (was CPR-AI Coach) |
| Clean project structure | Removed ghost brace folders, root-level duplicates — see `scripts/clean_repo.sh` |
| Phase 1 web demo | `web/` — fully functional browser demo, no install required |
| Full Flutter app | All screens, services, providers wired — runs in rule-based demo mode until ML model is trained |
| ML pipeline | Complete Python pipeline: extract → train → evaluate → export (TFLite + TFJS) |
| Reproducible setup | Pinned deps for macOS M1 Max + Metal GPU |
| Google Drive dataset | `Sample_Dataset` on Google Drive wired into `ml_pipeline/` — see [Setup](#getting-started) |
| GNU GPL v3 | All files carry license header |

---

## Phase 1 Demo

Open `web/index.html` in Chrome — no server needed for the demo build.

For the full wired web app:
```bash
cd web && npm install && npm run dev
# → http://localhost:3000
```

---

## Key Features

| Feature | Status | Notes |
|---|---|---|
| Real-time pose estimation | ✓ | MediaPipe BlazePose, 25–30 FPS |
| BiLSTM error classification | ⏳ | Runs in rule-based mode until `novice_cpr_classifier.tflite` is trained |
| Voice coaching EN + RW | ✓ | flutter_tts (EN offline), Umuganda TTS HTTP (RW) |
| BPM detection (rule-based) | ✓ | Peak detection on wrist Y velocity |
| Depth estimation | ✓ | Normalised wrist displacement proxy |
| Session logging (SQLite) | ✓ | Offline, exportable JSON for pilot study |
| Web app (TF.js) | ✓ | Same model, same prompts, browser-native |
| Demo animation | ✓ | Flutter CustomPainter stick figure; Rive slot ready |
| Kinyarwanda voice | ⏳ | Placeholder — needs Umuganda TTS endpoint or native speaker recording |

---

## Platform Architecture

```
┌──────────────────────────────────────────────────────┐
│              Shared business logic                    │
│  CPR thresholds · Prompts · Session schema · Tests   │
└──────────────────────┬───────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌─────────────────────┐   ┌────────────────────────────┐
│   iOS / Android      │   │   Web (Browser)             │
│   Flutter + Dart     │   │   Vanilla JS + HTML5        │
│                      │   │                             │
│  Pose: google_mlkit  │   │  Pose: @mediapipe/pose WASM │
│  Infer: tflite_flutter│   │  Infer: TensorFlow.js       │
│  TTS: flutter_tts    │   │  TTS: Web Speech API        │
│  Storage: sqflite    │   │  Storage: IndexedDB         │
└─────────────────────┘   └────────────────────────────┘
```

---

## Project Structure

```
novice/                                ← repo root (clean — no root-level pubspec)
│
├── README.md
├── SETUP.md                           ← step-by-step M1 Max + iPhone 15 Pro guide
├── pubspec.yaml                       ← Flutter dependencies
├── analysis_options.yaml
├── .gitignore                         ← covers .DS_Store, .env, *.tflite (Git LFS)
├── .env.example
├── LICENSE                            ← GNU GPL v3
│
├── lib/                               ← Flutter app
│   ├── main.dart
│   ├── core/
│   │   ├── constants/app_constants.dart    ← CPR thresholds, prompts, error classes
│   │   ├── theme/app_theme.dart
│   │   ├── di/injection.dart               ← GetIt DI bootstrap
│   │   ├── router/app_router.dart          ← GoRouter
│   │   └── utils/landmark_math.dart        ← vectorized geometry (pure Dart)
│   ├── models/
│   │   ├── session_model.dart              ← Freezed + SQLite schema
│   │   └── landmark_frame.dart
│   ├── services/
│   │   ├── pose_service.dart               ← MediaPipe BlazePose (mobile only)
│   │   ├── inference_service.dart          ← TFLite BiLSTM + rule-based fallback
│   │   ├── feedback_engine.dart            ← priority queue, cooldown gating
│   │   ├── tts_service.dart                ← EN offline + Umuganda RW HTTP
│   │   └── session_logger.dart             ← SQLite + JSON export
│   ├── providers/session_provider.dart     ← Riverpod live session state
│   ├── features/
│   │   ├── splash/                         ← animated entry
│   │   ├── home/                           ← landing + navigation
│   │   ├── training/                       ← camera + pose + inference screen
│   │   ├── results/                        ← post-session metrics
│   │   ├── history/                        ← past sessions list
│   │   ├── demo/                           ← animated CPR technique guide
│   │   └── settings/                       ← language, data export, about
│   └── widgets/
│       ├── bpm_indicator.dart              ← animated arc ring
│       ├── compression_gauge.dart          ← vertical bar with target markers
│       ├── feedback_banner.dart
│       └── pose_overlay.dart               ← CustomPainter skeleton
│
├── web/                               ← Web app (standalone JS)
│   ├── index.html                          ← Phase 1 demo (self-contained)
│   ├── package.json
│   └── src/
│       ├── services/
│       │   ├── poseService.js              ← @mediapipe/pose WASM
│       │   ├── inferenceService.js         ← TensorFlow.js BiLSTM
│       │   ├── feedbackEngine.js           ← port of Dart FeedbackEngine
│       │   ├── ttsService.js               ← Web Speech API + Umuganda HTTP
│       │   └── sessionLogger.js            ← IndexedDB persistence
│       └── utils/
│           ├── constants.js                ← mirror of app_constants.dart
│           └── landmarkMath.js             ← port of landmark_math.dart
│
├── assets/                            ← Flutter asset bundle
│   ├── models/                             ← novice_cpr_classifier.tflite (Git LFS)
│   ├── animations/                         ← cpr_instructor.riv (Rive, Phase 2)
│   ├── audio/en/                           ← pre-recorded EN prompts (optional)
│   └── audio/rw/                           ← pre-recorded RW prompts (TODO)
│
├── ml_pipeline/                       ← Python training pipeline
│   ├── requirements.txt                    ← pinned, M1 Max + Metal GPU
│   ├── config.yaml                         ← single source of truth for hyperparams
│   ├── notebooks/
│   │   └── 01_dataset_exploration.ipynb   ← Sample_Dataset analysis
│   └── src/
│       ├── data/
│       │   ├── extract_landmarks.py        ← MediaPipe → .npy feature files
│       │   └── dataset_loader.py           ← tf.data pipeline + augmentation
│       ├── models/bilstm_model.py          ← BiLSTM architecture
│       ├── training/
│       │   ├── train.py                    ← full training loop + callbacks
│       │   └── evaluate.py                 ← F1, confusion matrix, TFLite latency
│       └── export/
│           ├── convert_to_tflite.py        ← INT8 quantised .tflite
│           └── convert_to_tfjs.py          ← TFJS graph model for web
│
├── scripts/
│   └── clean_repo.sh                  ← removes ghost folders + root duplicates
│
├── test/
│   ├── unit/
│   │   ├── landmark_math_test.dart
│   │   └── feedback_engine_test.dart
│   └── widget/                        ← widget tests (Phase 2)
│
└── android/ ios/                      ← platform configs
```

---

## Getting Started

See **[SETUP.md](SETUP.md)** for the complete step-by-step guide for macOS M1 Max + iPhone 15 Pro.

Quick start:
```bash
git clone git@github.com:Gatwaza/Capstone-Project.git
cd Capstone-Project
./scripts/clean_repo.sh          # one-time repo cleanup
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Loading the Sample_Dataset

Your `Sample_Dataset` is on Google Drive. Two options:

**Option A — Google Drive connector (recommended):**
Connect the Google Drive MCP connector in Claude, then ask Claude to access `Sample_Dataset` directly for pipeline runs.

**Option B — Manual:**
```bash
# Download Sample_Dataset from Google Drive → unzip
cp -r ~/Downloads/Sample_Dataset ml_pipeline/data/raw/
python ml_pipeline/src/data/extract_landmarks.py --config ml_pipeline/config.yaml
python ml_pipeline/src/training/train.py --config ml_pipeline/config.yaml
```

---

## ML Pipeline

### Architecture
```
Input: (batch, 30 frames, 12 features)
  → BatchNorm
  → Bidirectional LSTM(64)    ← captures downstroke + upstroke
  → LSTM(32)
  → Dense(32) + ReLU + Dropout(0.3)
  → Dense(8, softmax)         ← 8 error classes
```

### Error classes (BiLSTM)
| Index | Key | ERC Code |
|---|---|---|
| 0 | correct_compression | — |
| 1 | hand_too_high | E01 |
| 2 | hand_too_low | E02 |
| 3 | bent_elbows | E05 |
| 4 | body_lean | E06 |
| 5 | too_shallow | E07 |
| 6 | too_deep | E08 |
| 7 | incomplete_decomp | E09 |

Rate errors (E10/E11) are detected via rule-based peak detection on wrist Y velocity.

### Evaluation targets
| Metric | Target |
|---|---|
| F1-score per class | ≥ 0.85 |
| TFLite inference latency | < 100ms / frame |
| BPM accuracy | ±5 bpm of true rate |
| Model size | < 5 MB |

---

## Research Context

ALU Capstone Project — Rwanda.

Key references:
- Perkins et al. (2021) — ERC Guidelines 2021 (100–120 bpm, 5–6 cm depth)
- Wang et al. (2023) — CPR-Coach dataset; ICCV 2023 Demo
- Ecker et al. (2024) — Computer vision CPR feedback doubled correct depth proportions
- GSMA Intelligence (2023) — Mobile Economy Sub-Saharan Africa

**To request the full CPR-Coach dataset:**
```
Email: slwang19@fudan.edu.cn
Subject: CPR-Coach Dataset Request — African Leadership University Capstone
```

---

## Contributing

```bash
# Branch naming
feature/pose-pipeline
feature/tfjs-inference
fix/tts-kinyarwanda
chore/update-deps

# Commit style (Conventional Commits)
feat: add compression rate peak detection
feat(web): wire TensorFlow.js inference service
fix: resolve MediaPipe landmark confidence threshold
docs: update dataset instructions
```

---

## License

**GNU General Public License v3.0** — see [LICENSE](LICENSE).

> **Medical Disclaimer:** Novice is a training and simulation aid only.
> It does not replace formal CPR certification or professional medical advice.
> Always call emergency services first.

---

*"Buri mugenzi yagutabara" — Anyone can help*

*Built for Rwanda and Sub-Saharan Africa · ALU Capstone 2024 · Jean Robert Gatwaza*
