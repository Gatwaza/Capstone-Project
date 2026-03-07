# CPR-AI Coach — AI-Guided First Aid Simulation Tool
### *Empowering Every Bystander in Sub-Saharan Africa*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TFLite-2.x-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python)](https://python.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev/multi-platform)

---

## Table of Contents

- [Project Overview](#-project-overview)
- [Problem Statement](#-problem-statement)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Datasets](#-datasets)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Flutter App Setup](#flutter-app-setup)
  - [ML Pipeline Setup](#ml-pipeline-setup)
- [Voice Guidance: Two Approaches](#-voice-guidance-two-approaches)
- [ML Pipeline](#-ml-pipeline)
- [Evaluation & Metrics](#-evaluation--metrics)
- [Roadmap](#-roadmap)
- [Research Context](#-research-context)
- [Contributing](#-contributing)
- [License](#-license)

---

## Project Overview

**CPR-AI Coach** is a cross-platform (Android/iOS) mobile application that uses real-time pose estimation and machine learning to coach completely untrained bystanders through CPR (Cardiopulmonary Resuscitation) in emergency situations — **with no internet connection required**.

This is the capstone project for The African Leadership University, developed in the context of Sub-Saharan Africa where:
- **41%** of all deaths could be addressed by emergency interventions *(Anto-Ocrah et al., 2020)*
- Official EMS response is rare — bystanders are the first and often only responder
- Smartphone ownership has grown from 32% (2012) to ~50% (2022) *(GSMA, 2023)*
- Each minute without CPR cuts survival by **~10%**; immediate bystander CPR can **triple** survival chances

---

## Problem Statement

In Rwanda and across Sub-Saharan Africa, untrained bystanders witnessing cardiac emergencies have no real-time guidance system to follow. Existing first-aid apps deliver static videos or text they do not observe the user, correct posture errors, or adapt to performance. This tool fills that gap by combining:

- **Camera-based pose estimation** (MediaPipe BlazePose)
- **On-device ML classification** (CNN + LSTM via TFLite)
- **Adaptive voice coaching** (flutter_tts + Umuganda TTS for Kinyarwanda)
- **100% offline operation** — no API calls, no internet dependency

---

## Key Features

| Feature | Description |
|---|---|
| Real-time Pose Estimation | MediaPipe BlazePose tracks 33 body landmarks at 25–30 FPS |
| Error Classification | CNN/LSTM detects: wrong hand placement, bent elbows, shallow depth, wrong rate |
| Voice Coaching | Prioritized prompt queue in English + Kinyarwanda (Umuganda TTS) |
| Live Dashboard | BPM counter, depth indicator, compression fraction display |
| Fully Offline | All inference on-device; TFLite INT8 quantized model (~3–5 MB) |
| Mid-Range Optimized | Tested on Tecno Spark / Samsung A-series (≤2GB RAM devices) |
| Session Logging | Local SQLite log of all metrics for post-session review |
| Animated Demo | On-screen animated instructor shows correct technique |

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
│                                        │   (CNN + LSTM       │  │
│                                        │    Classifier)      │  │
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
| **Access** | Sample: Google Drive link on dataset page. Full dataset: email slwang19@fudan.edu.cn with institution and purpose |

**To request full access:**
```
Email: slwang19@fudan.edu.cn
Subject: CPR-Coach Dataset Request — [Your Institution]
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
> Used for CNN backbone pre-training on general human motion

| Property | Value |
|---|---|
| **Source** | [HMDB-51](https://serre-lab.clps.brown.edu/resource/hmdb-a-large-human-motion-database/) |
| **Videos** | 6,766 clips across 51 action categories |
| **Usage** | Transfer learning for temporal motion modeling (not CPR-specific) |
| **Access** | Free download from Brown University Serre Lab |

```bash
# Download HMDB-51
wget -O hmdb51_org.rar "https://serre-lab.clps.brown.edu/resource/hmdb-a-large-human-motion-database/"
# See ml_pipeline/src/data/download_datasets.sh for full instructions
```

---

### Excluded Dataset — Penn Action
> Low relevance to CPR; repetitive exercise motions (curl, press) lack CPR-specific error taxonomy

Not used in this project. May be revisited if compression rhythm modeling needs additional temporal data.

---

## Tech Stack

### Mobile Application
| Layer | Technology | Reason |
|---|---|---|
| Framework | Flutter 3.x + Dart 3.x | Single codebase → Android + iOS; best TFLite integration |
| Pose Estimation | `google_mlkit_pose_detection` | MediaPipe BlazePose; 33 landmarks; offline; 25–30 FPS |
| ML Inference | `tflite_flutter` | On-device INT8 quantized model; <5MB; low latency |
| Voice (Primary) | `flutter_tts` | Offline TTS; English + multilingual support |
| Voice (Kinyarwanda) | Umuganda TTS | Local language resonance; culturally appropriate coaching |
| Local Storage | `sqflite` + `path_provider` | Session logs; offline-first |
| DI / State | `get_it` + `riverpod` | Clean dependency injection; reactive state management |
| Animation | `rive` | Animated CPR instructor demo; lightweight |
| Camera | `camera` plugin | Live frame capture for pose pipeline |

### ML Pipeline (Python)
| Component | Technology |
|---|---|
| Landmark Extraction | `mediapipe` 0.10+ |
| Model Training | `tensorflow` 2.x / `keras` |
| Video Processing | `opencv-python` |
| Data Augmentation | `albumentations` + custom transforms |
| Experiment Tracking | `wandb` (optional) / `mlflow` |
| Model Export | TFLite Converter + INT8 quantization |
| Analysis | `numpy`, `pandas`, `scipy`, `scikit-learn` |

---

## Project Structure

```
cpr-ai-coach/
│
├── README.md                          ← You are here
├── pubspec.yaml                       ← Flutter dependencies
├── analysis_options.yaml              ← Dart linting rules
├── .gitignore
├── .env.example                       ← Environment variable template
│
├── lib/
│   ├── main.dart                      ← App entry point
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart     ← CPR thresholds, timing, config
│   │   ├── theme/
│   │   │   └── app_theme.dart         ← Design system / colors
│   │   ├── di/
│   │   │   └── injection.dart         ← GetIt service locator setup
│   │   └── utils/
│   │       └── landmark_math.dart     ← Joint angle calculations
│   │
│   ├── models/
│   │   ├── session_model.dart         ← Session data structure
│   │   ├── landmark_frame.dart        ← Per-frame pose data
│   │   └── cpr_feedback.dart          ← Feedback event model
│   │
│   ├── services/
│   │   ├── pose_service.dart          ← MediaPipe pose extraction
│   │   ├── inference_service.dart     ← TFLite model runner
│   │   ├── feedback_engine.dart       ← Priority feedback logic
│   │   ├── tts_service.dart           ← Voice synthesis (TTS + Umuganda)
│   │   └── session_logger.dart        ← SQLite session persistence
│   │
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── demo_screen.dart           ← Animated technique demo
│   │   ├── training_screen.dart       ← Live camera + coaching UI
│   │   └── results_screen.dart        ← Post-session metrics
│   │
│   └── widgets/
│       ├── bpm_indicator.dart
│       ├── pose_overlay.dart          ← Skeleton overlay on camera
│       ├── feedback_banner.dart
│       └── compression_gauge.dart
│
├── assets/
│   ├── models/
│   │   └── cpr_classifier.tflite     ← Trained + quantized model (git-lfs)
│   ├── animations/
│   │   └── cpr_instructor.riv        ← Rive animated instructor
│   └── images/
│       └── hand_placement_guide.png
│
├── ml_pipeline/                       ← Python ML training pipeline
│   ├── requirements.txt
│   ├── config.yaml                    ← Hyperparameters + paths
│   ├── notebooks/
│   │   ├── 01_dataset_exploration.ipynb
│   │   ├── 02_landmark_extraction.ipynb
│   │   ├── 03_model_training.ipynb
│   │   └── 04_evaluation.ipynb
│   └── src/
│       ├── data/
│       │   ├── download_datasets.sh
│       │   ├── extract_landmarks.py   ← MediaPipe batch processing
│       │   └── augment_data.py
│       ├── models/
│       │   ├── cnn_classifier.py
│       │   └── lstm_temporal.py
│       ├── training/
│       │   ├── train.py
│       │   └── evaluate.py
│       └── export/
│           └── convert_to_tflite.py
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

**For Flutter App:**
```bash
# Flutter SDK (≥3.10.0)
flutter --version

# Ensure both platforms are set up
flutter doctor

# Git LFS for model assets
git lfs install
```

**For ML Pipeline:**
```bash
python --version   # 3.10+
pip --version
```

---

### Flutter App Setup

```bash
# 1. Clone the repository
git clone git@github.com:Gatwaza/Capstone-Project.git
cd Capstone-Project

# 2. Install dependencies
flutter pub get

# 3. Copy environment config
cp .env.example .env
# Edit .env with your configuration (see Environment Variables section)

# 4. Pull model assets via Git LFS
git lfs pull

# 5. Run on connected device
flutter run

# For release build
flutter build apk --release           # Android
flutter build ipa --release           # iOS (requires Xcode)
```

**Android-specific (add to `android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

---

### ML Pipeline Setup

```bash
cd ml_pipeline

# Create virtual environment
python -m venv venv
source venv/bin/activate        # Linux/Mac
# venv\Scripts\activate         # Windows

# Install dependencies
pip install -r requirements.txt

# Download CPR-Coach sample data
# 1. Download from Google Drive (see dataset section above for full access)
# 2. Place in: ml_pipeline/data/raw/cpr_coach/

# Run landmark extraction
python src/data/extract_landmarks.py --config config.yaml

# Train model
python src/training/train.py --config config.yaml

# Export to TFLite
python src/export/convert_to_tflite.py --model_path outputs/best_model.h5
# Output: assets/models/cpr_classifier.tflite
```

---

## Voice Guidance: Two Approaches

### Option 1 — Pre-recorded Audio + TTS Hybrid (Recommended for MVP)
> Best for naturalness and Kinyarwanda authenticity

Pre-recorded `.wav` files by a native Kinyarwanda speaker cover all ~25 core prompts. `flutter_tts` handles dynamic/fallback messages.

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
    ├── prompt_start.wav
    └── ...
```

### Option 2 — Fully Synthetic TTS (No Recordings Required)
> Simpler to implement; recommended if recording sessions aren't feasible

Both `flutter_tts` (English) and the Umuganda TTS engine (Kinyarwanda) synthesize all prompts **on-the-fly** from plain text strings defined in `app_constants.dart`. No `.wav` files needed. The `TTSService` manages a priority queue so prompts never overlap.

```dart
// All prompts are plain strings — TTS engine speaks them dynamically
static const Map<String, String> promptsEn = {
  'start':           'Place your hands on the center of the chest.',
  'compress_deeper': 'Press deeper. Aim for five centimeters.',
  'straighten_arms': 'Straighten your arms. Lock your elbows.',
  'speed_up':        'Speed up. Keep a steady beat.',
  // ...
};

static const Map<String, String> promptsRw = {
  'start':           'Shyira intoki zo hagati y\'isaya.',
  'compress_deeper': 'Kanda cyane. Gera kuri santimetero eshanu.',
  // ...
};
```

**Umuganda TTS integration** is handled via HTTP to a locally-bundled or sideloaded Kinyarwanda TTS model. If unavailable at runtime, the service auto-falls back to `flutter_tts` in English. See `lib/services/tts_service.dart`.

---

## ML Pipeline

### Model Architecture

```
Input: 30 frames × 12 landmark features
         ↓
  LSTM(64 units) — captures temporal compression rhythm
         ↓
  Dense(32) — ReLU
         ↓
  Dropout(0.3)
         ↓
  Dense(8, softmax) — output classes:
         ├── correct_compression
         ├── wrong_hand_high
         ├── wrong_hand_low
         ├── bent_elbows
         ├── compression_too_shallow
         ├── rate_too_slow
         ├── rate_too_fast
         └── not_compressing
```

### Feature Engineering (per frame, from MediaPipe landmarks)
```python
features = [
    elbow_angle_left,          # ~180° = locked (correct)
    elbow_angle_right,
    shoulder_angle,            # compression axis alignment
    wrist_to_sternum_dist,     # hand placement proximity
    spine_verticality,         # lean angle
    wrist_velocity_y,          # compression depth proxy
    wrist_acceleration_y,      # transition detection
    hip_shoulder_alignment,    # posture
    compression_phase,         # 0=up, 1=down (derived)
    left_visibility,           # MediaPipe landmark confidence
    right_visibility,
    overall_confidence,        # mean confidence score
]
```

### Compression Rate (Rule-Based, Not ML)
```python
# Peak detection on wrist Y-coordinate — more reliable than classification
from scipy.signal import find_peaks
peaks, _ = find_peaks(wrist_y_sequence, distance=fps * 0.4)
bpm = 60 / np.mean(np.diff(peaks) / fps)
# Target: 100–120 bpm per ERC Guidelines 2021
```

### Training Configuration (`config.yaml`)
```yaml
dataset:
  primary: cpr_coach
  secondary: hmdb51       # for backbone pre-training only
  sequence_length: 30     # frames per sample
  overlap: 15             # 50% sliding window

model:
  lstm_units: 64
  dense_units: 32
  dropout: 0.3
  learning_rate: 0.001
  batch_size: 32
  epochs: 50
  early_stopping_patience: 8

export:
  quantization: int8      # ~4x size reduction
  target_size_mb: 5       # max for mid-range phones
```

---

## Evaluation & Metrics

### System Metrics
| Metric | Target | Measurement |
|---|---|---|
| Classifier Accuracy | ≥ 85% | F1-score per class on CPR-Coach test split |
| Compression Rate Accuracy | ±5 bpm of true rate | vs. metronome reference |
| Inference Latency | < 100ms per frame | Pixel 4a / Samsung A32 benchmark |
| Model Size | < 5 MB | Post INT8 quantization |
| Landmark Detection FPS | ≥ 25 FPS | MediaPipe on target devices |

### Pilot Study Metrics (Group A vs Group B)
| Metric | Instrument |
|---|---|
| Compression rate adherence (100–120 bpm) | Session logger |
| Hand placement accuracy (%) | CNN classifier output |
| Elbow lock compliance (% frames) | Pose estimation |
| Time to first compression (s) | Event timestamp |
| Self-efficacy change | Likert pre/post survey |
| Cognitive load | NASA-TLX |
| Usability score | SUS (≥68 = acceptable) |

---

## Roadmap

| Phase | Timeline | Status |
|---|---|---|
| Phase 1: Infrastructure + Pose Pipeline | Month 1 | In Progress |
| Phase 2: ML Model Training + TFLite Export | Month 2 | ⏳ Pending |
| Phase 3: Full App Integration + TTS | Month 3 | ⏳ Pending |
| Phase 4: Pilot Study + Evaluation | Month 4 | ⏳ Pending |
| Future: USSD/SMS interface (feature phones) | Post-capstone | 💡 Planned |
| Future: Kinyarwanda Umuganda TTS model fine-tuning | Post-capstone | 💡 Planned |
| Future: Expand to bleeding control, stroke, emergency childbirth | Post-capstone | 💡 Planned |

---

## Research Context

This project is developed as a capstone for The African Leadership University, Rwanda. Key references:

- Anto-Ocrah et al. (2020) — Bystander CPR attitudes in low-resource settings
- Ecker et al. (2024) — Computer vision CPR feedback; **doubled correct depth proportions**
- Perkins et al. (2021) — ERC Guidelines 2021 (100–120 bpm, 5–6 cm depth)
- Rao et al. (2023) — ML CPR guidance significantly increased procedural accuracy
- Wang et al. (2023) — CPR-Coach dataset; ImagineNet; ICCV 2023 Demo
- GSMA Intelligence (2023) — Mobile Economy Sub-Saharan Africa

---

## Contributing

```bash
# Branch naming convention
feature/pose-pipeline
fix/tts-kinyarwanda-fallback
chore/update-dependencies
docs/evaluation-protocol

# Commit format (Conventional Commits)
feat: add compression rate peak detection
fix: resolve MediaPipe landmark confidence threshold
docs: update dataset download instructions
```

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).

> **Medical Disclaimer:** This tool is a training and simulation aid only. It does not replace formal CPR certification or professional medical advice. Always call emergency services first.

---

*Built with ❤️ for Rwanda and Sub-Saharan Africa — "Buri mugenzi yagutabara" (Anyone can help)*