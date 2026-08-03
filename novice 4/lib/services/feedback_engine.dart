// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// FeedbackEngine — priority-queue voice coaching.
///
/// POST-DEFENSE REVISION (adaptive coaching):
/// Panel feedback (defense, 2026) identified that spoken/on-screen coaching
/// was generic and did not use the model's own predicted values — the same
/// fixed phrase played back regardless of how far off technique was, and
/// hand-placement corrections kept repeating once hands were already
/// correctly placed. The hand-placement repeat was traced to a geometry
/// bug in LandmarkMath.assessHandPlacement2D (documented and fixed there —
/// see the FIX comment in that file). This revision addresses the
/// "generic feedback" half of the criticism:
///
///   1. Rate and depth corrections are now driven directly by the model's
///      own numeric outputs (InferenceResult.currentBpm /
///      .estimatedDepthCm) rather than only the categorical topClassLabel,
///      and are split into MILD/SEVERE bands so a rescuer who is
///      dramatically too fast/shallow gets a visibly and audibly different
///      cue than one who is only slightly off. This numeric check runs
///      even when the model's own label still says "correct" — a stale or
///      low-confidence label no longer silently overrides what the
///      predicted rate/depth values themselves say.
///   2. The on-screen banner message (FeedbackPrompt.message) now always
///      includes the actual measured value (e.g. "you're at 138 bpm"),
///      not just a category name — the previous version showed the same
///      static sentence for every instance of a given error.
///   3. Voice cues (looked up by FeedbackPrompt.key via
///      TtsService.speakKey) now also vary by band for EN/RW, since a
///      pre-written bilingual phrase set can't safely synthesize live
///      numbers in Kinyarwanda — banding is the adaptive step that's safe
///      to do with a fixed, clinician-reviewable phrase set.
///
/// Key behaviours (unchanged from before):
///   - SILENCE when technique is correct. The absence of speech IS
///     positive feedback. Only speak when there is an active error.
///   - Optional PRAISE once per streak: after [_praiseAfterCompressions]
///     consecutive correct compressions, speak one praise cue, then go
///     silent again until the next error.
///   - Error cues obey a [_errorCooldown] so we don't repeat the same
///     correction every 200 ms. Different errors can speak sooner.
///   - The last-key debounce only applies to error cues — good frames
///     never update _lastKey/_lastErrorTime, so the next real error after
///     a good streak speaks immediately without cooldown interference.
library;

import '../core/constants/app_constants.dart';
import '../core/utils/landmark_math.dart' show HandPlacementResult;
import '../models/session_model.dart';

class FeedbackEngine {
  // Minimum gap between any two error speech cues.
  static const Duration _errorCooldown = Duration(seconds: 4);
  // Praise spoken once after this many consecutive correct compressions.
  static const int _praiseAfterCompressions = 10;

  // ── Severity-band thresholds ───────────────────────────────────────────
  // "Mild" bands sit between the ERC-correct range and these outer bounds;
  // beyond them the deviation is large enough that a rescuer needs a more
  // urgent cue rather than the same gentle nudge. Chosen as roughly 1.5–2x
  // the width of the correct band on each side — a starting point for the
  // pilot, not a clinically validated cut-point.
  static const double _rateSevereSlowBpm = 80;
  static const double _rateSevereFastBpm = 140;
  static const double _depthSevereShallowCm = 3.5;
  static const double _depthSevereDeepCm = 7.5;

  DateTime? _lastErrorTime;
  String? _lastErrorKey;
  int _consecutiveCorrect = 0;
  bool _praisedThisStreak = false;
  // The very first prompt of a session always speaks, whatever its
  // severity — a trainee who just started should get immediate
  // confirmation ("you're doing this right" or "fix this now") rather
  // than waiting out a 10-compression streak or an error cooldown that
  // assumes a prior cue already fired.
  bool _hasSpokenOnce = false;

