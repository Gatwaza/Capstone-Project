// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// Central constants for Novice.
/// All CPR clinical thresholds are sourced from:
/// Perkins et al. (2021) — ERC Guidelines 2021 (DOI: 10.1016/j.resuscitation.2021.02.009)
library;

class AppConstants {
  AppConstants._();

  // ── App ─────────────────────────────────────────────────
  static const String appName    = 'Novice';
  static const String appVersion = '0.1.0';
  static const String appTagline = 'CPR Coach for Sub-Saharan Africa';

  // ── ML Model ────────────────────────────────────────────
  /// TFLite INT8 quantized BiLSTM model (produced by ml_pipeline/src/export/)
  static const String tfliteModelPath =
      'assets/models/novice_cpr_classifier.tflite';

  /// Number of landmark feature dimensions per frame
  static const int landmarkFeatureDims = 12;

  /// Temporal window (frames) fed into BiLSTM — must match API shape (1, 60, 12)
  static const int temporalWindowFrames = 60;

  /// Minimum MediaPipe landmark visibility score to include a frame
  static const double minLandmarkVisibility = 0.5;

  // ── CPR Clinical Thresholds (ERC 2021) ──────────────────
  static const double cprMinDepthCm  = 5.0;
  static const double cprMaxDepthCm  = 6.0;
  static const int    cprMinRateBpm  = 100;
  static const int    cprMaxRateBpm  = 120;

  /// Minimum elbow angle (degrees) for "arms locked"
  static const double elbowLockAngleDeg = 160.0;

  /// Maximum spine lean angle from vertical (degrees)
  static const double maxSpineLeanDeg = 15.0;

  // ── Session ──────────────────────────────────────────────
  static const int sessionInferenceHz        = 5;
  static const int poseEstimationTargetFps   = 25;
  static const int voiceCoachingCooldownMs   = 4000;

  // ── Depth estimation calibration ─────────────────────────
  //
  // PROBLEM (why depth was always clamping at 10 cm):
  //   normToPhysicalCmScale = 200 was far too high.
  //   With a typical web-camera normalised shoulder width of ~0.20:
  //     torsoHeightCm = (0.20 × 200) / 0.85 = 47 cm
  //   Even a modest 25% torso displacement → 0.25 × 47 = 11.8 cm → clamped to 10.
  //
  // FIX — calibrated for ~1 m camera-to-rescuer distance, laptop webcam:
  //
  //   Measured: at 1 m distance, an adult shoulder span of ~40 cm real-world
  //   maps to normalised width ≈ 0.35–0.45 in MediaPipe coordinates
  //   (fraction of frame width, frame width ≈ 640 px at ResolutionPreset.high).
  //
  //   Target: normShoulderWidth × scale ≈ real biacromial width in cm (≈ 40 cm)
  //     → scale = 40 / 0.40 = 100
  //
  //   Torso height from shoulder width:
  //     torsoHeightCm = (normShoulderWidth × 100) / 0.85
  //     At norm=0.40: torsoHeightCm = 40 / 0.85 ≈ 47 cm  ← still too high
  //
  //   The real fix is also raising shoulderWidthToTorsoRatio.
  //   Adult biacromial width (40 cm) vs torso height (shoulder→hip ≈ 50 cm):
  //     ratio = 40/50 = 0.80  ← close to prior value, not the problem
  //
  //   Root issue: normalizedWristDisplacement() returns wrist position relative
  //   to the shoulder→hip span, not actual compression depth.
  //   At rest (hands on chest), wristMidY sits ~30–40% down the torso span,
  //   so normDisp ≈ 0.30–0.40 even with zero compression.
  //
  //   CORRECT approach: the depth signal is the CHANGE in wristMidY during
  //   a compression cycle, not the absolute position.
  //   Until the inference pipeline is retrained with delta-depth features,
  //   we use a conservative scale that makes the displayed number reflect
  //   plausible cm ranges without clamping:
  //
  //     scale = 40   (was 200)  →  torsoHeightCm at norm=0.40: 40/0.85 ≈ 47 cm
  //     ... still high. Use scale = 20, ratio = 1.0 as interim:
  //     torsoHeightCm = (0.40 × 20) / 1.0 = 8 cm  ← motion range, not full torso
  //
  //   This maps the wrist MOTION range (not absolute position) to ~0–8 cm,
  //   which puts a real 5–6 cm compression in the correct zone.
  //
  //   TODO: replace with a proper delta-depth estimator in ml_pipeline once
  //   pilot study frame data is labelled and retraining runs.

