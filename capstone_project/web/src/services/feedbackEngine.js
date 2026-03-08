// web/src/services/feedbackEngine.js
// Real-time CPR feedback engine — mirrors lib/services/feedback_engine.dart.
// Stateless between sessions; call reset() at each session start.
//
// Priority levels (lower = more urgent):
//   1 CRITICAL   — wrong hand / immediate danger
//   2 URGENT     — bent elbows
//   3 COACHING   — depth / rate
//   4 POSITIVE   — encouragement

import { CONST } from '../utils/constants.js';

// Minimum ms between any two TTS prompts (applied externally by TTSService).
// FeedbackEngine itself enforces per-key cooldowns below.
const KEY_COOLDOWN_MS = 8000;

export class FeedbackEngine {
  constructor({ onFeedback }) {
    // onFeedback(key, priority, uiType)
    // uiType: 'critical' | 'coaching' | 'positive' | 'idle'
    this._onFeedback = onFeedback;
    this._lastFired   = {};       // key -> timestamp
    this._frameCount  = 0;
    this._correctFrames = 0;
    this._consecutiveCorrect = 0;
    this._totalCompressions  = 0;

    // BPM tracking
    this._wristYBuffer = [];
    this._bpmHistory   = [];
    this._currentBpm   = null;
    this._prevWristY   = 0.5;
    this._prevVelY     = 0;

    // Calibration
    this._calibrated       = false;
    this._calibFrames      = 0;
    this._baselineWristY   = 0.5;
    this._refShoulderWidth = 0.3;

    // Rolling classification window for majority vote
    this._recentLabels = [];
  }

  // ── Accessors ─────────────────────────────────────────────────────────────

  get calibrated()         { return this._calibrated; }
  get frameCount()         { return this._frameCount; }
  get correctFrames()      { return this._correctFrames; }
  get totalCompressions()  { return this._totalCompressions; }
  get currentBpm()         { return this._currentBpm; }
  get wristYBuffer()       { return this._wristYBuffer; }
  get baselineWristY()     { return this._baselineWristY; }
  get refShoulderWidth()   { return this._refShoulderWidth; }
  get prevWristY()         { return this._prevWristY; }
  get prevVelY()           { return this._prevVelY; }

  accuracy() {
    return this._frameCount > 0 ? this._correctFrames / this._frameCount : 0;
  }

  rateScore() {
    if (!this._currentBpm) return 0.5;
    const inRange = this._currentBpm >= CONST.CPR_BPM_MIN &&
                    this._currentBpm <= CONST.CPR_BPM_MAX;
    if (inRange) return 1.0;
    return Math.max(0, 1.0 - Math.abs(this._currentBpm - 110) / 30);
  }

  avgBpm() {
    if (!this._bpmHistory.length) return null;
    return this._bpmHistory.reduce((a, b) => a + b, 0) / this._bpmHistory.length;
  }

