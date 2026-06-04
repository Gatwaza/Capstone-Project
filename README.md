# Novice — CPR-AI Coach

**Development and Evaluation of a Machine Learning First Aid Simulation Training Tool in Sub-Saharan Africa**

Jean Robert Gatwaza · African Leadership University · Capstone 2026
Supervisor: Marvin Ogore
License: GNU General Public License v3.0

---

## What Novice Does

Novice is a cross-platform (Android / iOS / Web) mobile application that delivers real-time, AI-guided CPR coaching to untrained bystanders. Using the device camera and on-device machine learning (MediaPipe BlazePose + BiLSTM), it detects chest compression errors and delivers corrective voice guidance in English and Kinyarwanda — no internet required.

It is simultaneously a pilot study research tool: the app enrolls participants (with informed consent), logs anonymised interaction metrics (never video), runs the SUS / NASA-TLX / self-efficacy surveys, and exports structured CSV and JSON for the Group A vs B comparative analysis described in the capstone proposal.

---

## Project Structure

```
novice/
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart     # ERC thresholds, prompt strings
│   │   ├── di/injection.dart                # GetIt DI — registers all services
│   │   ├── router/app_router.dart           # GoRouter route definitions
│   │   └── theme/app_theme.dart             # Dark theme tokens
│   │
│   ├── features/
│   │   ├── home/home_screen.dart
│   │   ├── training/training_screen.dart    # Live CPR coaching screen
│   │   ├── results/results_screen.dart      # Post-session metrics
│   │   ├── history/history_screen.dart
│   │   ├── demo/demo_screen.dart
│   │   ├── settings/settings_screen.dart    # Language, export, researcher link
│   │   ├── splash/splash_screen.dart
│   │   └── research/
│   │       ├── consent_screen.dart          # Participant enrolment + consent
│   │       ├── survey_screen.dart           # Self-efficacy / SUS / NASA-TLX
│   │       └── researcher_dashboard.dart    # PIN-gated researcher view + export
│   │
│   ├── models/
│   │   ├── research_models.dart             # UserProfile, ResearchSession, surveys
│   │   ├── session_model.dart
│   │   └── landmark_frame.dart
│   │
│   ├── services/
│   │   ├── research_logger.dart             # Mobile: SQLite research logger
│   │   ├── research_logger_web.dart         # Web: SharedPrefs + browser download
│   │   ├── research_logger_adapter.dart     # Unified facade — use this in UI code
│   │   ├── feedback_engine.dart             # Priority-queue corrective prompts
│   │   ├── inference_service.dart           # TFLite BiLSTM (mobile)
│   │   ├── session_logger.dart              # General session storage (mobile)
│   │   ├── tts_service.dart                 # flutter_tts + Umuganda
│   │   └── platform/
│   │       ├── pose_service_interface.dart
│   │       ├── pose_service_mobile.dart     # google_mlkit_pose_detection
│   │       ├── pose_service_web.dart        # @mediapipe/pose (WASM)
│   │       ├── inference_service_web.dart   # TensorFlow.js
│   │       └── storage_service.dart         # General storage façade
│   │
│   ├── providers/session_provider.dart      # Riverpod live session state
│   └── main.dart
│
├── web/
│   ├── index.html
│   ├── flutter_pose_bridge.js               # JS ↔ Dart MediaPipe bridge
│   ├── flutter_inference_bridge.js          # JS ↔ Dart TF.js bridge
│   └── assets/models/                       # TF.js model weights (git-ignored)
│
├── assets/
│   ├── models/                              # TFLite model (git-ignored, see below)
│   ├── animations/                          # Rive CPR instructor
│   └── audio/en/ audio/rw/                 # Fallback audio clips
│
├── ml_pipeline/
│   ├── CPR_Coach_Training.ipynb             # BiLSTM training on CPR-Coach dataset
│   └── requirements.txt
│
├── test/
│   └── unit/
│       ├── feedback_engine_test.dart
│       └── landmark_math_test.dart
│
├── pubspec.yaml
└── vercel.json                              # Web deployment config
```

---

## Research Layer — How It Works

### Participant flow (researcher operates the device)

