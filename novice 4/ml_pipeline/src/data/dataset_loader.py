#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

dataset_loader.py
─────────────────
Builds reproducible tf.data pipelines from the landmark .npy files
produced by extract_landmarks.py.

Handles:
  • Temporal windowing (sliding window of 30 frames with stride 5)
  • Class-imbalance weighting
  • Augmentation (temporal jitter, Gaussian noise, horizontal flip)
  • Train / val / test splits
"""

import logging
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
import tensorflow as tf
import yaml

log = logging.getLogger("dataset_loader")


# ── Sliding window ─────────────────────────────────────────────────────────────

def sliding_windows(
    sequence: np.ndarray,   # (T, F)
    window:   int,
    stride:   int = 5,
) -> np.ndarray:
    """
    Extract all windows of length `window` from a (T, F) sequence.
    Returns array of shape (N_windows, window, F).
    """
    T, F = sequence.shape
    if T < window:
        # Pad with zeros if sequence shorter than window
        pad = np.zeros((window - T, F), dtype=sequence.dtype)
        sequence = np.vstack([sequence, pad])
        T = window

    indices = np.arange(0, T - window + 1, stride)
    return np.stack([sequence[i: i + window] for i in indices], axis=0)


# ── Augmentation ───────────────────────────────────────────────────────────────

def augment_window(
    window: np.ndarray,   # (W, F)
    cfg:    dict,
    rng:    np.random.Generator,
) -> np.ndarray:
    """
    Apply augmentations to a single window.

    Augmentations are safe for CPR pose sequences — they do not alter
    class identity (e.g. horizontal flip is valid because CPR is symmetric).
    """
    aug_cfg = cfg["training"]["augmentation"]
    if not aug_cfg.get("enabled", True):
        return window

    W, F = window.shape

    # 1. Temporal jitter: shift window start by ±N frames (zero-pad)
    jitter = aug_cfg.get("temporal_jitter_frames", 2)
    if jitter > 0 and rng.random() > 0.5:
        shift = rng.integers(-jitter, jitter + 1)
        if shift > 0:
            window = np.vstack([np.zeros((shift, F), dtype=window.dtype), window[:-shift]])
        elif shift < 0:
            window = np.vstack([window[-shift:], np.zeros((-shift, F), dtype=window.dtype)])

    # 2. Gaussian noise on landmark coordinates (features 0–9)
    noise_std = aug_cfg.get("gaussian_noise_std", 0.02)
    if noise_std > 0:
        noise = rng.normal(0, noise_std, size=(W, 10)).astype(np.float32)
        window = window.copy()
        window[:, :10] += noise

    # 3. Horizontal flip: negate elbow angles (left ↔ right symmetry)
    if aug_cfg.get("horizontal_flip", True) and rng.random() > 0.5:
        window = window.copy()
        # Swap left/right elbow angles (indices 0 and 1)
        window[:, 0], window[:, 1] = window[:, 1].copy(), window[:, 0].copy()
        # Swap left/right visibility flags (indices 10 and 11)
        window[:, 10], window[:, 11] = window[:, 11].copy(), window[:, 10].copy()

    return window


# ── Per-split dataset builder ──────────────────────────────────────────────────

def load_split(
    landmarks_dir: Path,
    split:         str,            # "train", "val", or "test"
    class_map:     Dict[str, int],
    window:        int,
    stride:        int,
    min_vis:       float,
    augment:       bool,
    cfg:           dict,
    seed:          int = 42,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Load all windows and labels for a given split.

    Returns:
      X: float32 array (N, window, feature_dims)
      y: int32   array (N,)
    """
    split_dir = landmarks_dir / split
    if not split_dir.exists():
        log.warning(f"Split directory not found: {split_dir}")
        return np.empty((0, window, cfg["features"]["feature_dims"]), dtype=np.float32), \
               np.empty((0,), dtype=np.int32)

    rng = np.random.default_rng(seed)
    X_all: List[np.ndarray] = []
    y_all: List[int]        = []

    class_dirs = sorted(split_dir.iterdir())
    for class_dir in class_dirs:
        if not class_dir.is_dir():
            continue
        label_name = class_dir.name
        if label_name not in class_map:
            log.warning(f"Unknown class directory '{label_name}' — skipping")
            continue
        label_idx = class_map[label_name]

        npy_files = sorted(class_dir.glob("*.npy"))
        for npy_path in npy_files:
            seq = np.load(str(npy_path))   # (T, 12)
            if seq.ndim != 2 or seq.shape[1] != cfg["features"]["feature_dims"]:
                log.warning(f"Shape mismatch in {npy_path} — skipping")
                continue

            windows = sliding_windows(seq, window, stride)   # (N, W, 12)

            if augment:
                windows = np.stack(
                    [augment_window(w, cfg, rng) for w in windows], axis=0
                )

            X_all.append(windows)
            y_all.extend([label_idx] * len(windows))

    if not X_all:
        log.warning(f"No data loaded for split '{split}'")
        return np.empty((0, window, cfg["features"]["feature_dims"]), dtype=np.float32), \
               np.empty((0,), dtype=np.int32)

    X = np.concatenate(X_all, axis=0).astype(np.float32)
    y = np.array(y_all, dtype=np.int32)

    # Shuffle
    idx = rng.permutation(len(X))
    return X[idx], y[idx]


