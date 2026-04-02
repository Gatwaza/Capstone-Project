# Novice V1
### *Empowering Every Bystander in Sub-Saharan Africa*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-2.x-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![TensorFlow.js](https://img.shields.io/badge/TF.js-Web-FF6F00?logo=tensorflow)](https://www.tensorflow.org/js)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python)](https://python.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)](https://flutter.dev/multi-platform)

---

## Table of Contents

- [Project Overview](#project-overview)
- [Problem Statement](#problem-statement)
- [Key Features](#key-features)
- [Platform Architecture](#platform-architecture)
  - [Why Three Separate ML Stacks](#why-three-separate-ml-stacks)
- [System Architecture](#system-architecture)
- [Datasets](#datasets)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Flutter App Setup (Android / iOS)](#flutter-app-setup-android--ios)
  - [Web App Setup](#web-app-setup)
  - [ML Pipeline Setup](#ml-pipeline-setup)
- [Voice Guidance: Two Approaches](#voice-guidance-two-approaches)
- [ML Pipeline](#ml-pipeline)
- [Evaluation & Metrics](#evaluation--metrics)
- [Roadmap](#roadmap)
- [Research Context](#research-context)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview

**CPR-AI Coach** is a cross-platform (Android / iOS / Web) application that uses real-time pose estimation and machine learning to coach completely untrained bystanders through CPR (Cardiopulmonary Resuscitation) in emergency situations — **with no internet connection required on mobile**.

This is the capstone project for **The African Leadership University**, developed in the context of Sub-Saharan Africa where:
- **41%** of all deaths could be addressed by emergency interventions *(Anto-Ocrah et al., 2020)*
- Official EMS response is rare — bystanders are the first and often only responder
- Smartphone ownership has grown from 32% (2012) to ~50% (2022) *(GSMA, 2023)*
- Each minute without CPR cuts survival by **~10%**; immediate bystander CPR can **triple** survival chances

---

## Problem Statement

In Rwanda and across Sub-Saharan Africa, untrained bystanders witnessing cardiac emergencies have no real-time guidance system to follow. Existing first-aid apps deliver static videos or text — they do not observe the user, correct posture errors, or adapt to performance. This tool fills that gap by combining:

- **Camera-based pose estimation** (MediaPipe BlazePose)
- **On-device ML classification** (BiLSTM via TFLite on mobile; TensorFlow.js on web)
- **Adaptive voice coaching** (flutter_tts + Umuganda TTS for Kinyarwanda)
- **100% offline operation on mobile** — no API calls, no internet dependency

---

## Key Features

| Feature | Description |
|---|---|
| Real-time Pose Estimation | MediaPipe BlazePose tracks 33 body landmarks at 25–30 FPS |
| Error Classification | BiLSTM detects: wrong hand placement, bent elbows, shallow depth, wrong rate |
| Voice Coaching | Prioritized prompt queue in English + Kinyarwanda (Umuganda TTS) |
| Live Dashboard | BPM counter, depth indicator, compression fraction display |
| Fully Offline (Mobile) | All inference on-device; TFLite INT8 quantized model (~3–5 MB) |
| Web Access | Browser-based version via TensorFlow.js + MediaPipe JS (no install required) |
| Mid-Range Optimized | Tested on Tecno Spark / Samsung A-series (2GB RAM devices) |
| Session Logging | Local SQLite log of all metrics for post-session review |
| Animated Demo | On-screen animated instructor shows correct technique |

---

## Platform Architecture

### Why Three Separate ML Stacks

Cross-platform does **not** mean one ML codebase for all targets. The mobile libraries (`tflite_flutter`, `google_mlkit_pose_detection`) use native Android/iOS hardware acceleration and have **no web implementation**. The web platform requires a separate inference pipeline using browser-native technologies:

```
┌────────────────────────────────────────────────────────────────┐
│                    Shared across all platforms                  │
│  Business logic · Feedback prompt strings · CPR thresholds     │
│  Session metrics schema · Research evaluation forms            │
└────────────────────────────────────────────────────────────────┘
         │                                        │
         ▼                                        ▼
┌─────────────────────┐               ┌──────────────────────────┐
│  Android / iOS       │               │  Web (Browser)           │
│  Flutter + Dart      │               │  Vanilla JS              │
│                      │               │                          │
│  Pose:               │               │  Pose:                   │
│  google_mlkit_pose   │               │  @mediapipe/pose (WASM)  │
│  (MediaPipe native)  │               │  runs in-browser         │
│                      │               │                          │
│  Inference:          │               │  Inference:              │
│  tflite_flutter      │               │  TensorFlow.js           │
│  (INT8 .tflite)      │               │  (same .h5 converted)    │
│                      │               │                          │
│  TTS:                │               │  TTS:                    │
│  flutter_tts         │               │  Web Speech API          │
│  + Umuganda TTS      │               │  + Umuganda TTS HTTP     │
│                      │               │                          │
│  Storage:            │               │  Storage:                │
│  sqflite (offline)   │               │  IndexedDB               │
└─────────────────────┘               └──────────────────────────┘
```

> **Web limitation:** The web version requires a modern browser with camera access
> (Chrome 90+, Firefox 95+, Safari 15.4+) and an internet connection to load
> TensorFlow.js and MediaPipe WASM bundles on first load. Full offline PWA support
> is a post-capstone goal.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                        │
│                                                                  │
│  ┌──────────┐   ┌──────────────────┐   ┌─────────────────────┐  │
│  │  Camera  │──▶│  PoseService     │──▶│  FeatureExtractor   │  │
│  │  Plugin  │   │  (MediaPipe /    │   │  (joint angles,     │  │
│  └──────────┘   │  google_mlkit)   │   │   wrist velocity,   │  │
│                 └──────────────────┘   │   compression rate) │  │
│                                        └──────────┬──────────┘  │
│                                                   │             │
│                                        ┌──────────▼──────────┐  │
│                                        │   TFLite Inference  │  │
│                                        │   (BiLSTM model     │  │
│                                        │    on-device)       │  │
│                                        └──────────┬──────────┘  │
│                                                   │             │
│  ┌──────────────────┐              ┌──────────────▼──────────┐  │
│  │   TTSService     │◀─────────────│   FeedbackEngine        │  │
│  │ (flutter_tts +   │              │   (priority queue,      │  │
│  │  Umuganda TTS)   │              │    rule-based logic)    │  │
│  └──────────────────┘              └──────────┬──────────────┘  │
│                                               │                 │
│  ┌──────────────────┐              ┌──────────▼──────────────┐  │
│  │  SessionLogger   │◀─────────────│   UI Layer              │  │
│  │  (SQLite/JSON)   │              │   (Training Screen,     │  │
│  └──────────────────┘              │    Results, Demo)       │  │
│                                    └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          Web App                                 │
│                                                                  │
│  Camera API ──▶ MediaPipe Pose (WASM) ──▶ Feature Extraction    │
│                                                 │               │
│                              TensorFlow.js BiLSTM Inference     │
│                                                 │               │
│               Web Speech API ◀────── FeedbackEngine.js          │
│                                                 │               │
│                       UI (HTML5 Canvas overlay + dashboard)     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Datasets

### Primary Dataset — CPR-Coach (Priority for Training & Evaluation)
> **Best fit for this use case**

| Property | Value |
|---|---|
| **Source** | [CPR-Coach GitHub](https://github.com/Shunli-Wang/CPR-Coach) / [Dataset Page](https://shunli-wang.github.io/CPR-Coach/) |
| **Paper** | *"Recognizing Composite Error Actions based on Single-class Training"* — Submitted to Pattern Recognition; Demo at ICCV 2023 |
| **Videos** | 4,544 videos (~4.5K total) |
| **Total Frames** | 2,217,756 RGB frames |
| **Resolution** | 4K (4096×2160) — downsampled for training |
| **FPS** | 25 |
| **Participants** | 12 |
| **Perspectives** | 4 camera angles |
| **Error Classes** | 13 single-error actions + 74 composite error actions |
| **Extras** | Optical flow (TV-L1) + 2D skeletons (AlphaPose) pre-computed |
| **Size** | 449 GB (full); sample available via Google Drive |
| **Access** | Sample: Google Drive link on dataset page. Full dataset: email to request (see below) |

**TO-DO: Request full access:**
```
Email: slwang19@fudan.edu.cn
Subject: CPR-Coach Dataset Request — African Leadership University Capstone Project
Include: Work unit, research purpose, expected usage
```

**CPR-Coach Error Classes (13 single-error types used for training):**
```
E01 – Wrong hand position (too high)
E02 – Wrong hand position (too low)
E03 – One hand only
E04 – Fingers not interlocked
E05 – Bent elbows
E06 – Body leaning (not vertical compression)
E07 – Compression too shallow
E08 – Compression too deep
E09 – Incomplete decompression
E10 – Rate too slow (< 100 bpm)
E11 – Rate too fast (> 120 bpm)
E12 – Wrong rescuer position
E13 – Pausing mid-sequence
```

---

### Secondary Dataset — HMDB-51 (Supplementary Pre-training)
> Used for BiLSTM backbone pre-training on general human motion

| Property | Value |
|---|---|
| **Source** | [HMDB-51](https://serre-lab.clps.brown.edu/resource/hmdb-a-large-human-motion-database/) |
| **Videos** | 6,766 clips across 51 action categories |
| **Usage** | Transfer learning for temporal motion modeling (not CPR-specific) |
| **Access** | Free download from Brown University Serre Lab |

```bash
# Download HMDB-51 (actual archive URLs)
wget -O hmdb51_org.rar \
  "http://serre-lab.clps.brown.edu/wp-content/uploads/2013/10/hmdb51_org.rar"
wget -O test_train_splits.rar \
  "http://serre-lab.clps.brown.edu/wp-content/uploads/2013/10/test_train_splits.rar"
# See ml_pipeline/src/data/download_datasets.sh for full setup instructions
```

---

### Excluded Dataset — Penn Action
> Low relevance to CPR; repetitive exercise motions (curl, press) lack CPR-specific error taxonomy

Not used in this project. May be revisited if compression rhythm modeling needs additional temporal data.

---

## Tech Stack

### Mobile Application (Android / iOS)
| Layer | Technology | Reason |
|---|---|---|
| Framework | Flutter 3.x + Dart 3.x | Single codebase → Android + iOS; best TFLite integration |
| Pose Estimation | `google_mlkit_pose_detection` | MediaPipe BlazePose; 33 landmarks; offline; 25–30 FPS |
| ML Inference | `tflite_flutter` | On-device INT8 quantized BiLSTM; <5MB; low latency |
| Voice (Primary) | `flutter_tts` | Offline TTS; English + multilingual support |
| Voice (Kinyarwanda) | Umuganda TTS | Local language resonance; culturally appropriate coaching |
| Local Storage | `sqflite` + `path_provider` | Session logs; offline-first |
| DI / State | `get_it` + `riverpod` | Clean dependency injection; reactive state management |
| Animation | `rive` | Animated CPR instructor demo; lightweight |
| Camera | `camera` plugin | Live frame capture for pose pipeline |

### Web Application
| Layer | Technology | Reason |
|---|---|---|
| Pose Estimation | `@mediapipe/pose` (WASM) | Same BlazePose model running in-browser |
| ML Inference | `TensorFlow.js` | Runs the same trained model via WebGL/WASM |
| Voice | Web Speech API | Built into every modern browser; no library needed |
| Voice (Kinyarwanda) | Umuganda TTS HTTP | POST to local or hosted TTS endpoint |
| UI | Vanilla JS + HTML5 Canvas | Lightweight; no framework overhead on low-end devices |
| Storage | IndexedDB | Offline session caching in browser |
| Model Export | `tensorflowjs_converter` | Converts `.h5` → TFJS graph model format |

### ML Pipeline (Python)
| Component | Technology |
|---|---|
| Landmark Extraction | `mediapipe` 0.10+ |
| Model Training | `tensorflow` 2.x / `keras` |
| Video Processing | `opencv-python` |
| Data Augmentation | `albumentations` + custom transforms |
| Experiment Tracking | `wandb` (optional) / `mlflow` |
| Mobile Export | TFLite Converter + INT8 quantization |
| Web Export | `tensorflowjs_converter` → TFJS graph model |
| Analysis | `numpy`, `pandas`, `scipy`, `scikit-learn` |

---

## Project Structure

```
capstone-project/
│
├── README.md
├── pubspec.yaml                       ← Flutter dependencies (mobile)
├── analysis_options.yaml
├── .gitignore
├── .env.example
│
├── lib/                               ← Flutter mobile app (Android / iOS)
│   ├── main.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart     ← CPR thresholds, prompts, config
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── di/
│   │   │   └── injection.dart
│   │   └── utils/
│   │       └── landmark_math.dart     ← Joint angle calculations
│   ├── models/
│   │   ├── session_model.dart
│   │   ├── landmark_frame.dart
│   │   └── cpr_feedback.dart
│   ├── services/
│   │   ├── pose_service.dart          ← MediaPipe (mobile only)
│   │   ├── inference_service.dart     ← TFLite runner (mobile only)
│   │   ├── feedback_engine.dart       ← Priority feedback logic
│   │   ├── tts_service.dart           ← flutter_tts + Umuganda
│   │   └── session_logger.dart        ← SQLite persistence
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── demo_screen.dart
│   │   ├── training_screen.dart
│   │   └── results_screen.dart
│   └── widgets/
│       ├── bpm_indicator.dart
│       ├── pose_overlay.dart
│       ├── feedback_banner.dart
│       └── compression_gauge.dart
│
├── web/                               ← Web application (standalone JS)
│   ├── index.html                     ← Entry point
│   ├── package.json                   ← Node dependencies
│   ├── src/
│   │   ├── main.js                    ← Camera init + app bootstrap
│   │   ├── services/
│   │   │   ├── poseService.js         ← MediaPipe WASM pose estimation
│   │   │   ├── inferenceService.js    ← TensorFlow.js model runner
│   │   │   ├── feedbackEngine.js      ← Logic ported from feedback_engine.dart
│   │   │   └── ttsService.js          ← Web Speech API + Umuganda TTS
│   │   ├── components/
│   │   │   ├── dashboard.js           ← BPM / depth indicators
│   │   │   └── poseOverlay.js         ← Canvas skeleton drawing
│   │   └── utils/
│   │       ├── landmarkMath.js        ← Port of landmark_math.dart
│   │       └── constants.js           ← Port of app_constants.dart
│   └── assets/
│       └── models/                    ← TFJS model files (git-lfs)
│           ├── model.json
│           └── group1-shard1of1.bin
│
├── assets/                            ← Flutter asset bundle
│   ├── models/
│   │   └── cpr_classifier.tflite     ← TFLite model (git-lfs)
│   ├── animations/
│   │   └── cpr_instructor.riv
│   └── images/
│       └── hand_placement_guide.png
│
├── ml_pipeline/                       ← Python training pipeline
│   ├── requirements.txt
│   ├── config.yaml
│   ├── notebooks/
│   │   ├── 01_dataset_exploration.ipynb
│   │   ├── 02_landmark_extraction.ipynb
│   │   ├── 03_model_training.ipynb
│   │   └── 04_evaluation.ipynb
│   └── src/
│       ├── data/
│       │   ├── download_datasets.sh
│       │   ├── extract_landmarks.py
│       │   └── augment_data.py
│       ├── models/
│       │   ├── cnn_classifier.py
│       │   └── lstm_temporal.py
│       ├── training/
│       │   ├── train.py
│       │   └── evaluate.py
│       └── export/
│           ├── convert_to_tflite.py   ← Export for Android / iOS
│           └── convert_to_tfjs.py     ← Export for Web
│
└── test/
    ├── unit/
    │   ├── feedback_engine_test.dart
    │   └── landmark_math_test.dart
    └── widget/
        └── training_screen_test.dart
```

---

## Getting Started

### Prerequisites

**For Flutter App (Android / iOS):**
```bash
flutter --version    # >= 3.10.0
flutter doctor
git lfs install
```

**For Web App:**
```bash
node --version       # >= 18.0
npm --version
```

**For ML Pipeline:**
```bash
python --version     # 3.10+
pip --version
```

---

### Flutter App Setup (Android / iOS)

```bash
# 1. Clone the repository
git clone git@github.com:Gatwaza/Capstone-Project.git
cd Capstone-Project

# 2. Install dependencies
flutter pub get

# 3. Copy environment config
cp .env.example .env

# 4. Pull model assets via Git LFS
git lfs pull

# 5. Run on connected device
flutter run

# Release builds
flutter build apk --release        # Android
flutter build ipa --release        # iOS (requires Xcode on macOS)
```

**Android — add to `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

---

### Web App Setup

```bash
cd web

# Install dependencies
npm install

# Development server (with hot reload)
npm run dev
# → http://localhost:3000

# Production build
npm run build
# → web/dist/  (deploy to any static host: GitHub Pages, Netlify, Vercel)
```

**Browser requirements:**
- Chrome 90+ / Firefox 95+ / Safari 15.4+
- Camera permission required
- Internet required on first load (downloads WASM bundles ~8MB); subsequent loads use browser cache

**Deploy to GitHub Pages:**
```bash
npm run build
npm run deploy     # pushes web/dist/ to gh-pages branch
```

---

### ML Pipeline Setup

```bash
cd ml_pipeline
python -m venv venv
source venv/bin/activate        # Linux / Mac
# venv\Scripts\activate         # Windows

pip install -r requirements.txt

# Download datasets
chmod +x src/data/download_datasets.sh
./src/data/download_datasets.sh

# Full pipeline (run in order)
python src/data/extract_landmarks.py --config config.yaml
python src/training/train.py --config config.yaml

# Export for BOTH platforms
python src/export/convert_to_tflite.py --config config.yaml
# → assets/models/cpr_classifier.tflite  (Flutter mobile)

python src/export/convert_to_tfjs.py --config config.yaml
# → web/assets/models/model.json + shards  (Web app)
```

---

## Voice Guidance: Two Approaches

### Option 1 — Pre-recorded Audio + TTS Hybrid (Recommended for MVP)
> Best for naturalness and Kinyarwanda authenticity

Pre-recorded `.wav` files by a native Kinyarwanda speaker cover all ~25 core prompts. `flutter_tts` / Web Speech API handle dynamic fallback messages.

```
assets/audio/
├── en/
│   ├── prompt_start.wav             "Place your hands on the center of the chest"
│   ├── prompt_compress_deeper.wav   "Press deeper — aim for 5 centimeters"
│   ├── prompt_straighten_arms.wav   "Straighten your arms — lock your elbows"
│   ├── prompt_speed_up.wav          "Speed up — keep a steady beat"
│   ├── prompt_slow_down.wav         "Slow down slightly"
│   ├── prompt_hand_too_high.wav     "Move your hands down — center of chest"
│   └── prompt_keep_going.wav        "Good work — keep going"
└── rw/                              # Kinyarwanda (Umuganda TTS or native speaker)
    └── ...
```

### Option 2 — Fully Synthetic TTS (No Recordings Required)
> Simpler to implement; recommended if recording sessions are not feasible

Mobile uses `flutter_tts` (English) and Umuganda TTS (Kinyarwanda). Web uses the built-in Web Speech API. All prompts are plain text strings — no `.wav` files needed.

```dart
// Mobile: app_constants.dart
static const Map<String, String> promptsEn = {
  'start':           'Place your hands on the center of the chest.',
  'compress_deeper': 'Press deeper. Aim for five centimeters.',
  'straighten_arms': 'Straighten your arms. Lock your elbows.',
  'speed_up':        'Speed up. Keep a steady beat.',
};
static const Map<String, String> promptsRw = {
  'start':           'Shyira intoki zo hagati y\'isaya.',
  'compress_deeper': 'Kanda cyane. Gera kuri santimetero eshanu.',
};
```

```javascript
// Web: web/src/utils/constants.js (identical strings, different runtime)
export const PROMPTS_EN = {
  start:           'Place your hands on the center of the chest.',
  compress_deeper: 'Press deeper. Aim for five centimeters.',
};
```

---

## ML Pipeline

### Model Architecture

```
Input: 30 frames x 12 landmark features
         |
  Bidirectional LSTM(64 units) — captures compression downstroke + upstroke
         |
  LSTM(32 units)
         |
  Dense(32) — ReLU + Dropout(0.3)
         |
  Dense(8, softmax) — output classes:
         |-- correct_compression
         |-- wrong_hand_high
         |-- wrong_hand_low
         |-- bent_elbows
         |-- compression_too_shallow
         |-- rate_too_slow
         |-- rate_too_fast
         +-- not_compressing
```

> **Note:** The model operates on MediaPipe landmark features — not raw video pixels.
> There is no CNN stage. This makes the model lightweight (<5MB), fast on mid-range
> hardware, and much more data-efficient to train with a constrained dataset.

### Feature Engineering (per frame, from MediaPipe landmarks)
```python
features = [
    elbow_angle_left,          # ~180 degrees = locked (correct)
    elbow_angle_right,
    elbow_angle_mean,          # mean across both arms
    spine_verticality,         # lean angle from vertical
    wrist_y_position,          # normalised Y coordinate
    wrist_velocity_y,          # compression depth proxy
    wrist_acceleration_y,      # transition detection
    normalised_depth,          # wrist displacement / shoulder width
    shoulder_width,            # body-size normalisation factor
    mean_landmark_confidence,  # MediaPipe visibility score
    left_elbow_visible,        # binary occlusion flag
    right_elbow_visible,       # binary occlusion flag
]
```

### Compression Rate (Rule-Based, Not ML)
```python
# Peak detection on wrist Y-coordinate — more reliable than classification
from scipy.signal import find_peaks
peaks, _ = find_peaks(wrist_y_sequence, distance=fps * 0.4)
bpm = 60 / np.mean(np.diff(peaks) / fps)
# Target: 100-120 bpm per ERC Guidelines 2021
```

### Dual Export for Both Platforms
```bash
# Mobile: TFLite INT8
python src/export/convert_to_tflite.py
# -> assets/models/cpr_classifier.tflite  (~3-5 MB)

# Web: TensorFlow.js graph model
python src/export/convert_to_tfjs.py
# -> web/assets/models/model.json + weight shards
```

---

## Evaluation & Metrics

### System Metrics
| Metric | Target | Platform |
|---|---|---|
| Classifier F1-score | >= 85% per class | Both |
| Compression rate accuracy | +/-5 bpm of true rate | Both |
| Inference latency | < 100ms per frame | Mobile: TFLite; Web: TFJS/WebGL |
| Model size | < 5 MB | Mobile TFLite |
| Landmark detection FPS | >= 25 FPS | Both |
| Web model initial load | < 3s on 4G | Web only |

### Pilot Study Metrics (Group A vs Group B)
| Metric | Instrument |
|---|---|
| Compression rate adherence (100-120 bpm) | Session logger |
| Hand placement accuracy (%) | BiLSTM classifier output |
| Elbow lock compliance (% frames) | Pose estimation |
| Time to first compression (s) | Event timestamp |
| Self-efficacy change | Likert pre/post survey |
| Cognitive load | NASA-TLX |
| Usability score | SUS (>=68 = acceptable) |

---

## Roadmap

| Phase | Timeline | Status |
|---|---|---|
| Phase 1: Infrastructure + Pose Pipeline (Mobile + Web) | Month 1 | In Progress |
| Phase 2: ML Model Training + TFLite + TFJS Export | Month 2 | Pending |
| Phase 3: Full App Integration + TTS (all platforms) | Month 3 | Pending |
| Phase 4: Pilot Study + Evaluation | Month 4 | Pending |
| Future: USSD/SMS interface (feature phones) | Post-capstone | Planned |
| Future: Kinyarwanda Umuganda TTS fine-tuning | Post-capstone | Planned |
| Future: Full offline Progressive Web App (PWA) | Post-capstone | Planned |
| Future: Expand to bleeding control, stroke, emergency childbirth | Post-capstone | Planned |

---

## Research Context

This project is developed as a capstone for **The African Leadership University**, Rwanda. Key references:

- Anto-Ocrah et al. (2020) — Bystander CPR attitudes in low-resource settings
- Ecker et al. (2024) — Computer vision CPR feedback; **doubled correct depth proportions**
- Perkins et al. (2021) — ERC Guidelines 2021 (100-120 bpm, 5-6 cm depth)
- Rao et al. (2023) — ML CPR guidance significantly increased procedural accuracy
- Wang et al. (2023) — CPR-Coach dataset; ImagineNet; ICCV 2023 Demo
- GSMA Intelligence (2023) — Mobile Economy Sub-Saharan Africa

---

## Contributing

```bash
# Branch naming convention
feature/pose-pipeline
feature/web-tfjs-inference
fix/tts-kinyarwanda-fallback
chore/update-dependencies
docs/evaluation-protocol

# Commit format (Conventional Commits)
feat: add compression rate peak detection
feat(web): add TensorFlow.js inference service
fix: resolve MediaPipe landmark confidence threshold
docs: update dataset download instructions
```

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

> **Medical Disclaimer:** This tool is a training and simulation aid only. It does not replace formal CPR certification or professional medical advice. Always call emergency services first.
