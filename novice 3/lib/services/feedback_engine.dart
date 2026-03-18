// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import '../core/constants/app_constants.dart';
import '../models/session_model.dart';

/// Converts [InferenceResult] into a [FeedbackPrompt] using a
/// priority queue that prevents prompt flooding.
///
/// Priority order (highest → lowest):
///   1. not_compressing / pause_detected  — CRITICAL
///   2. rate errors (too slow / too fast) — WARNING (safety-critical per ERC 2021)
///   3. depth errors                      — WARNING
///   4. hand placement errors             — WARNING
///   5. bent elbows / body lean           — WARNING
///   6. good technique                    — INFO (positive reinforcement)
///
/// Voice prompts are gated by [AppConstants.voiceCoachingCooldownMs] to
/// avoid cognitive overload (NASA-TLX target ≤ 40 per research protocol).
class FeedbackEngine {
  FeedbackEngine();

  DateTime? _lastPromptTime;
  String _lastKey = '';

  // ── Priority mapping ─────────────────────────────────────
  static const _priority = <String, int>{
    'not_compressing':  10,
    'pause_detected':   10,
    'rate_too_slow':     8,
    'rate_too_fast':     8,
    'too_shallow':       7,
    'too_deep':          7,
    'hand_too_high':     5,
    'hand_too_low':      5,
    'bent_elbows':       4,
    'body_lean':         4,
    'incomplete_decomp': 3,
    'correct_compression': 1,
    'good':              1,
  };

  // ── Severity mapping ─────────────────────────────────────
  static FeedbackSeverity _severity(String key) {
    if (key == 'not_compressing' || key == 'pause_detected') {
      return FeedbackSeverity.critical;
    }
    if (key == 'correct_compression' || key == 'good') {
      return FeedbackSeverity.good;
    }
    return FeedbackSeverity.warning;
  }

  /// Process an [InferenceResult] and return a [FeedbackPrompt].
  ///
  /// Returns the current best prompt — callers should check
  /// [shouldSpeak] before invoking TTS.
  FeedbackPrompt process(InferenceResult result, String language) {
    final key = _resolveKey(result);
    final prompts = language == 'rw'
        ? AppConstants.promptsRw
        : AppConstants.promptsEn;
    final message = prompts[key] ?? prompts['good']!;

    return FeedbackPrompt(
      key: key,
      message: message,
      severity: _severity(key),
      issuedAt: DateTime.now(),
    );
  }

  /// Whether enough time has passed to speak a new prompt.
  /// Critical errors bypass the cooldown.
  bool shouldSpeak(FeedbackPrompt prompt) {
    if (prompt.severity == FeedbackSeverity.critical) {
      _lastPromptTime = DateTime.now();
      _lastKey = prompt.key;
      return true;
    }

    final now = DateTime.now();
    final cooldown = Duration(milliseconds: AppConstants.voiceCoachingCooldownMs);
    final sinceLastSpeak = _lastPromptTime == null
        ? const Duration(days: 1)
        : now.difference(_lastPromptTime!);

    // Don't repeat the same non-critical prompt
    if (prompt.key == _lastKey && sinceLastSpeak < cooldown * 2) return false;

    if (sinceLastSpeak >= cooldown) {
      _lastPromptTime = now;
      _lastKey = prompt.key;
      return true;
    }
    return false;
  }

  void reset() {
    _lastPromptTime = null;
    _lastKey = '';
  }

  // ── Private ──────────────────────────────────────────────

  String _resolveKey(InferenceResult result) {
    // BPM check overrides model classification
    if (result.currentBpm > 0) {
      if (result.currentBpm < AppConstants.cprMinRateBpm) return 'rate_too_slow';
      if (result.currentBpm > AppConstants.cprMaxRateBpm) return 'rate_too_fast';
    }

    final label = result.topClassLabel;

    // Map 'correct_compression' → 'good' for display
    if (label == 'correct_compression') return 'good';

    // Return model label if it has a corresponding prompt
    if (AppConstants.promptsEn.containsKey(label)) return label;

    // Fallback
    return 'good';
  }
}
