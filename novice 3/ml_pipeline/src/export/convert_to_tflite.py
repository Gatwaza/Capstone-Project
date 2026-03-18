#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

convert_to_tflite.py
────────────────────
Converts the trained Keras model to TFLite INT8 for mobile deployment.

INT8 quantisation reduces the model from ~800 KB (.keras float32)
to ~200 KB (.tflite INT8), well within the 5 MB target.

Output: ../assets/models/novice_cpr_classifier.tflite
        (relative to ml_pipeline/ — place in Flutter assets/)

Usage:
  cd ml_pipeline
  python src/export/convert_to_tflite.py --config config.yaml
"""

import argparse
import logging
import sys
from pathlib import Path

import numpy as np
import yaml

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)-8s  %(message)s")
log = logging.getLogger("convert_tflite")


def representative_dataset_gen(landmarks_dir: Path, window: int, feature_dims: int, n_samples: int = 200):
    """
    Generator yielding representative input samples for INT8 calibration.
    TFLite's post-training quantisation needs ~100–200 real inputs.
    """
    npy_files = sorted(landmarks_dir.rglob("*.npy"))

    if not npy_files:
        log.warning(
            "No .npy landmark files found for INT8 calibration.\n"
            "Using random synthetic inputs — quantisation accuracy may be degraded.\n"
            "Run extract_landmarks.py first for best results."
        )
        for _ in range(n_samples):
            dummy = np.random.randn(1, window, feature_dims).astype(np.float32)
            yield [dummy]
        return

    yielded = 0
    for npy_path in npy_files:
        seq = np.load(str(npy_path))   # (T, F)
        if seq.ndim != 2 or seq.shape[1] != feature_dims:
            continue
        for start in range(0, len(seq) - window, window):
            window_data = seq[start: start + window]
            yield [window_data[np.newaxis].astype(np.float32)]
            yielded += 1
            if yielded >= n_samples:
                return


def convert(cfg: dict):
    import tensorflow as tf

    checkpoint_dir = Path(cfg["export"]["checkpoint_dir"])
    model_path     = checkpoint_dir / "model_final.keras"
    tflite_out     = Path(cfg["export"]["tflite_path"])
    lm_dir         = Path(cfg["dataset"]["landmarks_dir"])
    window         = cfg["features"]["temporal_window"]
    feature_dims   = cfg["features"]["feature_dims"]
    quantisation   = cfg["export"]["quantization"]

    if not model_path.exists():
        log.error(f"Model not found: {model_path}  — run train.py first")
        sys.exit(1)

    log.info(f"Loading model: {model_path}")
    model = tf.keras.models.load_model(str(model_path))

    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    if quantisation == "int8":
        log.info("Applying INT8 post-training quantisation …")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.representative_dataset = lambda: representative_dataset_gen(
            lm_dir, window, feature_dims
        )
        # Force INT8 input/output for maximum on-device speedup
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        ]
        converter.inference_input_type  = tf.int8
        converter.inference_output_type = tf.int8
    elif quantisation == "float16":
        log.info("Applying float16 quantisation …")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        converter.target_spec.supported_types = [tf.float16]
    else:
        log.info("Converting without quantisation (float32) …")

    tflite_model = converter.convert()

    tflite_out.parent.mkdir(parents=True, exist_ok=True)
    tflite_out.write_bytes(tflite_model)

    size_kb = tflite_out.stat().st_size / 1024
    log.info(f"TFLite model saved: {tflite_out}  ({size_kb:.1f} KB)")

    if size_kb > 5120:   # 5 MB target from research proposal
        log.warning(f"Model size {size_kb:.1f} KB exceeds 5 MB target. "
                    "Consider pruning or reducing LSTM units in config.yaml.")

    # ── Quick sanity check ────────────────────────────────────
    log.info("Running inference sanity check …")
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()
    in_detail  = interpreter.get_input_details()[0]
    out_detail = interpreter.get_output_details()[0]

    dummy = np.zeros((1, window, feature_dims), dtype=np.float32)
    if in_detail["dtype"] == np.int8:
        scale, zero_point = in_detail["quantization"]
        dummy = (dummy / scale + zero_point).astype(np.int8)

    interpreter.set_tensor(in_detail["index"], dummy)
    interpreter.invoke()
    output = interpreter.get_tensor(out_detail["index"])
    log.info(f"  Sanity check passed — output shape: {output.shape}")
    log.info("TFLite conversion complete.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="config.yaml")
    args = parser.parse_args()
    with open(args.config) as f:
        cfg = yaml.safe_load(f)
    convert(cfg)