# ── tf.data pipeline ───────────────────────────────────────────────────────────

def build_dataset(
    X: np.ndarray,
    y: np.ndarray,
    batch_size:    int,
    shuffle:       bool,
    class_weights: Dict[int, float],
) -> tf.data.Dataset:
    """
    Build a tf.data.Dataset from arrays.
    Applies class weights as sample weights for weighted cross-entropy.
    """
    sample_weights = np.array([class_weights.get(int(label), 1.0) for label in y],
                               dtype=np.float32)

    dataset = tf.data.Dataset.from_tensor_slices((X, y, sample_weights))

    if shuffle:
        dataset = dataset.shuffle(buffer_size=min(len(X), 10_000), seed=42)

    dataset = (
        dataset
        .batch(batch_size, drop_remainder=False)
        .prefetch(tf.data.AUTOTUNE)
    )
    return dataset


# ── Convenience loader ─────────────────────────────────────────────────────────

def build_all_datasets(cfg: dict) -> dict:
    """
    Build train / val / test tf.data.Datasets from config.

    Returns dict with keys 'train', 'val', 'test' and
    additional metadata ('class_map', 'class_weights', 'n_samples').
    """
    lm_dir     = Path(cfg["dataset"]["landmarks_dir"])
    window     = cfg["features"]["temporal_window"]
    min_vis    = cfg["features"]["min_visibility"]
    batch_size = cfg["training"]["batch_size"]
    seed       = cfg["dataset"]["random_seed"]

    # Inverse-frequency class weights from config
    class_weights_cfg = cfg["training"]["class_weights"]

    # Build string → int class map from config
    class_map_int: Dict[str, int] = {
        name: int(idx) for idx, name in cfg["dataset"]["classes"].items()
    }

    datasets = {}
    n_samples = {}

    for split, augment in [("train", True), ("val", False), ("test", False)]:
        X, y = load_split(
            landmarks_dir=lm_dir,
            split=split,
            class_map=class_map_int,
            window=window,
            stride=5 if split == "train" else window,  # dense for train, non-overlap for eval
            min_vis=min_vis,
            augment=augment,
            cfg=cfg,
            seed=seed,
        )
        log.info(f"  {split:5s}: {len(X):6,} windows  classes: {np.unique(y).tolist() if len(y) > 0 else []}")
        n_samples[split] = len(X)

        datasets[split] = build_dataset(
            X, y, batch_size,
            shuffle=(split == "train"),
            class_weights=class_weights_cfg,
        )

    datasets["class_map"]     = class_map_int
    datasets["class_weights"] = class_weights_cfg
    datasets["n_samples"]     = n_samples
    return datasets
