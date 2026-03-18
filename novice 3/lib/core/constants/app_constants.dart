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
  static const String appName = 'Novice';
  static const String appVersion = '0.1.0';
  static const String appTagline = 'CPR Coach for Sub-Saharan Africa';

  // ── ML Model ────────────────────────────────────────────
  /// TFLite INT8 quantized BiLSTM model (produced by ml_pipeline/src/export/)
  /// Place the compiled .tflite at this path after training.
  static const String tfliteModelPath = 'assets/models/novice_cpr_classifier.tflite';

  /// Number of landmark feature dimensions per frame (see ml_pipeline/src/data/)
  static const int landmarkFeatureDims = 12;

  /// Temporal window (frames) fed into BiLSTM
  static const int temporalWindowFrames = 30;

  /// Minimum MediaPipe landmark visibility score to include a frame
  static const double minLandmarkVisibility = 0.5;

  // ── CPR Clinical Thresholds (ERC 2021) ──────────────────
  static const double cprMinDepthCm = 5.0;
  static const double cprMaxDepthCm = 6.0;
  static const int cprMinRateBpm = 100;
  static const int cprMaxRateBpm = 120;

  /// Minimum elbow angle (degrees) for "arms locked" — below this = bent elbows error
  static const double elbowLockAngleDeg = 160.0;

  /// Maximum spine lean angle from vertical (degrees) — above this = body lean error
  static const double maxSpineLeanDeg = 15.0;

  // ── Session ──────────────────────────────────────────────
  static const int sessionInferenceHz = 5;      // inference calls per second
  static const int poseEstimationTargetFps = 25; // MediaPipe target FPS
  static const int voiceCoachingCooldownMs = 4000; // min ms between TTS prompts

  // ── TTS prompts — English ────────────────────────────────
  /// All prompt strings follow a 5–8 word imperative structure
  /// for cognitive load reduction (NASA-TLX target ≤ 40)
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
  /// Source: Umuganda TTS project (kinyarwanda.net)
  /// TODO: Validate all Kinyarwanda translations with native speaker before pilot study
  /// TODO: Record native speaker audio for pre-recorded hybrid approach (see SETUP.md)
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
  /// Maps model output index → error key used in prompts + UI
  static const Map<int, String> errorClassLabels = {
    0: 'correct_compression',
    1: 'hand_too_high',      // E01
    2: 'hand_too_low',       // E02
    3: 'bent_elbows',        // E05
    4: 'body_lean',          // E06
    5: 'too_shallow',        // E07
    6: 'too_deep',           // E08
    7: 'incomplete_decomp',  // E09
  };
  // NOTE: Rate errors (E10, E11) are detected via rule-based peak detection,
  // not the BiLSTM classifier. See services/pose_service.dart.

  // ── UI ───────────────────────────────────────────────────
  static const double canvasAspectRatio = 3 / 4; // portrait camera
  static const int depthGaugeBars = 20;
  static const int bpmHistoryLength = 150; // frames kept for rate calculation
}
