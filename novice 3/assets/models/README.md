# Model Assets

Place the trained TFLite model here:

```
novice_cpr_classifier.tflite   — INT8 quantised BiLSTM (~200 KB)
```

## How to generate

```bash
cd ml_pipeline
python src/data/extract_landmarks.py --config config.yaml
python src/training/train.py --config config.yaml
python src/export/convert_to_tflite.py --config config.yaml
# ↑ copies model here automatically
```

This file is tracked with Git LFS. Run `git lfs pull` after cloning.
