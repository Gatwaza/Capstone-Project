# Research Proposal — Suggested Revisions
## Based on Ground Truth: CPR_Coach_Training_v3_SLIDING_WINDOW.ipynb

> These are recommended amendments to Chapter 3 and other sections of the
> research proposal to bring them into alignment with the actual implemented
> ML pipeline. Sections are identified by their heading in the proposal.

---

### 1. Section 3.2 — Proposed Architecture (MAJOR revision required)

**Current text states:**
> "BiLSTM layer (64 units) ... output Dense layer (8 units, softmax) classifying
> the eight output states: correct compression, wrong hand placement (high), ..."

**What the notebook actually implements:**
The final architecture is a **multi-task TCN (Temporal Convolutional Network)**,
not a single-head BiLSTM. Seven model architectures were benchmarked
(BiLSTM, CNN-LSTM, GRU, TCN, Conv1D, ST-Transformer, CNN-BiLSTM). Only
TCN, Conv1D, and ST-Transformer passed the <100 ms latency requirement for
TFLite deployment. TCN was selected as the deployment candidate (`TCN` model
string already shown in the live app UI).

The model has **three output heads**, not one:

| Head | Classes | Loss weight |
|------|---------|-------------|
| `rate` | `Correct`, `Too_Fast`, `Too_Slow` | 1.0 |
| `depth` | `Correct`, `Too_Shallow`, `Too_Deep` | 2.0 |
| `recoil` | `Complete`, `Incomplete` | 2.0 |

There is **no 8-class softmax**. The 13 CPR error classes from the dataset
are mapped to these three independent classification tasks using the label
mapping in `single_error_to_labels()`.

**Suggested replacement text (Table 1 and architecture paragraph):**

Replace the 8-class output table and BiLSTM description with:

> The deployed model is a Temporal Convolutional Network (TCN) operating on
> a sliding window of 60 consecutive frames (≈2.4 s at 25 FPS) × 12 landmark
> features. The TCN uses four dilated causal convolution blocks (dilation rates
> 1, 2, 4, 8), SpatialDropout1D regularisation, GlobalAveragePooling1D, and a
> shared dense bottleneck (64 units, ReLU). Three independent softmax output
> heads produce simultaneous classifications:
>
> | Output head | Classes | ERC target |
> |---|---|---|
> | Rate | Correct / Too_Fast / Too_Slow | 100–120 bpm |
> | Depth | Correct / Too_Shallow / Too_Deep | 5–6 cm |
> | Recoil | Complete / Incomplete | Full chest recoil |
>
> Loss weights of 1.0 (rate), 2.0 (depth), and 2.0 (recoil) prioritise the
> clinically harder-to-detect depth and recoil errors. FocalCrossEntropy
> (γ=2.0, label_smoothing=0.05) is used for all three heads to address
> class imbalance.

---

### 2. Section 3.2 — Input window / temporal alignment

**Current text states:**
> "Input layer accepting 30 frames × 12 landmark features"

**Ground truth:** `SEQ_LEN = 60` consecutive frames per inference call
(sliding window, stride 30). The v3 notebook explicitly fixed a prior mismatch
where the model was trained on full-video resampled sequences but the live app
sends 60 consecutive real-time frames.

**Replace** "30 frames" with "60 frames" everywhere it appears in §3.2.

---

### 3. Section 3.2 — Model architecture (remove CNN stage claim)

**Current text states:**
> "This architecture deliberately avoids a CNN stage, operating instead on
> pre-extracted landmark features..."

**Ground truth:** The TCN uses Conv1D layers internally (causal dilated
convolutions). While it does not process raw video pixels, saying "avoids a
CNN stage" is misleading for the TCN architecture. The CNN-BiLSTM was also
benchmarked. Remove or amend this sentence.

---

### 4. Section 3.2 — Class imbalance strategy (update loss function)

**Current text states:**
> "Three complementary strategies: (1) SMOTE-like temporal augmentation,
> (2) Weighted cross-entropy loss, (3) Stratified evaluation"

**Ground truth from notebook:**
- SMOTE was not implemented; the notebook uses `compute_class_weight` from
  scikit-learn to generate inverse-frequency sample weights passed as a 1-D
  numpy array to `model.fit()`.
- The loss function is **FocalCrossEntropy** (γ=2.0), not plain weighted
  cross-entropy. This is a key design decision that should be stated.
- GroupShuffleSplit (keyed on source video) ensures no video-level data
  leakage across train/val/test splits — this is stronger than the stratified
  split described in the proposal.

