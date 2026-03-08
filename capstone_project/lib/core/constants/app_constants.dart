class AppConstants {
  AppConstants._();

  static const String appName = 'CPR AI Coach';

  // CPR Clinical Thresholds (ERC Guidelines 2021)
  static const int cprBpmMin = 100;
  static const int cprBpmMax = 120;
  static const int sessionDurationSeconds = 120;

  // Pose Estimation
  static const double landmarkMinVisibility = 0.60;
  static const int classifierWindowFrames = 30;
  static const double classifierConfidenceThreshold = 0.70;
  static const int baselineCalibrationFrames = 10;

  // BPM Detection
  static const int peakMinDistanceFrames = 12;

  // Feedback Timing (ms)
  static const int feedbackMinIntervalMs = 3500;
  static const int feedbackCooldownMs = 8000;
  static const int encourageEveryNFrames = 90;

  // Feedback Priority Levels
  static const int priorityCritical = 1;
  static const int priorityUrgent = 2;
  static const int priorityCoaching = 3;
  static const int priorityEncouragement = 4;

  // Model Output Classes
  static const List<String> classLabels = [
    'correct_compression',
    'wrong_hand_high',
    'wrong_hand_low',
    'bent_elbows',
    'too_shallow',
    'rate_too_slow',
    'rate_too_fast',
    'not_compressing',
  ];

  // Prompt keys
  static const String promptStart        = 'start';
  static const String promptHandHigh     = 'hand_too_high';
  static const String promptHandLow      = 'hand_too_low';
  static const String promptElbowsBent   = 'elbows_bent';
  static const String promptBodyLean     = 'body_not_vertical';
  static const String promptTooShallow   = 'too_shallow';
  static const String promptRateSlow     = 'rate_too_slow';
  static const String promptRateFast     = 'rate_too_fast';
  static const String promptKeepGoing    = 'keep_going';
  static const String promptAlmostThere  = 'almost_there';
  static const String promptComplete     = 'session_complete';
  static const String promptCameraAdjust = 'camera_position';
  static const String promptGreatRate    = 'great_rate';

  static const Map<String, String> promptsEn = {
    'start': 'Place the heel of your hand on the center of the chest. Interlock your fingers. Lock your elbows. Begin compressions now.',
    'hand_too_high': 'Move your hands down. Place them on the center of the chest.',
    'hand_too_low': 'Move your hands up slightly to the center of the breastbone.',
    'elbows_bent': 'Straighten your arms. Lock your elbows for full compression power.',
    'body_not_vertical': 'Position yourself directly above the chest. Shoulders over hands.',
    'too_shallow': 'Press deeper. Aim for five to six centimeters.',
    'rate_too_slow': 'Speed up. Target one hundred to one hundred twenty compressions per minute.',
    'rate_too_fast': 'Slow down slightly. Aim for a steady one hundred per minute.',
    'keep_going': 'Great work. Keep compressing.',
    'almost_there': 'Fifteen seconds remaining. Keep pushing.',
    'session_complete': 'Session complete. Well done.',
    'camera_position': 'Adjust your device so your full upper body is visible.',
    'great_rate': 'Perfect rate. Keep going.',
  };

  static const Map<String, String> promptsRw = {
    'start': 'Shyira intoki zo hagati y\'isaya. Fata hamwe umurambi. Tangira gukanda.',
    'hand_too_high': 'Manura intoki. Shyira zo hagati y\'isaya.',
    'hand_too_low': 'Muzure intoki gato.',
    'elbows_bent': 'Gurura amaboko yawe yombi.',
    'body_not_vertical': 'Ityereke hejuru y\'umubyimba.',
    'too_shallow': 'Kanda cyane. Gera kuri santimetero eshanu.',
    'rate_too_slow': 'Yihuta. Gukanda inshuro ijana.',
    'rate_too_fast': 'Erekeza vuba gato.',
    'keep_going': 'Biragenda neza. Komeza gukanda.',
    'almost_there': 'Vuba isi. Komeza.',
    'session_complete': 'Ituye ryarangiye. Wakoze neza.',
    'camera_position': 'Hindura telefoni.',
    'great_rate': 'Inshuro zihwanye. Komeza.',
  };

  static const String modelAssetPath = 'assets/models/cpr_classifier.tflite';
  static const String driveFolderName = 'CPR_Coach_Sessions';
  static const double cardBorderRadius = 16.0;
  static const double screenPadding = 16.0;
}
