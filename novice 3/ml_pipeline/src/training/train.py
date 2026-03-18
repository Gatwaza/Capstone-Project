#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

train.py
────────
Main training script for the BiLSTM CPR error classifier.

Usage:
  cd ml_pipeline
  python src/training/train.py --config config.yaml

After training, run export scripts:
  python src/export/convert_to_tflite.py --config config.yaml
  python src/export/convert_to_tfjs.py   --config config.yaml
"""

import argparse
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

import numpy as np
import tensorflow as tf
import yaml

sys.path.insert(0, str(Path(__file__).parent.parent))
from data.dataset_loader import build_all_datasets
from models.bilstm_model import build_from_config, model_summary_str

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("train")


def make_callbacks(checkpoint_dir: Path, patience: int) -> list:
    """Build Keras training callbacks."""
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    best_weights = checkpoint_dir / "best_weights.h5"

    return [
        # Save best model by val loss
        tf.keras.callbacks.ModelCheckpoint(
            filepath=str(best_weights),
            monitor="val_loss",
            save_best_only=True,
            save_weights_only=True,
            verbose=1,
        ),
        # Stop early if val_loss plateaus
        tf.keras.callbacks.EarlyStopping(
            monitor="val_loss",
            patience=patience,
            restore_best_weights=True,
            verbose=1,
        ),
        # Cosine decay LR schedule
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=max(3, patience // 3),
            min_lr=1e-6,
            verbose=1,
        ),
        # TensorBoard logs
        tf.keras.callbacks.TensorBoard(
            log_dir=str(checkpoint_dir / "tb_logs"),
            histogram_freq=0,
            write_graph=False,
        ),
    ]


def main(cfg: dict):
    # ── Reproducibility ──────────────────────────────────────
    seed = cfg["dataset"]["random_seed"]
    tf.random.set_seed(seed)
    np.random.seed(seed)

    log.info("=" * 60)
    log.info("Novice — CPR BiLSTM Training")
    log.info("=" * 60)

    # ── Check landmark data exists ────────────────────────────
    lm_dir = Path(cfg["dataset"]["landmarks_dir"])
    if not lm_dir.exists():
        log.error(
            f"Landmark directory not found: {lm_dir}\n"
            "Run extract_landmarks.py first:\n"
            "  python src/data/extract_landmarks.py --config config.yaml"
        )
        sys.exit(1)

    # ── Load datasets ─────────────────────────────────────────
    log.info("Loading datasets …")
    datasets = build_all_datasets(cfg)
    n_train = datasets["n_samples"]["train"]
    n_val   = datasets["n_samples"]["val"]

    if n_train == 0:
        log.error(
            "No training samples found.\n"
            "Ensure Sample_Dataset is mounted at data/raw/ and "
            "extract_landmarks.py has been run."
        )
        sys.exit(1)

    log.info(f"  Train: {n_train:,}  Val: {n_val:,}")

    # ── Build model ───────────────────────────────────────────
    log.info("Building BiLSTM model …")
    model = build_from_config(cfg)
    log.info(model_summary_str(model))

    # ── Callbacks ─────────────────────────────────────────────
    checkpoint_dir = Path(cfg["export"]["checkpoint_dir"])
    patience       = cfg["training"]["early_stopping_patience"]
    callbacks      = make_callbacks(checkpoint_dir, patience)

    # ── Optional WandB ───────────────────────────────────────
    try:
        import wandb
        from wandb.keras import WandbCallback
        wandb.init(
            project=os.environ.get("WANDB_PROJECT", "novice-cpr-coach"),
            entity=os.environ.get("WANDB_ENTITY"),
            config=cfg,
            name=f"bilstm_{datetime.now():%Y%m%d_%H%M}",
        )
        callbacks.append(WandbCallback(save_model=False))
        log.info("WandB tracking enabled")
    except (ImportError, Exception) as e:
        log.info(f"WandB not available ({e}) — training without experiment tracking")

    # ── Train ─────────────────────────────────────────────────
    log.info(f"Training for up to {cfg['training']['epochs']} epochs …")
    history = model.fit(
        datasets["train"],
        validation_data=datasets["val"],
        epochs=cfg["training"]["epochs"],
        callbacks=callbacks,
        verbose=1,
    )

    # ── Save final model ──────────────────────────────────────
    final_path = checkpoint_dir / "model_final.keras"
    model.save(str(final_path))
    log.info(f"Final model saved: {final_path}")

    # ── Quick val metrics ─────────────────────────────────────
    log.info("Evaluating on validation set …")
    val_results = model.evaluate(datasets["val"], verbose=0)
    for name, val in zip(model.metrics_names, val_results):
        log.info(f"  val_{name}: {val:.4f}")

    log.info("Training complete. Next steps:")
    log.info("  python src/export/convert_to_tflite.py --config config.yaml")
    log.info("  python src/export/convert_to_tfjs.py   --config config.yaml")
    log.info("  python src/training/evaluate.py        --config config.yaml")

    return model, history


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Novice CPR BiLSTM model")
    parser.add_argument("--config", default="config.yaml")
    args = parser.parse_args()

    with open(args.config) as f:
        cfg = yaml.safe_load(f)

    main(cfg)
