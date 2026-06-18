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
| Web-only deployment | Removed native iOS/Android folders and build artifacts |
| Connected inference | TF.js pipeline uses the CNN-BiLSTM assessment model |
| First aid focus | Broad first aid technique evaluation with CPR-related posture and compression metrics |
| ML pipeline preserved | Python pipeline remains available for training and TFJS export |
| Dataset link | Public dataset available via Google Drive |

---

## Running the Web App

```bash
cd web
npm install
npm run dev
# open http://localhost:3000
```

---

## Key Features

| Feature | Status | Notes |
|---|---|---|
| Real-time pose estimation | ✓ | Pose landmarks via @mediapipe/pose in browser |
| Connected model assessment | ✓ | CNN-BiLSTM inference in TF.js |
| First aid technique evaluation | ✓ | Focuses on posture and compression technique, not only CPR steps |
| Web-native feedback | ✓ | Live browser rendering and corrective prompts |
| Session persistence | ✓ | IndexedDB logging and export |
| ML training pipeline | ✓ | Python pipeline with TFJS export |

---

## Platform Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Novice Web Application                     │
│     Live pose capture · landmark extraction · inference       │
└──────────────────────────────────────────────────────────────┘
                       │
                       ▼
         ┌──────────────────────────────────────────────────┐
         │          Browser runtime                         │
         │  - Pose: @mediapipe/pose WASM                    │
         │  - Model: TF.js CNN-BiLSTM                       │
         │  - Feedback: Web Speech API                      │
         │  - Storage: IndexedDB                            │
         └──────────────────────────────────────────────────┘
```
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
└── vercel.json                        ← web deployment config
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

## Dataset

The pipeline uses the public dataset available here:

https://drive.google.com/drive/folders/1zJoJYrmvIv9TgNd5ZmVYVq7odkB5wI5e?usp=drive_link

### Training setup

```python
from google.colab import drive
from pathlib import Path
import os, pickle, re, time, json, warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, f1_score
from sklearn.utils.class_weight import compute_class_weight
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, callbacks, optimizers, losses, metrics

warnings.filterwarnings('ignore')
tf.random.set_seed(42)
np.random.seed(42)

gpus = tf.config.list_physical_devices('GPU')
print(f'TensorFlow : {tf.__version__}')
print(f'GPUs       : {len(gpus)}')
if gpus:
    print(f'GPU name   : {tf.test.gpu_device_name()}')
    tf.config.experimental.set_memory_growth(gpus[0], True)

DATA_ROOT      = Path('/content/drive/MyDrive/cpr_coach_data')
KEYPOINTS_DIR  = DATA_ROOT / 'Keypoints'
ANN_DIR        = DATA_ROOT / 'ann'
CHECKPOINT_DIR = Path('/content/drive/MyDrive/cpr_coach_checkpoints_tf')
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)

RESUME_FILE = CHECKPOINT_DIR / 'resume_state.json'

print(f'Data root      : {DATA_ROOT}')
print(f'Keypoints dir  : {KEYPOINTS_DIR}')
print(f'Annotation dir : {ANN_DIR}')
print(f'Checkpoint dir : {CHECKPOINT_DIR}')
print('\n✓ Stage 1 complete')
```

### Dataset summary

- `train_keypoints.pkl`: 1344 entries
- `test_keypoints.pkl`: 1008 entries
- `Unique physical videos`: 2352
- `Matched annotation rows`: 2352

---

## ML Pipeline

### Architecture
```
Input: pose landmark sequence
  → CNN encoder
  → Bidirectional LSTM
  → Dense + Dropout
  → Softmax classification
```

### Model
Production inference uses the **CNN-BiLSTM** model, which outperformed alternate architectures in sequence validation.

### Evaluation targets
| Metric | Target |
|---|---|
| F1-weighted | ≥ 0.80 |
| TFJS inference latency | < 100 ms per frame |
| Model size | < 10 MB |

---

## License

**GNU General Public License v3.0** — see [LICENSE](LICENSE).

---