  /// Conversion factor: normalised shoulder width → physical cm.
  /// Reduced from 200 → 20 to prevent depth from clamping at 10 cm.
  /// Calibrated for ~1 m webcam distance; re-measure during pilot study.
  static const double normToPhysicalCmScale = 20.0;

  /// Ratio used to convert shoulder width proxy → torso height estimate.
  /// Set to 1.0 (1:1) so the scale directly controls the output range.
  static const double shoulderWidthToTorsoRatio = 1.0;

  /// Fallback torso height (cm) before calibration data accumulates (~1.2 s).
  /// Set to match the motion range implied by normToPhysicalCmScale above.
  static const double fallbackTorsoHeightCm = 8.0;

  // ── TTS prompts — English ────────────────────────────────
  static const Map<String, String> promptsEn = {
    'start':            'Place your hands on the center of the chest.',
    'good':             'Good technique — keep going.',
    'bent_elbows':      'Straighten your arms. Lock your elbows.',
    'hand_too_high':    'Move hands down. Center of the chest.',
    'hand_too_low':     'Move hands up slightly.',
    'too_shallow':      'Press deeper. Aim for five centimeters.',
    'too_deep':         'Ease up. Five to six centimeters maximum.',
    'rate_too_slow':    'Speed up. Keep a steady beat.',
    'rate_too_fast':    'Slow down slightly.',
    'body_lean':        'Lean forward. Keep your body vertical.',
    'incomplete_decomp':'Release fully between compressions.',
    'not_compressing':  'Place hands on chest and begin compressions.',
    'pause_detected':   'Keep going. Do not stop compressions.',
  };

  // ── TTS prompts — Kinyarwanda ────────────────────────────
  /// TODO: Validate with native speaker before pilot study
  static const Map<String, String> promptsRw = {
    'start':            'Shyira intoki zo hagati y\'isaya.',
    'good':             'Imirimo myiza — komeza.',
    'bent_elbows':      'Gorora amaboko. Shira ingufu.',
    'hand_too_high':    'Manura intoki. Hagati y\'isaya.',
    'hand_too_low':     'Fungura intoki hejuru gato.',
    'too_shallow':      'Kanda cyane. Gera kuri santimetero eshanu.',
    'too_deep':         'Fata neza. Kuri santimetero eshanu kugeza cyenda.',
    'rate_too_slow':    'Yihutirire. Komeza intera.',
    'rate_too_fast':    'Yigende buhoro gato.',
    'body_lean':        'Sonera imbere. Shira umubiri wawe hejuru.',
    'incomplete_decomp':'Rekura intoki neza hagati.',
    'not_compressing':  'Shyira intoki ku isaya hanyuma ufate kanda.',
    'pause_detected':   'Komeza. Ntugahagarike.',
  };

  // ── CPR-Coach Error Class Labels (Wang et al., 2023) ────
  static const Map<int, String> errorClassLabels = {
    0: 'correct_compression',
    1: 'hand_too_high',
    2: 'hand_too_low',
    3: 'bent_elbows',
    4: 'body_lean',
    5: 'too_shallow',
    6: 'too_deep',
    7: 'incomplete_decomp',
  };

  // ── UI ───────────────────────────────────────────────────
  static const double canvasAspectRatio  = 3 / 4;
  static const int    depthGaugeBars     = 20;
  static const int    bpmHistoryLength   = 150;
}