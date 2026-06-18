# Novice — ML Pipeline

**GNU GPL v3 · Jean Robert Gatwaza / African Leadership University**

---

## Overview

The `ml_pipeline/` directory contains the full Python training pipeline for the CNN-BiLSTM model. The trained model is exported in two formats:
- **TF.js graph model** → `web/assets/models/` (served via the Hugging Face Spaces API)
- **TFLite INT8** → `assets/models/novice_cpr_classifier.tflite` (for future mobile builds)

---

## Pipeline Structure

```
ml_pipeline/
├── requirements.txt               ← pinned for M1 Max + Metal GPU
├── CPR_Coach_Training.ipynb       ← full training notebook (Colab-ready)
└── src/
    ├── data/
    │   ├── extract_landmarks.py   ← MediaPipe → .npy feature files
    │   └── dataset_loader.py      ← tf.data pipeline + augmentation
    ├── models/
    │   └── bilstm_model.py        ← CNN-BiLSTM architecture
    ├── training/
    │   ├── train.py               ← full training loop + callbacks
    │   └── evaluate.py            ← F1, confusion matrix, TFLite latency
    └── export/
        ├── convert_to_tflite.py   ← INT8 quantised .tflite
        └── convert_to_tfjs.py     ← TFJS graph model for web
```

---

## Model Architecture

```python
Input: (batch, 60, 12)         # 60 frames × 12 landmark features
  │
  ├─ Conv1D(64, kernel=3, relu)  # local temporal patterns
  ├─ MaxPooling1D(2)
  ├─ Bidirectional(LSTM(128))    # long-range bidirectional context
  ├─ Dense(64, relu)
  ├─ Dropout(0.3)
  └─ Dense(8, softmax)           # 8 error classes
```

**Why CNN-BiLSTM?** The Conv1D encoder captures short-window compression rhythm patterns before the BiLSTM processes the full sequence. This outperformed pure LSTM and pure CNN baselines in cross-validated F1 score on the training dataset.

---

## Error Classes

| Index | Label | ERC 2021 Violation |
|---|---|---|
| 0 | `correct_compression` | — |
| 1 | `hand_too_high` | Hands not on lower half of sternum |
| 2 | `hand_too_low` | Below xiphoid process |
| 3 | `bent_elbows` | Elbows not locked (< 160°) |
| 4 | `body_lean` | Spine lean > 15° from vertical |
| 5 | `too_shallow` | Depth < 5 cm |
| 6 | `too_deep` | Depth > 6 cm |
| 7 | `incomplete_decomp` | Insufficient chest recoil |

Source: Wang et al. (2023); thresholds: Perkins et al. (2021) ERC Guidelines.

---

## Dataset

| Split | Entries |
|---|---|
| Training (`train_keypoints.pkl`) | 1,344 |
| Test (`test_keypoints.pkl`) | 1,008 |
| Total unique physical videos | 2,352 |

Public dataset: https://drive.google.com/drive/folders/1zJoJYrmvIv9TgNd5ZmVYVq7odkB5wI5e?usp=drive_link

---

## Setup (M1 Max + Metal GPU)

```bash
cd ml_pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Verify Metal GPU
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
# Expected: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

---

## Running the Pipeline

```bash
# Step 1 — Extract MediaPipe landmarks from all videos (~5–20 min on M1 Max)
python src/data/extract_landmarks.py --config config.yaml

# Step 2 — Train CNN-BiLSTM (~20–60 min with Metal GPU)
python src/training/train.py --config config.yaml

# Step 3 — Evaluate
python src/training/evaluate.py --config config.yaml
# Reports: F1-weighted, confusion matrix, per-class precision/recall

# Step 4 — Export TFLite INT8 (mobile)
python src/export/convert_to_tflite.py --config config.yaml
# → assets/models/novice_cpr_classifier.tflite

# Step 5 — Export TF.js (web / Hugging Face API)
python src/export/convert_to_tfjs.py --config config.yaml
# → web/assets/models/model.json + *.bin shards
```

---

## API Shape

The Hugging Face Spaces API (`jeanrobert-novice.hf.space`) expects:

```json
POST /predict
{
  "sequence": [[...12 floats...], ...] // shape: (60, 12)
}
```

Response:
```json
{
  "rate":   { "label": "Correct|Too_Fast|Too_Slow", "confidence": 0.92 },
  "depth":  { "label": "Correct|Too_Shallow|Too_Deep", "confidence": 0.87 },
  "recoil": { "label": "Correct|Incomplete", "confidence": 0.81 }
}
```

The `CprApiService.resolvedLabel` method maps these three heads to the 8-class error label used by the feedback engine.

---

## Evaluation Targets

| Metric | Target |
|---|---|
| F1-weighted | ≥ 0.80 |
| TFJS inference latency | < 100 ms / frame |
| TFLite INT8 model size | < 10 MB |

---

## Colab Quickstart

```python
from google.colab import drive
from pathlib import Path
import tensorflow as tf, numpy as np

drive.mount('/content/drive')

DATA_ROOT      = Path('/content/drive/MyDrive/cpr_coach_data')
KEYPOINTS_DIR  = DATA_ROOT / 'Keypoints'
ANN_DIR        = DATA_ROOT / 'ann'
CHECKPOINT_DIR = Path('/content/drive/MyDrive/cpr_coach_checkpoints_tf')
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)

tf.random.set_seed(42)
np.random.seed(42)

gpus = tf.config.list_physical_devices('GPU')
print(f'TF {tf.__version__} | GPUs: {len(gpus)}')
if gpus:
    tf.config.experimental.set_memory_growth(gpus[0], True)
```

Full notebook: `ml_pipeline/CPR_Coach_Training.ipynb`

---

*GNU GPL v3 · ALU Capstone 2024 · Jean Robert Gatwaza*