  /// Derives a FeedbackPrompt from the latest InferenceResult.
  /// Call once per assessed frame.
  ///
  /// [handPlacement] is computed independently of the hosted TCN model —
  /// the model only classifies rate/depth/recoil, it was never trained on
  /// hand position. LandmarkMath.assessHandPlacement2D() derives it
  /// directly from the current frame's wrist/shoulder/hip landmarks every
  /// tick and is checked FIRST, ahead of everything else: correcting hand
  /// position is the pedagogical starting point, and badly-placed hands
  /// also make the model's own depth/rate reading unreliable. Pass null
  /// (the default) to skip this check — e.g. when landmark confidence is
  /// too low to trust it for that frame.
  FeedbackPrompt process(
    InferenceResult result,
    String language, {
    HandPlacementResult? handPlacement,
  }) {
    final now = DateTime.now();

    // ── 1. Hand placement (geometry-driven, model-independent) ──────────
    if (handPlacement != null &&
        handPlacement != HandPlacementResult.correct &&
        handPlacement != HandPlacementResult.unknown) {
      return FeedbackPrompt(
        key: 'hand_placement',
        severity: FeedbackSeverity.critical,
        message: 'Place your hands together at the center of the chest.',
        issuedAt: now,
      );
    }

    final label = result.topClassLabel;

    // ── 2. Explicit "not started" signal ─────────────────────────────────
    // Distinct from the scaffolding states below: this is an explicit
    // model/session signal that compressions have not begun at all
    // (e.g. hands placed but no motion registered for several seconds),
    // and always takes priority over a numeric rate reading of 0, which
    // on its own is ambiguous between "not compressing" and "just started".
    if (label == 'not_compressing') {
      return FeedbackPrompt(
        key: 'not_compressing',
        severity: FeedbackSeverity.critical,
        message: 'Hands on the chest — start compressing now.',
        issuedAt: now,
      );
    }

    // ── 3. Scaffolding states — no real assessment has happened yet ─────
    // These are NOT model assessments, so they must never be treated as
    // 'correct technique' (silence) or blended in with real rate/depth/
    // recoil errors. `info` severity still speaks (see shouldSpeak) so a
    // novice gets guidance from frame one, but stays visually distinct
    // (see FeedbackBanner) so it never reads as a fault.
    switch (label) {
      case 'no_compression_motion':
        return FeedbackPrompt(
          key: 'no_compression_motion',
          severity: FeedbackSeverity.info,
          message: 'Start compressions: push hard and fast on the '
              'center of the chest.',
          issuedAt: now,
        );
      case 'awaiting_compressions':
        return FeedbackPrompt(
          key: 'awaiting_compressions',
          severity: FeedbackSeverity.info,
          message: 'Good — keep going. Scoring your technique now.',
          issuedAt: now,
        );
      case 'model_unavailable':
        return FeedbackPrompt(
          key: 'model_unavailable',
          severity: FeedbackSeverity.info,
          message: "Reconnecting to the coach — keep practicing, "
              "you'll still be able to review your form.",
          issuedAt: now,
        );
    }

    // ── 4. Numeric rate check — driven by the model's own currentBpm, ───
    // not just its categorical label. This runs even when topClassLabel
    // says the compression was correct, so a stale/low-confidence label
    // can't mask a rate that the model's own bpm estimate shows is out of
    // range. Depth is checked after rate (rate is the more time-critical
    // correction — ERC guidance prioritises "push fast" before "push
    // hard" when both are off).
    final bpm = result.currentBpm;
    if (bpm > 0) {
      if (bpm < AppConstants.cprMinRateBpm) {
        final severe = bpm < _rateSevereSlowBpm;
        return FeedbackPrompt(
          key: severe ? 'rate_too_slow_severe' : 'rate_too_slow',
          severity: severe ? FeedbackSeverity.critical : FeedbackSeverity.warning,
          message: severe
              ? "Way too slow — ${bpm.round()} bpm. Push hard and fast, "
                  "aim for 100 to 120 per minute."
              : "Speed up a little — you're at ${bpm.round()} bpm, "
                  "aim for 100 to 120.",
          issuedAt: now,
        );
      }
      if (bpm > AppConstants.cprMaxRateBpm) {
        final severe = bpm > _rateSevereFastBpm;
        return FeedbackPrompt(
          key: severe ? 'rate_too_fast_severe' : 'rate_too_fast',
          severity: severe ? FeedbackSeverity.critical : FeedbackSeverity.warning,
          message: severe
              ? "Way too fast — ${bpm.round()} bpm. Slow right down, "
                  "aim for 100 to 120 per minute."
              : "Ease back — you're at ${bpm.round()} bpm, "
                  "aim for 100 to 120.",
          issuedAt: now,
        );
      }
    }

    // ── 5. Numeric depth check — same reasoning as rate, using the ──────
    // model's own estimatedDepthCm.
    final depth = result.estimatedDepthCm;
    if (depth > 0) {
      if (depth < AppConstants.cprMinDepthCm) {
        final severe = depth < _depthSevereShallowCm;
        return FeedbackPrompt(
          key: severe ? 'too_shallow_severe' : 'too_shallow',
          severity: FeedbackSeverity.critical,
          message: severe
              ? "Much too shallow — about ${depth.toStringAsFixed(1)}cm. "
                  "Push hard, aim for 5 to 6 centimeters."
              : "Push a little deeper — about ${depth.toStringAsFixed(1)}cm "
                  "now, aim for 5 to 6 centimeters.",
          issuedAt: now,
        );
      }
      if (depth > AppConstants.cprMaxDepthCm) {
        final severe = depth > _depthSevereDeepCm;
        return FeedbackPrompt(
          key: severe ? 'too_deep_severe' : 'too_deep',
          severity: severe ? FeedbackSeverity.critical : FeedbackSeverity.warning,
          message: severe
              ? "Much too deep — about ${depth.toStringAsFixed(1)}cm. "
                  "Ease off, aim for 5 to 6 centimeters."
              : "Ease back slightly — about ${depth.toStringAsFixed(1)}cm "
                  "now, 5 to 6 centimeters is enough.",
          issuedAt: now,
        );
      }
    }

    // ── 6. Remaining categorical corrections (posture, recoil) — these ──
    // have no equivalent live numeric signal in InferenceResult today, so
    // they stay label-driven.
    switch (label) {
      case 'incomplete_decomp':
        return FeedbackPrompt(
          key: 'incomplete_decomp',
          severity: FeedbackSeverity.critical,
          message: 'Allow full chest recoil — let it come all the way back up.',
          issuedAt: now,
        );
      case 'bent_elbows':
        return FeedbackPrompt(
          key: 'bent_elbows',
          severity: FeedbackSeverity.warning,
          message: 'Lock your elbows. Push straight down from your shoulders.',
          issuedAt: now,
        );
      case 'body_lean':
        return FeedbackPrompt(
          key: 'body_lean',
          severity: FeedbackSeverity.warning,
          message: 'Stay upright — shoulders directly over your hands.',
          issuedAt: now,
        );
    }

    // ── 7. Nothing wrong ──────────────────────────────────────────────────
    return FeedbackPrompt(
      key: 'good',
      severity: FeedbackSeverity.good,
      message: 'Good rhythm — keep that up.',
      issuedAt: now,
    );
  }

