#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

bilstm_model.py
───────────────
Defines the BiLSTM model for CPR error classification.

Architecture (from research proposal / README):
  Input: (batch, 30, 12)
    ↓
  Bidirectional LSTM(64) — captures downstroke + upstroke of compression
    ↓
  LSTM(32)
    ↓
  Dense(32) + ReLU + Dropout(0.3)
    ↓
  Dense(8, softmax) — 8 error classes

Design choices:
  • Operates on MediaPipe landmark features (not raw pixels) → lightweight (~200 KB)
  • INT8 quantization-friendly: no layer norms that break TFLite
  • Bidirectional on first LSTM layer to capture compression symmetry
  • Second LSTM (unidirectional) for temporal compression
"""

from typing import Tuple
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers


def build_bilstm(
    input_shape:  Tuple[int, int] = (30, 12),
    num_classes:  int             = 8,
    lstm1_units:  int             = 64,
    lstm2_units:  int             = 32,
    dense_units:  int             = 32,
    dropout_rate: float           = 0.3,
) -> keras.Model:
    """
    Build the CPR error classifier.

    Args:
        input_shape:  (temporal_window, feature_dims) — must match config.yaml
        num_classes:  number of output classes (default 8, see config.yaml)
        lstm1_units:  units in first BiLSTM layer
        lstm2_units:  units in second LSTM layer
        dense_units:  units in Dense hidden layer
        dropout_rate: dropout rate after Dense layer

    Returns:
        Compiled Keras model.
    """
    inputs = keras.Input(shape=input_shape, name="landmark_sequence")

    # ── Normalise inputs (Z-score per feature across time) ──
    # Helps with variable body sizes between participants.
    # LayerNormalization breaks INT8 TFLite — use BatchNormalization instead.
    x = layers.BatchNormalization(name="input_norm")(inputs)

    # ── BiLSTM: captures downstroke (press) + upstroke (release) ──
    x = layers.Bidirectional(
        layers.LSTM(lstm1_units, return_sequences=True, name="lstm1"),
        name="bilstm1",
    )(x)

    # ── LSTM: temporal compression ──────────────────────────
    x = layers.LSTM(lstm2_units, return_sequences=False, name="lstm2")(x)

    # ── Dense classification head ────────────────────────────
    x = layers.Dense(dense_units, activation="relu", name="dense1")(x)
    x = layers.Dropout(dropout_rate, name="dropout")(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="output")(x)

    model = keras.Model(inputs=inputs, outputs=outputs, name="novice_cpr_bilstm")

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss="sparse_categorical_crossentropy",
        metrics=[
            "accuracy",
            keras.metrics.SparseTopKCategoricalAccuracy(k=2, name="top2_accuracy"),
        ],
    )

    return model


def build_from_config(cfg: dict) -> keras.Model:
    """Build model using hyperparameters from config.yaml."""
    m_cfg = cfg["model"]
    return build_bilstm(
        input_shape  = tuple(m_cfg["input_shape"]),
        num_classes  = m_cfg["num_classes"],
        lstm1_units  = m_cfg["bilstm_units_1"],
        lstm2_units  = m_cfg["bilstm_units_2"],
        dense_units  = m_cfg["dense_units"],
        dropout_rate = m_cfg["dropout"],
    )


def model_summary_str(model: keras.Model) -> str:
    """Return model.summary() as a string for logging."""
    lines = []
    model.summary(print_fn=lines.append)
    return "\n".join(lines)
