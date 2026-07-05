# Novice — Setup & Deployment Guide
**GNU GPL v3 — Jean Robert Gatwaza / African Leadership University**

This guide covers everything a third party needs to run Novice locally and deploy
their own copy. Novice is a **Flutter Web** app — there is currently no mobile
build (see `pubspec.yaml`).

The system has three independently hosted parts:

| Part | What it is | Where it lives |
|---|---|---|
| **Frontend** | Flutter Web app (this repo) | Deployed on Vercel |
| **Inference API** | Hosted TCN model serving `/predict` and `/health` | Hugging Face Spaces |
| **Data store** | Session storage, consent records, researcher dashboard | Supabase (Postgres) |

You can run the frontend against the **already-deployed** inference API
(`https://jeanrobert-novice.hf.space`) with zero backend setup — this is the
fastest path to testing the app end-to-end. Standing up your own copy of the
inference API requires the separate model-serving repo (not included here);
see [Inference API](#4-inference-api-hugging-face-spaces) below.

---

## Prerequisites

```bash
flutter --version   # 3.29.3 exact (matches the deployment pin)
dart --version       # bundled with Flutter — 3.7.2
git --version
python3 --version    # >= 3.9, only needed for local build scripts
```

Get Flutter from [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install).
Chrome 90+ is required to run/test the app (camera access for the CPR module).

---

## 1. Clone

```bash
git clone https://github.com/Gatwaza/novice.git
cd novice
```

---

## 2. Install dependencies

```bash
flutter pub get
```

`freezed`/`json_serializable` generated files (`*.g.dart`) are committed to
this repo, so `build_runner` is **not required** to run the app. If you modify
any `@freezed` or `@JsonSerializable` model, regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 3. Run locally

### Quickest path — use the live inference API and skip Supabase

```bash
flutter run -d chrome
```

The app runs fully: CPR training, live AI coaching (against the existing
hosted model), and all animated first aid guides. Only participant
registration and cloud session upload are disabled, since those require
Supabase.

### With Supabase (session storage, research dashboard)

Add your own Supabase project's `web/index.html` config inside the `<head>`,
before any `<script>` tags:

```html
<script>
window.__NOVICE_CONFIG__ = {
  supabaseUrl:     "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_ANON_KEY",
  researcherPin:   "Any integer value"
};
</script>
```

Then run `flutter run -d chrome` as above. See [Supabase](#3a-supabase-setup)
below for schema setup.

### 3a. Supabase setup

1. Create a free project at [supabase.com](https://supabase.com).
2. Apply the schema migration in `scripts/migrate_schema_version.py` (or the
   SQL it wraps) to create the sessions/consent/participant tables.
3. Copy your project's **URL** and **anon/public key** from
   Project Settings → API — these are safe to expose client-side (the anon
   key is scoped by Supabase Row Level Security, not a secret credential).
4. Use them in the config block above (local) or as Vercel environment
   variables (production — see below).

---

## 4. Inference API (Hugging Face Spaces)

The AI model — a Temporal Convolutional Network (TCN) trained on the
[CPR Coach Dataset](https://drive.google.com/drive/folders/1zJoJYrmvIv9TgNd5ZmVYVq7odkB5wI5e?usp=sharing)
(Wang et al., 2023) — is served from a Hugging Face Space and called over
HTTP from `lib/services/platform/cpr_api_service.dart`.

- **Default endpoint (already live, no setup needed):**
  `https://jeanrobert-novice.hf.space`
- **Point the app at a different endpoint** without editing code:
  ```bash
  flutter run -d chrome --dart-define=CPR_API_URL=https://your-space.hf.space
  ```
- **Model training pipeline:** `ml_pipeline/CPR_Coach_Training_(3) (1).ipynb`
  documents feature extraction, training, and evaluation for the TCN model
  (see `ml_pipeline/requirements.txt` for the Python environment). The
  Flask/FastAPI serving app that wraps the trained model into `/predict` and
  `/health` endpoints lives in a separate Hugging Face Space repository —
  reach out to the maintainer for access if you need to redeploy the backend
  independently rather than using the shared endpoint above.
- If the inference API is unreachable, the app automatically falls back to
  rule-based threshold coaching so training is never blocked.

---

## 5. Deploy your own copy (Vercel)

This repo's `vercel.json` and `scripts/vercel_build.sh` already define the
full build pipeline (cloning Flutter 3.29.3, building web release, and
injecting Supabase config).

1. Import the repo into [vercel.com](https://vercel.com) as a new project.
2. Leave **Framework Preset** as "Other" — `vercel.json` already sets
   `installCommand`, `buildCommand`, and `outputDirectory`.
3. Add these under **Settings → Environment Variables**:

   | Variable | Value |
   |---|---|
   | `SUPABASE_URL` | Your Supabase project URL |
   | `SUPABASE_ANON_KEY` | Your Supabase anon/public key |

4. Deploy. `scripts/vercel_build.sh` fails the build early with a clear error
   if either variable is missing, so a misconfigured deploy is obvious rather
   than silently shipping a broken build.
5. The CPR inference endpoint does **not** need a Vercel env var — it's
   compiled in as a default (`https://jeanrobert-novice.hf.space`) and can be
   overridden per-build with `--dart-define=CPR_API_URL=...` if you fork the
   build script.

---

## 6. Run the tests

```bash
flutter test                                  # all tests
flutter test test/unit/landmark_math_test.dart
flutter test test/unit/feedback_engine_test.dart
```

---

## 7. Production build (manual, without Vercel)

```bash
flutter build web --release --no-tree-shake-icons
cd build/web && python3 -m http.server 8080
# open http://localhost:8080
```

Without injected config, Supabase-backed features are disabled but CPR
training and coaching work fully. To inject config locally, use
`run_local.sh` (reads `SUPABASE_URL`/`SUPABASE_ANON_KEY` from `~/.novice_env`).

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `flutter pub get` fails | `dart pub cache clean`, then retry |
| "Model: Unavailable" in the training screen | The Hugging Face Space may be asleep (free-tier Spaces sleep after inactivity) — the app falls back to rule-based coaching automatically; reload after ~30s to let it wake up |
| Camera permission denied | Check the browser's site settings — camera access must be explicitly allowed for the CPR module |
| Participant registration disabled | `window.__NOVICE_CONFIG__` isn't set — see [Supabase setup](#3a-supabase-setup) |
| Vercel build fails immediately | Check that `SUPABASE_URL` / `SUPABASE_ANON_KEY` are set in Vercel → Settings → Environment Variables |
| `build_runner` conflict | Re-run with `--delete-conflicting-outputs` |

---

## Medical Disclaimer

Novice is a training simulation tool. It does not replace formal CPR
certification or professional medical advice. Always call emergency services
first.

---

*GNU GPL v3 · ALU Capstone 2024–2025 · Jean Robert Gatwaza*
