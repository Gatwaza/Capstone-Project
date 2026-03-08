# Capstone Project — Setup Guide
> CPR AI Coach · Android + iOS + Web · Flutter + Vanilla JS + Google Colab

---

## Prerequisites Checklist

| Tool | Required For | Install |
|---|---|---|
| Flutter SDK | Android + iOS app | See §1 |
| Android Studio OR VS Code + Android SDK | Android testing | See §2 |
| Xcode (macOS only) | iOS testing | App Store |
| Node.js ≥ 18 | Web app | https://nodejs.org |
| Python 3.10+ | ML pipeline (local) | https://python.org |
| Google Chrome | Web testing | https://chrome.google.com |
| Git + Git LFS | All | https://git-scm.com |
| VS Code | All development | https://code.visualstudio.com |

---

## §1 — Install Flutter

### Windows
```powershell
# Option A: via Chocolatey (recommended)
choco install flutter

# Option B: manual
# 1. Download flutter_windows_stable.zip from https://flutter.dev/docs/get-started/install/windows
# 2. Extract to C:\src\flutter
# 3. Add C:\src\flutter\bin to your PATH
```

### macOS
```bash
# Option A: via Homebrew (recommended)
brew install --cask flutter

# Option B: manual
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_stable.tar.xz
tar xf flutter_macos_arm64_stable.tar.xz
export PATH="$PWD/flutter/bin:$PATH"
```

### Linux
```bash
sudo snap install flutter --classic
# OR
sudo apt-get install -y flutter
```

### Verify Flutter
```bash
flutter doctor
# All checks should pass (or show only Chrome/VS Code as optional)
# Android Studio license acceptance:
flutter doctor --android-licenses
```

---

## §2 — VS Code Extensions (install all)

Open VS Code and install:
- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **REST Client** (humao.rest-client)
- **GitLens** (eamodio.gitlens)

Or install all at once:
```bash
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
code --install-extension humao.rest-client
code --install-extension eamodio.gitlens
```

---

## §3 — Clone & Setup Project

```bash
git clone git@github.com:Gatwaza/Capstone-Project.git capstone_project
cd capstone_project

# Install Git LFS (for model files)
git lfs install
git lfs pull

# Copy env template
cp .env.example .env
# Edit .env — fill in your Google OAuth client IDs (see §6)

# Install Flutter dependencies
flutter pub get

# Install Web dependencies
cd web && npm install && cd ..
```

Open VS Code workspace:
```bash
code capstone_project.code-workspace
```

---

## §4 — Run the Flutter App

### Android (physical device or emulator)
```bash
# List available devices
flutter devices

# Run (replace <device-id> with output from above)
flutter run -d <device-id>

# Or just — Flutter will prompt you to choose
flutter run
```

> **First time on Android?**
> Enable Developer Options on your phone:
> Settings → About Phone → tap Build Number 7 times → back → Developer Options → enable USB Debugging

### iOS (macOS only)
```bash
cd ios && pod install && cd ..
flutter run -d <your-iphone-id>
```

### Web (Chrome)
```bash
flutter run -d chrome
# OR use the standalone web app (no Flutter needed):
cd web && npm run dev
# → http://localhost:5173
```

---

## §5 — Run the Web App Standalone (no Flutter required)

The `web/` directory is a fully independent Vite app. Useful for testing the complete experience before Flutter is set up.

```bash
cd web
npm install
npm run dev
# → http://localhost:5173 — open in Chrome

# Production build
npm run build
# → web/dist/ — deploy to Netlify, Vercel, or GitHub Pages
```

**First load:** downloads MediaPipe WASM (~8MB) and TensorFlow.js. Requires internet once.
**After first load:** works offline (service worker caches assets).

---

## §6 — Google Drive Session Export Setup

Session data (JSON export) can be uploaded to your Google Drive.

### Get OAuth Client ID
1. Go to https://console.cloud.google.com
2. Create a new project → "CPR-Coach Capstone"
3. APIs & Services → Enable: **Google Drive API**
4. APIs & Services → Credentials → Create OAuth 2.0 Client ID
   - Application type: **Web application** (for web)
   - Application type: **Android** (for Flutter Android) — add your SHA-1
   - Application type: **iOS** (for Flutter iOS)
5. Download the client config files
6. Fill in `.env`:
```env
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your-android-client-id.apps.googleusercontent.com
```

> **For capstone testing without Drive:** sessions are saved locally to SQLite
> (Android/iOS) or IndexedDB (web) automatically. Drive upload is optional.

---

## §7 — ML Pipeline (Google Colab)

### Setup

1. Upload `ml_pipeline/CPR_Coach_Training.ipynb` to Google Colab
   - Go to https://colab.research.google.com
   - File → Upload Notebook → select the `.ipynb` file

2. Upload your CPR-Coach sample data:
   - Create a folder in your Google Drive: `My Drive/capstone_data/cpr_coach/`
   - Upload the sample dataset files there

3. Run all cells (Runtime → Run all)

4. The notebook will:
   - Mount your Drive automatically
   - Detect whether sample or full dataset is present
   - Fall back to **synthetic dummy data** if no dataset found (still validates the pipeline)
   - Train the BiLSTM model
   - Export `cpr_classifier.tflite` + TFJS files
   - Save them to `My Drive/capstone_data/exports/`

5. Download the exported model and place in:
   - `assets/models/cpr_classifier.tflite` (Flutter)
   - `web/assets/models/model.json` + `.bin` shards (Web)

---

## §8 — Project Structure at a Glance

```
capstone_project/
├── lib/                    ← Flutter app (Android + iOS)
├── web/                    ← Standalone web app
├── ml_pipeline/            ← Python training (run in Colab)
├── assets/                 ← Flutter shared assets
├── SETUP.md                ← This file
├── capstone_project.code-workspace
├── pubspec.yaml
└── .env.example
```

---

## §9 — Troubleshooting

| Problem | Fix |
|---|---|
| `flutter doctor` shows Android SDK missing | Install Android Studio, then re-run `flutter doctor` |
| `CocoaPods not installed` (macOS) | `sudo gem install cocoapods` |
| Camera permission denied (Android) | Check `AndroidManifest.xml` has `<uses-permission android:name="android.permission.CAMERA"/>` |
| TFLite model not found | App runs in rule-based mode — this is expected until model is trained |
| Web: MediaPipe fails to load | Ensure you're on Chrome 90+ and have internet for first load |
| `flutter pub get` fails | Run `flutter clean` then `flutter pub get` |
| Pose not detected | Ensure you are well-lit and your upper body is fully in frame |

---

## §10 — Quick Test Checklist

- [ ] `flutter run -d chrome` launches the home screen
- [ ] "Start Training" opens camera and requests permission
- [ ] Skeleton overlay appears when upper body is detected
- [ ] Voice feedback fires within ~5 seconds of starting
- [ ] Session ends after 2 minutes and results appear
- [ ] Results screen shows BPM, accuracy, session duration
- [ ] Web app at `http://localhost:5173` loads and runs identically
- [ ] Colab notebook runs end-to-end (even with dummy data)
