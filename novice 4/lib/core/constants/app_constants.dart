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
  /// Path reserved for a future on-device TFLite model (mobile is on hold —
  /// see pubspec.yaml). The current web build calls the hosted TCN model
  /// over HTTP instead; this path is unused on web.
  static const String tfliteModelPath =
      'assets/models/novice_cpr_classifier.tflite';

  /// Number of landmark feature dimensions per frame
  static const int landmarkFeatureDims = 12;

  /// Temporal window (frames) fed into the TCN model — must match API shape (1, 60, 12)
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
  // For a live physical correction like "lock your elbows," too long a
  // cooldown means the person has already done several more bad
  // compressions before hearing about the first one — it feels delayed
  // rather than real-time. 1800ms is short enough to feel like live
  // coaching while still leaving room between cues so they don't overlap
  // or talk over each other.
  static const int voiceCoachingCooldownMs   = 1800;

  // ── Depth estimation calibration ─────────────────────────
  //
  // normalizedWristDisplacement() returns wrist position relative to the
  // shoulder→hip span, not compression depth directly — at rest (hands on
  // chest) wristMidY already sits ~30–40% down the torso span, so the ideal
  // signal is really the CHANGE in wristMidY during a compression cycle,
  // not its absolute position. Until the inference pipeline is retrained
  // with dedicated delta-depth features, the constants below use a
  // conservative scale/ratio pair (normToPhysicalCmScale=20,
  // shoulderWidthToTorsoRatio=1.0) that maps the wrist's MOTION range
  // (not absolute position) to a ~0–8 cm output, which puts a real 5–6 cm
  // compression in the correct displayed zone without clamping at 10 cm.
  // Calibrated for ~1 m camera-to-rescuer distance on a laptop webcam;
  // re-measure during the pilot study.
  //
  // TODO: replace with a proper delta-depth estimator in ml_pipeline once
  // pilot study frame data is labelled and retraining runs.

  /// Conversion factor: normalised shoulder width → physical cm.
  /// Calibrated for ~1 m webcam distance; re-measure during pilot study.
  static const double normToPhysicalCmScale = 20.0;

  /// Ratio used to convert shoulder width proxy → torso height estimate.
  /// Set to 1.0 (1:1) so the scale directly controls the output range.
  static const double shoulderWidthToTorsoRatio = 1.0;

  /// Fallback torso height (cm) before calibration data accumulates (~1.2 s).
  /// Set to match the motion range implied by normToPhysicalCmScale above.
  static const double fallbackTorsoHeightCm = 8.0;

  // ── TTS prompts — English ────────────────────────────────
  // Prompts are phrased as short, specific, actionable live cues (what to
  // change, not a restatement of the rule) rather than a textbook checklist
  // read aloud — a person mid-compression needs something quick. Kept short
  // enough to speak in well under voiceCoachingCooldownMs.
  static const Map<String, String> promptsEn = {
    'start':            'Hands on the center of the chest. Begin compressions.',
    'good':             'Good rhythm — keep that up.',
    'bent_elbows':      'Lock your elbows. Push straight down from your shoulders.',
    'hand_too_high':    'A little lower — center of the chest.',
    'hand_too_low':     'A little higher — center of the chest.',
    'too_shallow':      'Push harder. Go deeper, about five centimeters.',
    'too_deep':         'Ease off slightly — five to six centimeters is enough.',
    'rate_too_slow':    'Faster. Push to the beat.',
    'rate_too_fast':    'Ease back, you\'re rushing it.',
    'body_lean':        'Shoulders directly over your hands.',
    'incomplete_decomp':'Let the chest come all the way back up between pushes.',
    'not_compressing':  'Hands on the chest — start compressing now.',
    'pause_detected':   'Don\'t stop. Keep compressions going.',
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