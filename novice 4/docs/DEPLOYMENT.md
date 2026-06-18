# Novice — Deployment Guide

**GNU GPL v3 · Jean Robert Gatwaza / African Leadership University**

---

## Production Deployment (Vercel)

### Build config (`vercel.json`)

```json
{
  "buildCommand": "/tmp/flutter/bin/flutter build web --release --dart-define=RESEARCHER_PIN=2026",
  "outputDirectory": "build/web",
  "installCommand": "git clone https://github.com/flutter/flutter.git --depth 1 -b 3.29.3 /tmp/flutter && /tmp/flutter/bin/flutter --version && /tmp/flutter/bin/flutter pub get",
  "framework": null,
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

### Why `--web-renderer html` is NOT included

The `--web-renderer` CLI flag was removed in **Flutter 3.22**. Including it causes:

```
Could not find an option named "--web-renderer".
Error: Command exited with 64
```

This was the root cause of the Vercel 404 (`NOT_FOUND`) production build failure. The flag has been removed from `vercel.json`. Flutter 3.29.3 uses the CanvasKit renderer by default for web builds, which is appropriate for this application.

### Why Flutter is run as non-root

Vercel's build environment runs as root. Flutter prints a warning (`Woah! You appear to be trying to run flutter as root`) but this does not block the build. The `git clone` install approach bypasses the need for `sudo`.

### Why dependencies changed

The build log shows `Changed 138 dependencies` and `69 packages have newer versions incompatible with dependency constraints`. This is expected on a cold Vercel build — it resolves from `pubspec.lock`. The incompatibility warning is informational only; `pubspec.lock` pins all versions.

---

## Environment Variables

| Variable | Where set | Default |
|---|---|---|
| `RESEARCHER_PIN` | `--dart-define` in build command | `2026` |
| `CPR_API_URL` | `--dart-define` or Vercel env | `https://jeanrobert-novice.hf.space` |

To override the API URL:
```bash
flutter build web --release \
  --dart-define=RESEARCHER_PIN=2026 \
  --dart-define=CPR_API_URL=https://your-api.hf.space
```

---

## CORS / Security Headers

The `vercel.json` sets the following headers on all routes to enable SharedArrayBuffer (required for MediaPipe WASM):

```
Cross-Origin-Opener-Policy:   same-origin
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Resource-Policy: cross-origin
```

These are required for `@mediapipe/pose` WASM to run in-browser. Without them the pose bridge will fail silently.

---

## Hugging Face Spaces API

The CNN-BiLSTM inference API is hosted on Hugging Face Spaces:

- **Base URL:** `https://jeanrobert-novice.hf.space`
- **Health check:** `GET /health` → `200 OK`
- **Predict:** `POST /predict` with `{ "sequence": [[...12 floats × 60 frames...]] }`

`InferenceServiceWeb` calls `checkHealth()` at app startup (15 s timeout). If the API is unreachable, the app falls back to rule-based threshold classification and the results screen shows `Rule-based` in the AI MODEL tile.

---

## Local Build

```bash
# Debug (hot reload)
flutter run -d chrome --dart-define=RESEARCHER_PIN=2026

# Release (matches Vercel output)
flutter build web --release --dart-define=RESEARCHER_PIN=2026
cd build/web && python3 -m http.server 8080
# Open http://localhost:8080
```

---

## Static Hosting Alternatives

If deploying outside Vercel, ensure:
1. All routes rewrite to `index.html` (SPA mode)
2. COOP / COEP headers are set (for WASM)
3. `flutter_service_worker.js` is served with `Cache-Control: no-cache`
4. Assets under `/assets/` use long-lived cache headers

---

## Git LFS

Large binary assets are tracked with Git LFS:

```bash
git lfs install
git lfs track "assets/models/*.tflite"
git lfs track "web/assets/models/*.bin"
git lfs track "assets/animations/*.riv"
git add .gitattributes
git commit -m "chore: configure git-lfs for model assets"
```

Vercel automatically resolves LFS pointers during the build if the repository is connected via the Vercel GitHub integration.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Vercel 404 NOT_FOUND + exit 64 | `--web-renderer html` flag not supported in Flutter 3.22+ | Remove flag from `vercel.json` `buildCommand` |
| MediaPipe crash (`roi->width > 0`) | Pose bridge polled before `<video>` has valid dimensions | Wait for `window._novicePoseReady = true` before starting pose loop |
| AI MODEL shows "Rule-based" | API health check failed at startup | Verify Hugging Face Space is running; check `CPR_API_URL` env var |
| Depth always ~10 cm | `normToPhysicalCmScale` too high | Constant reduced to 20.0 in `app_constants.dart` |
| WASM blocked by CORP/COEP | Missing security headers | Add COOP/COEP headers to your host config |
| `flutter pub get` fails on Vercel | Dart SDK mismatch | Ensure pinned Flutter version in `installCommand` matches `pubspec.yaml` SDK constraint |

---

*GNU GPL v3 · ALU Capstone 2024 · Jean Robert Gatwaza*
