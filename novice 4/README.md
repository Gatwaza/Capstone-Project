# Novice — First Aid AI Coach

> Real-time CPR coaching powered by pose estimation and a hosted AI model, paired with an interactive first aid procedure library built for Sub-Saharan Africa.

[![Flutter](https://img.shields.io/badge/Flutter-3.29.3-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.2-0175C2?logo=dart)](https://dart.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Web-blue)](https://flutter.dev/web)
[![Deployed on Vercel](https://img.shields.io/badge/Deployed-Vercel-black?logo=vercel)](https://vercel.com)

---

## What Novice does

Novice is a web app that teaches you how to perform CPR and other first aid procedures — no prior training required, no extra hardware, just a smartphone or laptop with a camera.

| Mode | Procedures | What happens |
|------|------------|--------------|
| **Live AI Training** | CPR | Your camera captures your movements. An AI model assesses your compression rate, depth, and chest recoil in real time and speaks corrections aloud as you train. |
| **Guided Demo** | Choking · Stroke (FAST) · Recovery Position · AED | Step-by-step animated guides with no camera required. |

All procedure content is sourced from the **Rwanda Basic First Aid Training Manual** (Emergency Safety and Health Services / Belgian Red Cross, Flanders).

---

## Try it

Open the app in Chrome (camera required for CPR training):

> **[novice.vercel.app](https://novice.vercel.app)** ← live deployment

**Browser requirements:** Chrome 90+ recommended. Camera permission required for the CPR module. All other modules work without a camera.

---

## Run it locally

### What you need

| Tool | Version | Get it |
|------|---------|--------|
| Flutter | **3.29.3** (exact — matches deployment pin) | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| Chrome | 90+ | [google.com/chrome](https://google.com/chrome) |
| Git | any | bundled with most systems |

### Steps

```bash
# 1. Clone
git clone https://github.com/Gatwaza/novice.git
cd novice

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate model bindings (required once after cloning)
dart run build_runner build --delete-conflicting-outputs

# 4. Run in Chrome
flutter run -d chrome
```

The app will open in Chrome. The CPR training module will ask for camera permission — allow it and position yourself so your upper body is visible.

> **Without Supabase configured**, participant registration and session upload are disabled, but the CPR training, AI coaching, and all animated guides work fully offline.

### Optional: connect Supabase (for session storage)

If you have a Supabase project, add the following inside the `<head>` of `web/index.html` before any `<script>` tags:

```html
<script>
window.__NOVICE_CONFIG__ = {
  supabaseUrl:     "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_ANON_KEY"
};
</script>
```

**Is the anon key safe to share?** Yes. The Supabase anon key is a public key by design — it is safe to commit to a public repository. Access to your data is controlled by Row Level Security (RLS) policies on each table, not the key itself. Never share your **service role key** (the secret key) — that one bypasses RLS.

---

## Project structure

```
novice/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart       # CPR thresholds, AI params, voice prompts (EN + RW)
│   │   │   └── env.dart                 # Runtime config reader
│   │   ├── router/app_router.dart       # Navigation (12 routes)
│   │   ├── theme/app_theme.dart         # Visual design system
│   │   └── utils/landmark_math.dart     # Pose geometry and feature extraction
│   ├── models/
│   │   ├── landmark_frame.dart          # Single-frame pose data
│   │   └── session_model.dart           # Completed session with CPR metrics
│   ├── providers/
│   │   └── session_provider.dart        # Live session state (Riverpod)
│   ├── services/
│   │   ├── feedback_engine.dart         # When to speak a correction (4 s cooldown)
│   │   ├── tts_service.dart             # Voice coaching — English + Kinyarwanda
│   │   └── platform/
│   │       ├── cpr_api_service.dart     # AI model HTTP client
│   │       ├── inference_service_web.dart # Frame buffering + API throttle
│   │       ├── pose_service_web.dart    # Camera → pose landmarks (MediaPipe)
│   │       ├── storage_service.dart     # Session save/load
│   │       └── telemetry_service.dart   # Optional cloud session upload
│   └── features/
│       ├── splash/                      # Boot screen
│       ├── home/                        # Session history dashboard
│       ├── demo/                        # Procedures hub + animated guides
│       ├── training/                    # Live CPR training screen (camera HUD)
│       ├── results/                     # Post-session metrics
│       ├── history/                     # Full session list
│       └── settings/                   # Language toggle (English / Kinyarwanda)
├── web/index.html                       # App shell + AI bridge + config
├── scripts/vercel_build.sh             # Production build pipeline
├── docs/                               # Technical documentation
├── pubspec.yaml
└── vercel.json                         # Deployment configuration
```

---

## How the AI coaching works

```
Camera (25 fps)
    │
    ▼
MediaPipe Pose  →  33 body landmarks per frame
    │
    ▼
Feature extraction  →  12 values per frame
    │                   (elbow angles, spine lean, wrist position,
    │                    compression velocity, depth estimate…)
    │
    ▼
60-frame buffer  →  POST to AI model (every 600 ms)
    │                https://jeanrobert-novice.hf.space/predict
    │
    ▼
TCN model  →  three simultaneous assessments:
    │           Rate:   Correct / Too Fast / Too Slow
    │           Depth:  Correct / Too Shallow / Too Deep
    │           Recoil: Complete / Incomplete
    │
    ▼
Voice coach  →  speaks the highest-priority correction
                (silent when technique is correct)
```

The AI model (TCN — Temporal Convolutional Network) was trained on the CPR-Coach dataset (Wang et al., 2023) and hosted on Hugging Face Spaces. If the API is unreachable, the app falls back to rule-based threshold coaching automatically.

---

## CPR targets the AI coaches toward

Source: **ERC Guidelines 2021** (Perkins et al., DOI: 10.1016/j.resuscitation.2021.02.009)

| What | Target |
|------|--------|
| Compression rate | 100–120 per minute |
| Compression depth | 5.0–6.0 cm |
| Elbow posture | Arms straight (≥ 160°) |
| Body position | Shoulders directly above hands |
| Chest recoil | Full release between compressions |

---

## Voice coaching languages

The app coaches in **English** (default) and **Kinyarwanda**. Switch languages in Settings at any time during a session. All 13 coaching prompts are available in both languages.

---

## Quality score

After each session, Novice gives you a quality score (0–100) based on how accurately the AI assessed your rate, depth, and recoil across the session. Higher means your technique was more consistently correct on all three dimensions simultaneously.

---

## Build for production

```bash
# Matches the Vercel deployment exactly
flutter build web --release --no-tree-shake-icons
cd build/web && python3 -m http.server 8080
# Open http://localhost:8080
```

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for the full Vercel setup guide including environment variables and CORS headers required for the AI bridge.

---

## Run the tests

```bash
flutter test
```

---

## Procedure library

| Procedure | Mode | Content source |
|-----------|------|---------------|
| CPR | Live AI coaching | Rwanda Manual — Module 5 |
| Choking | Animated demo | Rwanda Manual — Module 6 |
| Stroke — FAST | Animated demo | Rwanda Manual — Module 9 |
| Recovery Position | Animated demo | Rwanda Manual — Module 3/4 |
| AED | Animated demo | Rwanda Manual — Module 11 |

---

## License

**GNU General Public License v3.0** — Jean Robert Gatwaza, African Leadership University 2024–2025. See [LICENSE](LICENSE).

---

## Technical documentation

For architecture, API reference, and deployment details see the [`docs/`](docs/) directory.