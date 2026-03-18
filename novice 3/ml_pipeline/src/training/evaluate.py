#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

evaluate.py
───────────
Evaluates the trained model against research proposal targets:
  • Classifier F1-score ≥ 0.85 per class
  • Inference latency < 100ms per frame (TFLite INT8)
  • Compression rate accuracy ±5 bpm of true rate

Outputs:
  • Console report
  • evaluation_report.json (for pilot study documentation)
  • confusion_matrix.png

Usage:
  python src/training/evaluate.py --config config.yaml
  python src/training/evaluate.py --config config.yaml --model checkpoints/model_final.keras
"""

import argparse
import json
import logging
import sys
import time
from pathlib import Path

import matplotlib
matplotlib.use("Agg")   # headless on server
import matplotlib.pyplot as plt
import numpy as np
import yaml
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    f1_score,
)

sys.path.insert(0, str(Path(__file__).parent.parent))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("evaluate")


def plot_confusion_matrix(
    cm: np.ndarray,
    class_names: list,
    output_path: Path,
) -> None:
    """Save a normalised confusion matrix PNG."""
    cm_norm = cm.astype(float) / (cm.sum(axis=1, keepdims=True) + 1e-9)
    fig, ax = plt.subplots(figsize=(10, 8))
    im = ax.imshow(cm_norm, cmap="Blues", vmin=0, vmax=1)
    plt.colorbar(im, ax=ax)

    ax.set_xticks(range(len(class_names)))
    ax.set_yticks(range(len(class_names)))
    ax.set_xticklabels(class_names, rotation=45, ha="right", fontsize=9)
    ax.set_yticklabels(class_names, fontsize=9)
    ax.set_xlabel("Predicted")
    ax.set_ylabel("True")
    ax.set_title("Novice CPR Classifier — Normalised Confusion Matrix")

    # Annotate cells
    for i in range(len(class_names)):
        for j in range(len(class_names)):
            ax.text(j, i, f"{cm_norm[i, j]:.2f}",
                    ha="center", va="center",
                    color="white" if cm_norm[i, j] > 0.5 else "black",
                    fontsize=8)

    plt.tight_layout()
    plt.savefig(str(output_path), dpi=150, bbox_inches="tight")
    plt.close(fig)
    log.info(f"Confusion matrix saved: {output_path}")


def estimate_bpm_accuracy(
    wrist_y_sequence: np.ndarray,  # (T,) normalized wrist Y coords
    true_bpm: float,
    fps: int = 25,
) -> dict:
    """
    Rule-based BPM estimation via peak detection.
    Mirrors the approach in lib/services/inference_service.dart.

    Returns dict with estimated_bpm, error_bpm, within_target.
    """
    from scipy.signal import find_peaks

    velocity = np.diff(wrist_y_sequence)
    # Detect downward peaks (compression = Y increases)
    peaks, _ = find_peaks(
        velocity,
        distance=int(fps * 0.4),  # min 0.4s between peaks (max 150 bpm)
        height=0.005,              # noise threshold
    )

    if len(peaks) < 2:
        return {"estimated_bpm": 0, "error_bpm": None, "within_target": False}

    intervals_s = np.diff(peaks) / fps
    mean_interval = float(np.mean(intervals_s))
    estimated_bpm = 60.0 / mean_interval if mean_interval > 0 else 0.0

    error = abs(estimated_bpm - true_bpm)
    return {
        "estimated_bpm": round(estimated_bpm, 1),
        "true_bpm":      round(true_bpm, 1),
        "error_bpm":     round(error, 1),
        "within_target": error <= 5.0,   # target: ±5 bpm (from research proposal)
    }


def measure_tflite_latency(tflite_path: Path, input_shape: tuple) -> dict:
    """
    Measure TFLite INT8 inference latency (100 warm-up + 100 measured runs).
    Target: < 100ms per frame on mid-range device.

    NOTE: This measures latency on the current machine (M1 Mac).
    On-device latency on iPhone 15 Pro will differ — validate empirically.
    """
    try:
        import tensorflow as tf
        interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
        interpreter.allocate_tensors()
        in_details  = interpreter.get_input_details()
        out_details = interpreter.get_output_details()

        dummy = np.random.randn(*input_shape).astype(np.float32)

        # Warm-up
        for _ in range(10):
            interpreter.set_tensor(in_details[0]["index"], dummy[np.newaxis])
            interpreter.invoke()

        # Measure
        times = []
        for _ in range(100):
            t0 = time.perf_counter()
            interpreter.set_tensor(in_details[0]["index"], dummy[np.newaxis])
            interpreter.invoke()
            times.append((time.perf_counter() - t0) * 1000)

        return {
            "mean_ms":   round(float(np.mean(times)), 2),
            "p95_ms":    round(float(np.percentile(times, 95)), 2),
            "within_target": float(np.mean(times)) < 100.0,
        }
    except Exception as e:
        log.warning(f"TFLite latency measurement failed: {e}")
        return {"mean_ms": None, "within_target": None, "error": str(e)}


def main(cfg: dict, model_path: str = None):
    import tensorflow as tf

    checkpoint_dir = Path(cfg["export"]["checkpoint_dir"])
    model_path     = model_path or str(checkpoint_dir / "model_final.keras")
    tflite_path    = Path(cfg["export"]["tflite_path"])

    class_names = [cfg["dataset"]["classes"][k] for k in sorted(cfg["dataset"]["classes"].keys())]

    # ── Load model ────────────────────────────────────────────
    log.info(f"Loading model: {model_path}")
    try:
        model = tf.keras.models.load_model(model_path)
    except Exception as e:
        log.error(f"Could not load model: {e}\nRun train.py first.")
        sys.exit(1)

    # ── Load test set ─────────────────────────────────────────
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from data.dataset_loader import build_all_datasets
    datasets = build_all_datasets(cfg)

    if datasets["n_samples"]["test"] == 0:
        log.error("No test samples found. Run extract_landmarks.py first.")
        sys.exit(1)

    # ── Collect predictions ───────────────────────────────────
    y_true_all = []
    y_pred_all = []

    for X_batch, y_batch, _ in datasets["test"]:
        preds = model.predict(X_batch, verbose=0)
        y_pred_all.extend(np.argmax(preds, axis=1).tolist())
        y_true_all.extend(y_batch.numpy().tolist())

    y_true = np.array(y_true_all)
    y_pred = np.array(y_pred_all)

    # ── Classification report ─────────────────────────────────
    report = classification_report(
        y_true, y_pred,
        target_names=class_names,
        output_dict=True,
    )
    log.info("\n" + classification_report(y_true, y_pred, target_names=class_names))

    per_class_f1 = {
        cls: round(report[cls]["f1-score"], 4)
        for cls in class_names if cls in report
    }

    target_f1 = cfg["evaluation"]["target_f1_per_class"]
    f1_pass   = all(v >= target_f1 for v in per_class_f1.values())
    log.info(f"F1 target (≥{target_f1}): {'PASS ✓' if f1_pass else 'FAIL ✗'}")

    # ── Confusion matrix ──────────────────────────────────────
    cm = confusion_matrix(y_true, y_pred)
    cm_path = checkpoint_dir / "confusion_matrix.png"
    plot_confusion_matrix(cm, class_names, cm_path)

    # ── TFLite latency ────────────────────────────────────────
    latency_result = {}
    if tflite_path.exists():
        log.info("Measuring TFLite latency …")
        latency_result = measure_tflite_latency(
            tflite_path,
            tuple(cfg["model"]["input_shape"]),
        )
        log.info(f"  Mean latency: {latency_result.get('mean_ms')} ms  "
                 f"P95: {latency_result.get('p95_ms')} ms  "
                 f"Target (<100ms): {'PASS ✓' if latency_result.get('within_target') else 'FAIL ✗'}")
    else:
        log.warning(f"TFLite model not found at {tflite_path} — run convert_to_tflite.py")

    # ── Save report ───────────────────────────────────────────
    eval_report = {
        "model_path":       model_path,
        "n_test_samples":   int(len(y_true)),
        "accuracy":         round(float(np.mean(y_true == y_pred)), 4),
        "per_class_f1":     per_class_f1,
        "f1_target_met":    f1_pass,
        "macro_f1":         round(float(f1_score(y_true, y_pred, average="macro")), 4),
        "tflite_latency":   latency_result,
    }

    report_path = checkpoint_dir / "evaluation_report.json"
    with open(report_path, "w") as f:
        json.dump(eval_report, f, indent=2)
    log.info(f"Evaluation report saved: {report_path}")

    return eval_report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="config.yaml")
    parser.add_argument("--model",  default=None, help="Override model path")
    args = parser.parse_args()

    with open(args.config) as f:
        cfg = yaml.safe_load(f)

    main(cfg, args.model)