  /** 0–1 normalised compression depth for the gauge widget. */
  depthNorm(wristY) {
    if (!this._calibrated || wristY == null) return 0;
    const disp = Math.abs(wristY - this._baselineWristY);
    return Math.min(1, disp / (this._refShoulderWidth + 1e-8));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  reset() {
    this._lastFired           = {};
    this._frameCount          = 0;
    this._correctFrames       = 0;
    this._consecutiveCorrect  = 0;
    this._totalCompressions   = 0;
    this._wristYBuffer        = [];
    this._bpmHistory          = [];
    this._currentBpm          = null;
    this._prevWristY          = 0.5;
    this._prevVelY            = 0;
    this._calibrated          = false;
    this._calibFrames         = 0;
    this._baselineWristY      = 0.5;
    this._refShoulderWidth    = 0.3;
    this._recentLabels        = [];
  }

  // ── Main frame processor ──────────────────────────────────────────────────

  /**
   * Process a single pose frame.
   * @param {Object} params
   * @param {Array|null}  params.landmarks   MediaPipe pose landmarks (33 items) or null
   * @param {number[]|null} params.features  12-dim feature vector from landmarkMath, or null
   * @param {Object|null} params.inference   Result from InferenceService.run(), or null
   * @param {number|null} params.wristY      Normalised mean wrist Y
   * @param {number|null} params.sw          Shoulder width (normalised)
   */
  processFrame({ landmarks, features, inference, wristY, sw }) {
    this._frameCount++;

    if (!landmarks) {
      if (this._frameCount % 30 === 0) {
        this._fire('camera_position', CONST.PRIORITY_URGENT, 'coaching');
      }
      return;
    }

    // ── Calibration (first CALIBRATION_FRAMES frames) ──────────────────────
    if (!this._calibrated) {
      this._calibFrames++;
      if (this._calibFrames === 1 && wristY != null) {
        this._baselineWristY   = wristY;
        this._refShoulderWidth = sw ?? 0.3;
      }
      if (this._calibFrames >= CONST.CALIBRATION_FRAMES) this._calibrated = true;
      return;
    }

    // ── BPM / compression tracking ────────────────────────────────────────
    if (wristY != null) {
      this._wristYBuffer.push(wristY);
      if (this._wristYBuffer.length > 300) this._wristYBuffer.shift();

      // Count compressions via velocity sign change (down → up)
      const vel = wristY - this._prevWristY;
      if (this._prevVelY < -0.005 && vel >= 0) this._totalCompressions++;
      this._prevVelY = vel;
      this._prevWristY = wristY;
    }

    // ── ML classification majority vote ───────────────────────────────────
    let label = null;
    if (inference) {
      this._recentLabels.push(inference.label);
      if (this._recentLabels.length > 5) this._recentLabels.shift();
      label = this._majorityVote(this._recentLabels);
    }

    // ── Correct frames & encouragement ───────────────────────────────────
    if (label === 'correct_compression') {
      this._correctFrames++;
      this._consecutiveCorrect++;
      if (this._consecutiveCorrect === CONST.ENCOURAGE_EVERY_N) {
        this._consecutiveCorrect = 0;
        this._fire('keep_going', CONST.PRIORITY_ENCOURAGEMENT, 'positive');
      }
    } else {
      this._consecutiveCorrect = 0;
    }

    // ── Update smoothed BPM ───────────────────────────────────────────────
    // Caller passes pre-computed BPM from estimateBpm(); we smooth it here.
    // (To avoid circular deps, BPM estimation stays in main.js / caller.)

    // ── Priority rule evaluation (P1 → P2 → P3) ──────────────────────────
    this._evalRules(label);
  }

  /**
   * Feed a freshly computed BPM sample into the history.
   * Call this from main.js after estimateBpm() returns a non-null value.
   */
  pushBpm(bpm) {
    this._bpmHistory.push(bpm);
    if (this._bpmHistory.length > 10) this._bpmHistory.shift();
    this._currentBpm = this._bpmHistory.reduce((a, b) => a + b, 0) / this._bpmHistory.length;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  _evalRules(label) {
    // P1 — Hand placement (critical; interrupts everything)
    if (label === 'wrong_hand_high') {
      this._fire('hand_too_high', CONST.PRIORITY_CRITICAL, 'critical'); return;
    }
    if (label === 'wrong_hand_low') {
      this._fire('hand_too_low',  CONST.PRIORITY_CRITICAL, 'critical'); return;
    }

    // P2 — Body mechanics (urgent)
    if (label === 'bent_elbows') {
      this._fire('elbows_bent',   CONST.PRIORITY_URGENT,   'coaching'); return;
    }

    // P3 — Depth / rate (coaching)
    if (label === 'too_shallow') {
      this._fire('too_shallow',   CONST.PRIORITY_COACHING, 'coaching');
    }

    if (this._currentBpm != null) {
      if (this._currentBpm < CONST.CPR_BPM_MIN) {
        this._fire('rate_too_slow', CONST.PRIORITY_COACHING, 'coaching');
      } else if (this._currentBpm > CONST.CPR_BPM_MAX) {
        this._fire('rate_too_fast', CONST.PRIORITY_COACHING, 'coaching');
      } else if (this._frameCount % 60 === 0) {
        this._fire('great_rate',    CONST.PRIORITY_ENCOURAGEMENT, 'positive');
      }
    }
  }

  _fire(key, priority, uiType) {
    const now  = Date.now();
    const last = this._lastFired[key] ?? 0;
    if (now - last < KEY_COOLDOWN_MS) return;
    this._lastFired[key] = now;
    this._onFeedback(key, priority, uiType);
  }

  _majorityVote(labels) {
    if (!labels.length) return null;
    const counts = {};
    for (const l of labels) counts[l] = (counts[l] || 0) + 1;
    return Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
  }

  // ── Session summary ───────────────────────────────────────────────────────

  buildSession({ id, startedAt, durationSeconds, language }) {
    return {
      id,
      startedAt:           startedAt,
      endedAt:             new Date().toISOString(),
      durationSeconds,
      avgBpm:              this.avgBpm(),
      rateAdherenceScore:  this.rateScore(),
      postureScore:        this.accuracy(),
      overallScore:        this.accuracy() * 0.6 + this.rateScore() * 0.4,
      totalCompressions:   this._totalCompressions,
      language,
      events:              [],
    };
  }
}
