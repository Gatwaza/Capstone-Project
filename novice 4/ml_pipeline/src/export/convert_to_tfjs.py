#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

convert_to_tfjs.py
──────────────────
Converts the trained Keras model to TensorFlow.js graph format for the web app.

Output: ../web/assets/models/model.json + group1-shard*.bin

The web app loads this via:
  const model = await tf.loadGraphModel('assets/models/model.json');

Usage:
  cd ml_pipeline
  python src/export/convert_to_tfjs.py --config config.yaml
"""

import argparse
import logging
import sys
from pathlib import Path

import yaml

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)-8s  %(message)s")
log = logging.getLogger("convert_tfjs")


def convert(cfg: dict):
    import tensorflowjs as tfjs
    import tensorflow as tf

    checkpoint_dir = Path(cfg["export"]["checkpoint_dir"])
    model_path     = checkpoint_dir / "model_final.keras"
    tfjs_out_dir   = Path(cfg["export"]["tfjs_path"])

    if not model_path.exists():
        log.error(f"Model not found: {model_path} — run train.py first")
        sys.exit(1)

    log.info(f"Loading model: {model_path}")
    model = tf.keras.models.load_model(str(model_path))

    tfjs_out_dir.mkdir(parents=True, exist_ok=True)

    log.info(f"Converting to TFJS graph model → {tfjs_out_dir}")
    tfjs.converters.save_keras_model(
        model,
        str(tfjs_out_dir),
        quantization_dtype_map={"float16": ["Dense", "LSTM", "Bidirectional"]},
    )

    model_json = tfjs_out_dir / "model.json"
    if model_json.exists():
        size_kb = sum(f.stat().st_size for f in tfjs_out_dir.iterdir()) / 1024
        log.info(f"TFJS model saved: {tfjs_out_dir}  ({size_kb:.1f} KB total)")
    else:
        log.error("TFJS conversion failed — model.json not found")
        sys.exit(1)

    log.info("TFJS conversion complete.")
    log.info("The web app loads it with:")
    log.info("  const model = await tf.loadGraphModel('assets/models/model.json');")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="config.yaml")
    args = parser.parse_args()
    with open(args.config) as f:
        cfg = yaml.safe_load(f)
    convert(cfg)