**Suggested revised text:**
> Class imbalance is addressed through: (1) inverse-frequency sample weights
> computed on the training split only (scikit-learn `compute_class_weight`,
> passed as a 1-D array); (2) FocalCrossEntropy loss (γ=2.0,
> label_smoothing=0.05) across all three output heads; and (3) group-aware
> train/val/test splitting via GroupShuffleSplit keyed on source video ID,
> preventing any video from appearing in more than one split.

---

### 5. Section 3.3 — Dataset labels (update error-to-label mapping)

**Current text states:**
> "The 13 CPR error classes targeted by the training pipeline are: (E01)
> wrong hand position too high; (E02) ... (E13) pausing mid-sequence."

**Ground truth — actual label mapping used in training:**

The 13 CPR-Coach action classes (from `ActionList.txt`) are mapped as follows:

| Action | Description | Rate | Depth | Recoil |
|--------|-------------|------|-------|--------|
| 1 | Correct | Correct | Correct | Complete |
| 7 | Jump Pressing | Too_Fast | Correct | Incomplete |
| 12 | Slow Frequency | Too_Slow | Correct | Complete |
| 11 | Insufficient Pressing | Correct | Too_Shallow | Complete |
| 13 | Excessive Pressing | Correct | Too_Deep | Complete |
| 2–6, 8–10, 14 | Posture/hand/position errors | Correct | Correct | Incomplete |

This is a significant difference from the proposal's description of 8 discrete
output classes. The network does not classify "wrong hand position too high" vs
"wrong hand position too low" as separate outputs — all hand/posture errors map
to `recoil=Incomplete`. The proposal's Table 1 should be updated accordingly.

---

### 6. Section 3.3 — Sliding window (new, add this)

Add a new paragraph after the dataset description:

> **Temporal windowing:** Each annotated video (median ~75 frames, range
> 25–300 frames at 25 FPS) is processed by `extract_features()` to produce
> per-frame biomechanical feature vectors. A sliding window of 60 consecutive
> frames with stride 30 then generates multiple training windows per video,
> each matching the exact input format sent by the live application. This
> design decision corrects a prior temporal-scale mismatch, identified as a
> plausible root cause of the `rate=Too_Fast` over-prediction observed in
> early live testing. Source-video identity is used as the grouping key in
> GroupShuffleSplit to ensure zero video overlap across splits.

---

### 7. Section 3.4.2 — NFR2 (update accuracy claim)

**Current text states:**
> "ML classifier F1-score ≥ 85–90% per error class"

**Ground truth:** The notebook reports F1 scores of 75–94% across classes
depending on the head and class. The `Too_Shallow` depth class and
`Too_Fast` rate class are the hardest. "≥ 85%" is achievable as an
aggregate target but may not hold per-class for all heads. Recommend
revising to:

> ML classifier macro-average F1-score ≥ 80% per output head (rate, depth,
> recoil); per-class F1 ≥ 70% with particular attention to the minority
> depth and rate classes.

---

### 8. Section 3.7 — Development tools (update ML row)

Replace the "ML Training" and "Mobile Export" rows:

| Layer | Tool | Purpose |
|-------|------|---------|
| ML Training | TensorFlow 2.x / Keras, FocalCrossEntropy | TCN multi-task training |
| Model selection | 7 architectures benchmarked (BiLSTM, CNN-LSTM, GRU, TCN, Conv1D, ST-Transformer, CNN-BiLSTM) | TFLite latency gate (<100 ms) |
| Mobile Export | TFLite Converter (INT8 quantisation), TCN only | BiLSTM/GRU fail Flex delegate latency |
| Scaler | scikit-learn StandardScaler (fit on train only) | Single scaler exported alongside model |

---

### 9. Section 3.9 / 3.10 — Research data collection (minor)

The in-app session logger already captures `rate`, `depth`, and `recoil`
per-class distributions (stored in `errorRates` map in `SessionModel`).
The research metrics panel in the results screen also stores per-head TCN
outputs. The proposal's description of "8-class output labels" should be
updated to reflect the three-head structure so that the data collection
instruments align with what is actually logged.

---

### Summary of priority changes

| Priority | Section | Change |
|----------|---------|--------|
| Critical | §3.2 | Replace BiLSTM/8-class with TCN/3-head |
| Critical | §3.2 | Change 30-frame input to 60-frame |
| Critical | §3.3 | Update error-to-label mapping table |
| High | §3.2 | Update class imbalance strategy (FocalCE, GroupShuffleSplit) |
| High | §3.3 | Add sliding window paragraph |
| Medium | §3.4.2 | Revise F1 acceptance threshold wording |
| Medium | §3.7 | Update tools table |
| Low | §3.9/3.10 | Align data collection language with 3-head outputs |
