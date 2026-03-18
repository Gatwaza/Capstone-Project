# Novice — Setup Guide
**GNU GPL v3 — Jean Robert Gatwaza / African Leadership University**

Complete reproducible setup for macOS M1 Max + iPhone 15 Pro testing.

---

## Prerequisites

```bash
# Verify you have these installed
flutter --version    # >= 3.10.0  (get from flutter.dev)
dart --version       # >= 3.0.0   (bundled with Flutter)
xcode-select --print-path   # must return a path (install Xcode from App Store)
python3 --version    # >= 3.11    (get from python.org or brew)
node --version       # >= 18.0    (get from nodejs.org)
git lfs version      # (brew install git-lfs if missing)
```

---

## 1. Clone & clean the repository

```bash
git clone git@github.com:Gatwaza/Capstone-Project.git
cd Capstone-Project

# Run the cleanup script to remove ghost folders and root duplicates
chmod +x scripts/clean_repo.sh
./scripts/clean_repo.sh
git commit -m "chore: clean repo structure"
```

---

## 2. Flutter app (Mobile — iPhone 15 Pro)

```bash
# Install dependencies
flutter pub get

# Run code generators (Freezed models, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Open in Xcode and set your Team/Bundle ID
open ios/Runner.xcworkspace
# In Xcode: Signing & Capabilities → set your Apple Developer Team

# Connect iPhone 15 Pro via USB
# Trust the device when prompted on iPhone

# Run on device
flutter run --release         # release for performance testing
flutter run                   # debug for development

# Build IPA for distribution
flutter build ipa --release
```

### Xcode signing (one-time)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` target → Signing & Capabilities
3. Set Team to your Apple Developer account
4. Change Bundle Identifier to `com.yourname.novice`
5. Click "Register Device" when prompted

### Camera entitlement (verify)
The `ios/Runner/Info.plist` already contains `NSCameraUsageDescription`.
No additional entitlements needed for camera on iOS 17 (iPhone 15 Pro).

---

## 3. Web app (Browser demo)

```bash
cd web
npm install
npm run dev
# → http://localhost:3000

# Production build (deploy to GitHub Pages / Netlify)
npm run build
# Output: web/dist/
```

**Browser requirements:**
- Chrome 90+ (recommended), Firefox 95+, Safari 15.4+
- Camera permission required
- WebGL for TensorFlow.js acceleration (enabled by default)

---

## 4. ML Pipeline (Python — M1 Max + Metal GPU)

```bash
cd ml_pipeline

# Create isolated virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies (M1 native TensorFlow + Metal GPU)
pip install --upgrade pip
pip install -r requirements.txt

# Verify Metal GPU acceleration
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
# Should show: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

### Load your Sample_Dataset from Google Drive

```bash
# Option A: Connect Google Drive connector in Claude, then:
# Claude will access Sample_Dataset directly via the connector.

# Option B: Manual download
# 1. Open Google Drive → Sample_Dataset
# 2. Download as ZIP and unzip to ml_pipeline/data/raw/Sample_Dataset/
# Expected structure:
#   data/raw/Sample_Dataset/
#     correct_compression/  ← video files (.mp4)
#     bent_elbows/
#     hand_too_high/
#     ... (one folder per class)

# Verify
ls ml_pipeline/data/raw/Sample_Dataset/
```

### Run the full ML pipeline

```bash
cd ml_pipeline

# Step 1: Extract MediaPipe landmarks from all videos (~5–20 min on M1 Max)
python src/data/extract_landmarks.py --config config.yaml

# Step 2: Train BiLSTM model (~20–60 min with Metal GPU)
python src/training/train.py --config config.yaml

# Step 3: Evaluate against research targets
python src/training/evaluate.py --config config.yaml

# Step 4: Export for mobile (TFLite INT8)
python src/export/convert_to_tflite.py --config config.yaml
# → places model at: assets/models/novice_cpr_classifier.tflite

# Step 5: Export for web (TensorFlow.js)
python src/export/convert_to_tfjs.py --config config.yaml
# → places model at: web/assets/models/model.json + shards

# Step 6: Re-run Flutter with real model
cd ..
flutter run
```

---

## 5. Run tests

```bash
# Flutter unit tests
flutter test test/unit/landmark_math_test.dart
flutter test test/unit/feedback_engine_test.dart
flutter test                      # all tests

# Python ML pipeline tests (after setting up venv)
cd ml_pipeline
python -m pytest tests/ -v
```

---

## 6. Git LFS (model files)

Large binary files are tracked with Git LFS:

```bash
git lfs install
git lfs track "assets/models/*.tflite"
git lfs track "web/assets/models/*.bin"
git lfs track "assets/animations/*.riv"
git add .gitattributes
git commit -m "chore: configure git-lfs for model assets"

# After training, add the model
git add assets/models/novice_cpr_classifier.tflite
git commit -m "feat: add trained TFLite model v0.1"
git push
```

---

## 7. Environment variables

```bash
cp .env.example .env
# Edit .env and fill in:
#   UMUGANDA_TTS_URL   — leave empty if not hosting Kinyarwanda TTS locally
#   WANDB_API_KEY      — optional, for experiment tracking
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `flutter pub get` fails | Run `dart pub cache clean` then retry |
| Xcode signing error | Check Apple Developer account → Certificates |
| Camera black on simulator | Use real iPhone — simulator has no camera |
| TFLite model not found | Expected at `assets/models/novice_cpr_classifier.tflite` — app runs in demo mode without it |
| Metal GPU not detected | Run `pip install tensorflow-metal==1.0.1` separately |
| MediaPipe WASM slow in browser | Use Chrome for best WebGL performance |
| `build_runner` conflict | Run with `--delete-conflicting-outputs` flag |

---

## Medical Disclaimer

Novice is a training simulation tool. It does not replace formal CPR certification or professional medical advice. Always call emergency services first.

---

*GNU GPL v3 · ALU Capstone 2024 · Jean Robert Gatwaza*
