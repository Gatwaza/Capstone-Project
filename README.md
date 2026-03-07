# Capstone-Project
This repository contains the code and documentation for the Capstone Project. The project focuses on proposal for

# Problem Statement

# Project Structure
cpr-ai-tool/
│
├── mobile_app/                        # Flutter cross-platform app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── training_screen.dart   # Live camera + feedback UI
│   │   │   ├── demo_screen.dart       # Animated instructor demo
│   │   │   └── results_screen.dart    # Post-session metrics
│   │   ├── services/
│   │   │   ├── pose_service.dart      # MediaPipe landmark extraction
│   │   │   ├── inference_service.dart # TFLite model runner
│   │   │   ├── feedback_engine.dart   # Rule-based + ML feedback logic
│   │   │   ├── tts_service.dart       # Voice prompt manager
│   │   │   └── session_logger.dart    # Metrics recording
│   │   ├── models/
│   │   │   └── session_model.dart
│   │   └── assets/
│   │       ├── models/cpr_classifier.tflite
│   │       ├── audio/                 # Pre-recorded voice prompts
│   │       └── animations/           # Lottie/rive animated instructor
│   └── pubspec.yaml
│
├── ml_pipeline/                       # Python ML research environment
│   ├── data/
│   │   ├── raw/                       # Raw collected video footage
│   │   ├── annotated/                 # LabelStudio exports
│   │   └── processed/                 # Extracted landmark sequences
│   ├── notebooks/
│   │   ├── 01_eda.ipynb              # Exploratory data analysis
│   │   ├── 02_landmark_extraction.ipynb
│   │   ├── 03_model_training.ipynb
│   │   └── 04_evaluation.ipynb
│   ├── src/
│   │   ├── data_collection/
│   │   │   ├── extract_landmarks.py   # MediaPipe batch processing
│   │   │   └── augment_data.py
│   │   ├── models/
│   │   │   ├── cnn_classifier.py      # Posture classification CNN
│   │   │   ├── lstm_temporal.py       # Compression rhythm LSTM
│   │   │   └── hybrid_model.py        # Combined architecture
│   │   ├── training/
│   │   │   ├── train.py
│   │   │   └── evaluate.py
│   │   └── export/
│   │       └── convert_to_tflite.py   # Model quantization + export
│   ├── requirements.txt
│   └── config.yaml                    # Hyperparameters, paths
│
├── evaluation/                        # Research evaluation tools
│   ├── pilot_study_protocol.md
│   ├── nasa_tlx_form.pdf
│   ├── data_collection_sheet.xlsx
│   └── analysis/
│       ├── statistical_analysis.py
│       └── visualizations.ipynb
│
└── docs/
    ├── architecture_diagram.png
    ├── api_specs.md
    └── user_guide.md


