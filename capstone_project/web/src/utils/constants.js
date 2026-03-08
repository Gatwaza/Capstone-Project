// web/src/utils/constants.js
// Mirror of lib/core/constants/app_constants.dart
// Keep both files in sync when changing thresholds or prompts.

export const CONST = {
  // ── CPR Clinical Thresholds (ERC Guidelines 2021) ─────────────────────────
  CPR_BPM_MIN: 100,
  CPR_BPM_MAX: 120,
  SESSION_DURATION_S: 120,

  // ── Pose Estimation ────────────────────────────────────────────────────────
  LANDMARK_MIN_VISIBILITY: 0.60,
  WINDOW_FRAMES: 30,
  CLASSIFIER_CONFIDENCE: 0.70,
  CALIBRATION_FRAMES: 10,

  // ── BPM Detection ──────────────────────────────────────────────────────────
  PEAK_MIN_DISTANCE: 12,

  // ── Feedback Timing (ms) ───────────────────────────────────────────────────
  FEEDBACK_MIN_INTERVAL_MS: 3500,
  FEEDBACK_COOLDOWN_MS: 8000,
  ENCOURAGE_EVERY_N: 90,

  // ── Feedback Priority Levels ───────────────────────────────────────────────
  PRIORITY_CRITICAL:      1,
  PRIORITY_URGENT:        2,
  PRIORITY_COACHING:      3,
  PRIORITY_ENCOURAGEMENT: 4,

  // ── MediaPipe Landmark Indices ────────────────────────────────────────────
  // https://google.github.io/mediapipe/solutions/pose.html
  LM: {
    NOSE:            0,
    LEFT_SHOULDER:  11,
    RIGHT_SHOULDER: 12,
    LEFT_ELBOW:     13,
    RIGHT_ELBOW:    14,
    LEFT_WRIST:     15,
    RIGHT_WRIST:    16,
    LEFT_HIP:       23,
    RIGHT_HIP:      24,
    LEFT_KNEE:      25,
    RIGHT_KNEE:     26,
  },

  // ── Model Output Class Labels ──────────────────────────────────────────────
  CLASS_LABELS: [
    'correct_compression', // 0
    'wrong_hand_high',     // 1
    'wrong_hand_low',      // 2
    'bent_elbows',         // 3
    'too_shallow',         // 4
    'rate_too_slow',       // 5
    'rate_too_fast',       // 6
    'not_compressing',     // 7
  ],
};

// ── English Prompts ──────────────────────────────────────────────────────────
export const PROMPTS_EN = {
  start:
    'Place the heel of your hand on the center of the chest. ' +
    'Interlock your fingers. Lock your elbows. Begin compressions now.',
  hand_too_high:
    'Move your hands down. Place them on the center of the chest.',
  hand_too_low:
    'Move your hands up slightly to the center of the breastbone.',
  elbows_bent:
    'Straighten your arms. Lock your elbows for full compression power.',
  body_not_vertical:
    'Position yourself directly above the chest. Shoulders over hands.',
  too_shallow:
    'Press deeper. Aim for five to six centimeters.',
  rate_too_slow:
    'Speed up. Target one hundred to one hundred twenty compressions per minute.',
  rate_too_fast:
    'Slow down slightly. Aim for a steady one hundred per minute.',
  keep_going:
    'Great work. Keep compressing.',
  almost_there:
    'Fifteen seconds remaining. Keep pushing.',
  session_complete:
    'Session complete. Well done.',
  camera_position:
    'Adjust your device so your full upper body is visible.',
  great_rate:
    'Perfect rate. Keep going.',
};

// ── Kinyarwanda Prompts ──────────────────────────────────────────────────────
export const PROMPTS_RW = {
  start:
    "Shyira intoki zo hagati y'isaya. Fata hamwe umurambi. Tangira gukanda.",
  hand_too_high:
    "Manura intoki. Shyira zo hagati y'isaya.",
  hand_too_low:
    'Muzure intoki gato. Shaka hagati.',
  elbows_bent:
    'Gurura amaboko yawe yombi.',
  body_not_vertical:
    "Ityereke hejuru y'umubyimba.",
  too_shallow:
    'Kanda cyane. Gera kuri santimetero eshanu.',
  rate_too_slow:
    'Yihuta. Gukanda inshuro ijana.',
  rate_too_fast:
    'Erekeza vuba gato.',
  keep_going:
    'Biragenda neza. Komeza gukanda.',
  almost_there:
    'Vuba isi. Komeza.',
  session_complete:
    'Ituye ryarangiye. Wakoze neza.',
  camera_position:
    'Hindura telefoni.',
  great_rate:
    'Inshuro zihwanye. Komeza.',
};
