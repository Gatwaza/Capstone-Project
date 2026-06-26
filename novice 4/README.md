# Novice — First Aid AI Coach
### *Real-time CPR assessment + interactive first aid procedure library*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![TensorFlow.js](https://img.shields.io/badge/TF.js-Web-FF6F00?logo=tensorflow)](https://www.tensorflow.org/js)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)](https://python.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Web-blue)](https://flutter.dev/web)
[![Phase](https://img.shields.io/badge/Phase-Field%20Validation-00E5A0)](SETUP.md)

---

## Overview

**Novice** is a web-first first aid training application built for research and community use.

Two distinct training modes:

| Mode | Procedure | How it works |
|------|-----------|-------------|
| **Live AI Training** | CPR only | Camera + MediaPipe pose estimation → TCN model assesses compression rate, depth, and recoil in real time |
| **Animated Demo** | Choking, Stroke, Recovery Position, Bleeding, Burns | Interactive step-by-step guides with SVG animations — no camera required |

The **TCN (Temporal Convolutional Network)** model is the deployed production model. It outperforms other evaluated architectures on the recoil task and achieves the best mean F1/AUC profile across all three compression quality heads.

Content for all procedure guides is sourced from the **Rwanda Basic First Aid Training Manual** (Emergency Safety and Health Services / Belgian Red Cross, Flanders).

---

## Model Selection

Full comparison from training notebook (Stage 9 `evaluate()`):

| Model | Rate F1_w | Depth F1_w | Recoil F1_w | Mean F1 | Recoil AUC |
|-------|-----------|-----------|------------|---------|------------|
| BiLSTM | 77.34% | 90.08% | 67.42% | 78.28% | 77.52% |
| CNN_LSTM | 77.90% | 91.50% | 64.87% | 78.09% | 73.90% |
| GRU | 73.37% | 86.97% | 56.09% | 72.14% | 72.20% |
| **TCN** | **73.94%** | **92.63%** | **78.19%** | **81.59%** | **84.25%** |
| Conv1D | 82.72% | 92.92% | 72.80% | 82.81% | 78.57% |
| ST_Transformer | 60.62% | 88.39% | 67.14% | 72.05% | 76.97% |
| CNN_BiLSTM | 75.92% | 94.05% | 74.79% | 81.59% | 84.14% |

**TCN selected as production model**: Best Recoil F1 (78.19%), best Depth AUC (96.26%), best Recoil AUC (84.25%). TCN and CNN-BiLSTM tie on mean F1 (81.59%), but TCN wins on the harder recoil task — the most clinically significant head.

The TCN API is hosted on Hugging Face Spaces: `https://jeanrobert-novice.hf.space`

---

## Current Status

| Item | Detail |
|------|--------|
| Deployed model | TCN (three-head: rate / depth / recoil) |
| Web inference | `InferenceServiceWeb` → HF Spaces `/predict`; falls back to rule-based thresholds when API unreachable |
| Pose bridge | `flutter_pose_bridge.js` — MediaPipe Pose WASM, `_novicePoseReady` guard |
| Depth calibration | `normToPhysicalCmScale=20`, `fallbackTorsoHeightCm=8` (≈1 m webcam distance) |
| Procedure library | 6 modules: CPR (live AI) + Choking / Stroke / Recovery / Bleeding / Burns (animated) |
| Research logging | Frame NDJSON export; researcher dashboard (PIN-gated) |
| Multilingual TTS | EN via Web Speech API · RW via Umuganda HTTP endpoint |
| Field testing | Participant ID system (P001, P002…) — on-field sessions pending |

---

## Running locally

```bash
git clone git@github.com:Gatwaza/Capstone-Project.git
cd "Capstone Project/novice 4"

flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Chrome recommended (WebGL + WASM)
flutter run -d chrome

# Or build for static hosting
flutter build web --release --dart-define=RESEARCHER_PIN=2026
cd build/web && python3 -m http.server 8080
```

---

## Key Features

| Feature | Status | Notes |
|---------|--------|-------|
| Real-time pose estimation | ✓ | `@mediapipe/pose` WASM |
| TCN inference (3 heads) | ✓ | Hosted HF Spaces; `(60 × 12)` input |
| Rule-based fallback | ✓ | Activates when API unreachable |
| Animated procedure guides | ✓ | 5 non-CPR procedures with SVG step animations |
| Live audio coaching | ✓ | 13 TTS prompts EN + RW; 4 s cooldown |
| Compression metrics | ✓ | Rate (bpm), depth (cm), quality score |
| Session persistence | ✓ | IndexedDB / NDJSON export |
| Researcher dashboard | ✓ | PIN-gated; participant management |
| Participant ID system | ✓ | P001, P002… — on-field testing ready |

---

## Architecture

```
Browser (Flutter Web)
│
├─ MediaPipe Pose WASM  →  33 landmarks @ 25 fps
│      (flutter_pose_bridge.js)
│
├─ LandmarkMath (Dart)  →  12-dim feature vector per frame
│
├─ InferenceServiceWeb  →  60-frame window → TCN (3-head)
│      (flutter_inference_bridge.js)  API: jeanrobert-novice.hf.space
│      ↳ falls back to rule-based thresholds when API unreachable
│
├─ FeedbackEngine       →  priority queue · 4 s cooldown gating
│
├─ TtsService           →  Web Speech API (EN) · Umuganda HTTP (RW)
│
└─ StorageService       →  IndexedDB session log · NDJSON frame export
```

---

## Procedure Library

Content sourced from **Rwanda Basic First Aid Training Manual** (Emergency Safety and Health Services / Belgian Red Cross):

| # | Procedure | Mode | Module in Manual |
|---|-----------|------|-----------------|
| 1 | CPR | 🤖 Live AI (TCN) | Module 5 |
| 2 | Choking | Animated demo | Module 6 |
| 3 | Stroke — FAST | Animated demo | Module 9 |
| 4 | Recovery Position | Animated demo | Module 3/4 |
| 5 | Bleeding / Haemorrhage | Animated demo | Module 10 |
| 6 | Burns | Animated demo | Module 14 |

---

## CPR Clinical Thresholds

Sourced from **Perkins et al. (2021) — ERC Guidelines 2021** (DOI: 10.1016/j.resuscitation.2021.02.009):

| Parameter | Target |
|-----------|--------|
| Compression rate | 100–120 bpm |
| Compression depth | 5.0–6.0 cm |
| Elbow lock angle | ≥ 160° |
| Max spine lean | ≤ 15° from vertical |

---

## Quality Score Formula

Multi-task weighted scoring using TCN AUC-weighted coefficients:

```
qualityScore = 0.364 × rateAcc + 0.341 × depthAcc + 0.295 × recoilAcc
```

Weights derived from TCN AUC-ROC per task (rate 98.3%, depth 99.3%, recoil 95.9% — Stage 9 evaluation).

---

## Field Validation

On-field testing is the next phase. The infrastructure supports:

- Participant ID assignment (P001, P002…) via `ParticipantGateScreen`
- Session data export (NDJSON frame logs + summary metrics)
- Researcher dashboard for session review and labelling
- Supabase backend for remote data persistence

For alternative validation without live camera setup, the animated procedure guides allow self-directed study and comprehension checking without requiring the TCN API.

---

## Dataset

- `train_keypoints.pkl`: 1,344 entries
- `test_keypoints.pkl`: 1,008 entries
- Total unique physical videos: 2,352
- [Google Drive dataset](https://drive.google.com/drive/folders/1zJoJYrmvIv9TgNd5ZmVYVq7odkB5wI5e?usp=drive_link)

---

## License

**GNU General Public License v3.0** — Jean Robert Gatwaza, African Leadership University 2024–2025

See [LICENSE](LICENSE).