```
Settings → Participant Enrolment
  └─ ConsentScreen        (3 steps: info sheet → form → confirmation)
       └─ SurveyScreen    (pre-session: self-efficacy only)
            └─ Training   (Group A: AI guidance ON / Group B: guidance OFF)
                 └─ SurveyScreen  (post-session: self-efficacy + SUS + NASA-TLX)

Settings → Researcher Dashboard (PIN required)
  └─ Live metrics A vs B
  └─ Export CSV  →  novice_pilot_YYYY-MM-DD.csv
  └─ Export JSON →  novice_research_YYYY-MM-DD.json
```

### What is recorded — what is NOT

| Recorded (anonymised metrics)        | NOT recorded                   |
|--------------------------------------|--------------------------------|
| Joint angles per frame               | Video footage (never stored)   |
| Compression rate (bpm)               | Participant name               |
| Wrist depth proxy                    | Face / biometric data          |
| Error class + confidence score       | Location data                  |
| Feedback events (prompt + timestamp) | Audio                          |
| SUS / NASA-TLX / self-efficacy scores| Any PII                        |

This complies with §3.12.3 of the capstone proposal:
> *"Camera footage … will be deleted within 48 hours of landmark extraction;
> only the anonymised landmark sequences and aggregate performance metrics
> will be retained for analysis."*
>
> **In this implementation no video is stored at all** — only extracted numeric
> metrics are persisted.

### CSV export columns (§3.11.1 analysis plan)

`participant_id · study_group · age_range · prior_cpr_training · language · session_id · start_time · end_time · duration_sec · model_active · total_compressions · mean_bpm · bpm_std_dev · mean_depth_cm · hand_placement_accuracy_pct · elbow_compliance_pct · time_to_first_compression_sec · cpr_fraction · quality_score · sus_score · nasa_tlx_score · self_efficacy_pre · self_efficacy_post · self_efficacy_delta · device_model · os_version · consent_given · enrolled_at`

---

## Researcher Dashboard PIN

The dashboard is PIN-gated to prevent participants from accessing research data.

Default PIN: **`2026`**

**Change before deployment** — set at build time:

```bash
# Web
flutter build web --dart-define=RESEARCHER_PIN=YOUR_PIN

# Android
flutter build apk --dart-define=RESEARCHER_PIN=YOUR_PIN
```

Do **not** commit your PIN to a public repository.

---

## Optional Cloud Sync

To receive participant data in real time (e.g. via a Google Apps Script webhook),
set `RESEARCH_WEBHOOK_URL` at build time. Only anonymised JSON metrics are POSTed —
no video, no PII.

```bash
flutter build web \
  --dart-define=RESEARCHER_PIN=YOUR_PIN \
  --dart-define=RESEARCH_WEBHOOK_URL=https://script.google.com/macros/s/YOUR_ID/exec
```

---

## Getting Started

### Prerequisites

- Flutter 3.x / Dart 3.x
- Chrome (web), or Android / iOS device for native

### Run (web)

```bash
flutter pub get
flutter run -d chrome
```

### Build for web deployment (Vercel / GitHub Pages)

```bash
flutter build web --release \
  --dart-define=RESEARCHER_PIN=YOUR_PIN
# output in build/web/
```

### ML model

The TFLite / TF.js BiLSTM model is **not** committed to the repository (file size).
See `assets/models/README.md` and `ml_pipeline/CPR_Coach_Training.ipynb` for
training instructions. Place the exported model at:

- Mobile: `assets/models/novice_cpr_classifier.tflite`
- Web:    `web/assets/models/novice_cpr_classifier/` (TF.js SavedModel format)

The app runs in **demo / rule-based mode** if no model file is found.

---

## Privacy & Ethics

- Ethical clearance: ALU Research Ethics Committee (ALU REC)
- Declaration of Helsinki compliant
- No video recorded or transmitted at any point
- All participant records linked to anonymous IDs only (e.g. P001)
- Data retained for 3 months post-graduation, then securely deleted
- See `lib/features/research/consent_screen.dart` for the full
  in-app participant information sheet

---

## Citation

If you build on this work, please cite:

> Gatwaza, J. R. (2026). *Development and Evaluation of a Machine Learning
> First Aid Simulation Training Tool in Sub-Saharan Africa* (Capstone project).
> African Leadership University.

CPR-Coach dataset:
> Wang et al. (2023). CPR-Coach: Recognizing composite error actions based on
> single-class training. arXiv:2309.11718.

---

*Novice is free software distributed under the GNU GPL v3.*
*Source code: github.com/Gatwaza/Capstone-Project*
