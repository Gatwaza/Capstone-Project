# Novice — TCN Inference API Reference

**GNU GPL v3 · Jean Robert Gatwaza / African Leadership University**

---

## Base URL

```
https://jeanrobert-novice.hf.space
```

Hosted on Hugging Face Spaces. The Flutter app configures this via:
```dart
const String.fromEnvironment('CPR_API_URL',
  defaultValue: 'https://jeanrobert-novice.hf.space')
```

---

## Endpoints

### `GET /health`

Startup health check. Called by `CprApiService.checkHealth()` at app launch with a 15 s timeout.

**Response (200 OK):**
```json
{ "status": "ok" }
```

If this fails, `InferenceServiceWeb.isModelLoaded` returns `false` and the app falls back to rule-based threshold classification.

---

### `POST /predict`

Submit a 60-frame landmark sequence for TCN classification.

**Request body:**
```json
{
  "sequence": [
    [f0, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11],
    // ... 60 rows total (one per frame)
  ]
}
```

**Feature vector (12 dimensions per frame):**

| Index | Name | Description |
|---|---|---|
| 0 | `leftElbowAngle` | Left shoulder–elbow–wrist angle (degrees) |
| 1 | `rightElbowAngle` | Right shoulder–elbow–wrist angle (degrees) |
| 2 | `spineVerticality` | Hip–shoulder lean from vertical (degrees) |
| 3 | `wristY` | Normalised mid-wrist Y position |
| 4 | `wristVelocityY` | Δ wristY / second |
| 5 | `wristAccelerationY` | Δ velocity / second |
| 6 | `normalizedDepth` | Wrist displacement / torso height |
| 7 | `shoulderWidth` | Normalised biacromial width |
| 8 | `meanConfidence` | Mean MediaPipe visibility score |
| 9 | `leftElbowVisible` | 0 or 1 |
| 10 | `rightElbowVisible` | 0 or 1 |
| 11 | _(reserved)_ | 0.0 padding |

**Sequence shape:** `(60, 12)` — must be exactly 60 rows.

**Response (200 OK):**
```json
{
  "rate": {
    "label": "Correct",
    "confidence": 0.92
  },
  "depth": {
    "label": "Too_Shallow",
    "confidence": 0.87
  },
  "recoil": {
    "label": "Correct",
    "confidence": 0.81
  }
}
```

**Rate labels:** `Correct` | `Too_Fast` | `Too_Slow`  
**Depth labels:** `Correct` | `Too_Shallow` | `Too_Deep`  
**Recoil labels:** `Correct` | `Incomplete`

**Response (non-200):** Returns `null` from `CprApiService.predict()`; inference falls back to rule-based.

---

## Label Resolution

`ApiPrediction.resolvedLabel` maps the three-head response to the 8-class error label used by `FeedbackEngine`:

| Condition | `resolvedLabel` |
|---|---|
| `rate == Too_Fast` | `rate_too_fast` |
| `rate == Too_Slow` | `rate_too_slow` |
| `depth == Too_Deep` | `too_deep` |
| `depth == Too_Shallow` | `too_shallow` |
| `recoil == Incomplete` | `incomplete_decomp` |
| All Correct | `correct_compression` |

---

## Timeouts

| Call | Timeout |
|---|---|
| `/health` (startup) | 15 seconds |
| `/predict` (per-inference) | 3 seconds |

If `/predict` times out, the frame is dropped and the rule-based fallback generates the inference result for that window.

---

## Flutter Integration

**`lib/services/platform/cpr_api_service.dart`** — HTTP client  
**`lib/services/platform/inference_service_web.dart`** — buffers 60-frame window, calls API, applies fallback

```dart
// Startup (called from injection.dart)
await inferWeb.init();           // → checkHealth()

// Per-frame (called from session_provider.dart)
final result = await inferWeb.inferAsync(frame);
```

---

## Rule-Based Fallback

When the API is unreachable, `InferenceServiceWeb` computes:

| Parameter | Rule |
|---|---|
| Rate | bpm < 100 → `rate_too_slow`; > 120 → `rate_too_fast` |
| Depth | depthCm < 5.0 → `too_shallow`; > 6.0 → `too_deep` |
| Elbows | leftElbowAngle < 160° OR rightElbowAngle < 160° → `bent_elbows` |
| Spine | spineVerticality > 15° → `body_lean` |

---

*GNU GPL v3 · ALU Capstone 2024 · Jean Robert Gatwaza*