  /// Returns true only when TTS should fire.
  ///
  /// Silence-on-correct behaviour:
  ///   • FeedbackSeverity.good → never speaks (except one optional praise
  ///     cue per sustained-correct streak).
  ///   • Errors speak immediately after the cooldown window, never blocked
  ///     by prior good frames. A *severe* band bypasses the "same key"
  ///     repeat suppression (but still respects the base cooldown) so a
  ///     rescuer who is dangerously off doesn't wait out a longer window
  ///     to be told again.
  bool shouldSpeak(FeedbackPrompt prompt) {
    if (!_hasSpokenOnce) {
      _hasSpokenOnce = true;
      if (prompt.severity != FeedbackSeverity.good) {
        _lastErrorKey = prompt.key;
        _lastErrorTime = DateTime.now();
      }
      return true;
    }

    // ── Correct technique path ─────────────────────────────────────────
    if (prompt.severity == FeedbackSeverity.good) {
      _consecutiveCorrect++;

      // Speak ONE praise cue after a sustained correct streak, then silence.
      if (!_praisedThisStreak && _consecutiveCorrect >= _praiseAfterCompressions) {
        _praisedThisStreak = true;
        // Deliberately do NOT update _lastErrorTime/_lastErrorKey here —
        // this praise cue must not delay the next error correction.
        return true;
      }
      return false; // silence while doing well
    }

    // ── Error path ────────────────────────────────────────────────────
    _consecutiveCorrect = 0;
    _praisedThisStreak = false;

    final now = DateTime.now();
    final sinceLastError = _lastErrorTime == null
        ? const Duration(days: 1)
        : now.difference(_lastErrorTime!);

    // Respect cooldown between consecutive error cues.
    if (sinceLastError < _errorCooldown) return false;

    final isSevere = prompt.key.endsWith('_severe') ||
        prompt.severity == FeedbackSeverity.critical;

    // Don't repeat the exact same error within a longer window (2x
    // cooldown), but DO allow a different error — or the same error
    // escalating into its severe band — to speak sooner.
    if (prompt.key == _lastErrorKey &&
        sinceLastError < _errorCooldown * 2 &&
        !isSevere) {
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
    _hasSpokenOnce = false;
  }
}