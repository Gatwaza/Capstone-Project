// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// FeedbackEngine — priority-queue voice coaching.
///
/// Key behaviours (updated):
///   1. SILENCE when technique is correct. The absence of speech IS positive
///      feedback. Only speak when there is an active error to correct.
///   2. Optional PRAISE once per streak: after [_praiseAfterCompressions]
///      consecutive correct compressions, speak one praise cue, then go
///      silent again until the next error.
///   3. Error cues obey a [_errorCooldown] so we don't repeat the same
///      correction every 200 ms. Different errors can speak sooner.
///   4. The last-key debounce only applies to error cues — good frames never
///      update _lastKey or _lastErrorTime, so the next real error after a
///      good streak speaks immediately without cooldown interference.
library;


import '../core/utils/landmark_math.dart' show HandPlacementResult;
import '../models/session_model.dart';

class FeedbackEngine {
  // Minimum gap between any two error speech cues.
  static const Duration _errorCooldown = Duration(seconds: 4);
  // Praise spoken once after this many consecutive correct compressions.
  static const int _praiseAfterCompressions = 10;

  DateTime? _lastErrorTime;
  String? _lastErrorKey;
  int _consecutiveCorrect = 0;
  bool _praisedThisStreak = false;

  /// Derives a FeedbackPrompt from the latest InferenceResult.
  /// Call once per assessed frame.
  ///
  /// [handPlacement] is computed independently of the hosted TCN model —
  /// the model only classifies rate/depth/recoil, it was never trained on
  /// hand position. LandmarkMath.assessHandPlacement2D() derives it
  /// directly from the current frame's wrist/shoulder/hip landmarks every
  /// tick — vertical position, lateral centering, and hands-together — and
  /// is checked FIRST, ahead of the model's own label: correcting hand
  /// position is the pedagogical starting point (an instructor corrects
  /// this before rate/depth), and badly-placed hands also make the
  /// model's own depth/rate reading unreliable, since its features assume
  /// compressions happening at the sternum. Pass null (the default) to
  /// skip this check entirely — e.g. when landmark confidence is too low
  /// to trust it for that frame.
  FeedbackPrompt process(
    InferenceResult result,
    String language, {
    HandPlacementResult? handPlacement,
  }) {
    // All hand-placement failure modes (too high/low, off to a side, or
    // hands spread apart instead of stacked) collapse to a single key and
    // message. Clinically the correction is the same regardless of which
    // axis drifted — get the hands back together, centered on the chest —
    // and a unified key means the voice/on-screen cue doesn't flicker
    // between different wordings as the geometry jitters frame-to-frame
    // near a threshold.
    if (handPlacement != null &&
        handPlacement != HandPlacementResult.correct &&
        handPlacement != HandPlacementResult.unknown) {
      return FeedbackPrompt(
        key: 'hand_placement',
        severity: FeedbackSeverity.critical,
        message: 'Place your hands together at the center of the chest.',
        issuedAt: DateTime.now(),
      );
    }

    final label = result.topClassLabel;

    // Map model output labels to prioritised feedback prompts.
    // Order matters: critical errors take priority over warnings.
    switch (label) {
      case 'rate_too_fast':
        return FeedbackPrompt(
          key: 'rate_too_fast',
          severity: FeedbackSeverity.critical,
          message: 'Slow down',
          issuedAt: DateTime.now(),
        );
      case 'rate_too_slow':
        return FeedbackPrompt(
          key: 'rate_too_slow',
          severity: FeedbackSeverity.warning,
          message: 'Speed up',
          issuedAt: DateTime.now(),
        );
      case 'too_shallow':
        return FeedbackPrompt(
          key: 'too_shallow',
          severity: FeedbackSeverity.critical,
          message: 'Push deeper',
          issuedAt: DateTime.now(),
        );
      case 'too_deep':
        return FeedbackPrompt(
          key: 'too_deep',
          severity: FeedbackSeverity.warning,
          message: 'Ease back',
          issuedAt: DateTime.now(),
        );
      case 'incomplete_decomp':
        return FeedbackPrompt(
          key: 'incomplete_decomp',
          severity: FeedbackSeverity.critical,
          message: 'Allow full chest recoil.',
          issuedAt: DateTime.now(),
        );
      case 'bent_elbows':
        return FeedbackPrompt(
          key: 'bent_elbows',
          severity: FeedbackSeverity.warning,
          message: 'Lock your elbows',
          issuedAt: DateTime.now(),
        );
      case 'body_lean':
        return FeedbackPrompt(
          key: 'body_lean',
          severity: FeedbackSeverity.warning,
          message: 'Stay upright',
          issuedAt: DateTime.now(),
        );
      default:
        return FeedbackPrompt(
          key: 'correct_compression',
          severity: FeedbackSeverity.good,
          message: '',
          issuedAt: DateTime.now(),
        );
    }
  }

  /// Returns true only when TTS should fire.
  ///
  /// Silence-on-correct behaviour:
  ///   • FeedbackSeverity.good → never speaks (except one optional praise
  ///     cue per sustained-correct streak).
  ///   • Errors speak immediately after the cooldown window, never blocked
  ///     by prior good frames.
  bool shouldSpeak(FeedbackPrompt prompt) {
    // ── Correct technique path ──────────────────────────────────────────────
    if (prompt.severity == FeedbackSeverity.good) {
      _consecutiveCorrect++;

      // Speak ONE praise cue after a sustained correct streak, then silence.
      if (!_praisedThisStreak && _consecutiveCorrect >= _praiseAfterCompressions) {
        _praisedThisStreak = true;
        // Note: we deliberately do NOT update _lastErrorTime/_lastErrorKey
        // here — this praise cue must not delay the next error correction.
        return true;
      }
      return false; // silence while doing well
    }

    // ── Error path ──────────────────────────────────────────────────────────
    _consecutiveCorrect = 0;
    _praisedThisStreak = false;

    final now = DateTime.now();
    final sinceLastError = _lastErrorTime == null
        ? const Duration(days: 1)
        : now.difference(_lastErrorTime!);

    // Respect cooldown between consecutive error cues.
    if (sinceLastError < _errorCooldown) return false;

    // Don't repeat the exact same error within a longer window (2× cooldown),
    // but DO allow a different error to speak after just one cooldown.
    if (prompt.key == _lastErrorKey &&
        sinceLastError < _errorCooldown * 2) {
      return false;
    }

    _lastErrorKey = prompt.key;
    _lastErrorTime = now;
    return true;
  }

  void reset() {
    _lastErrorTime = null;
    _lastErrorKey = null;
    _consecutiveCorrect = 0;
    _praisedThisStreak = false;
  }
}