// web/src/components/dashboard.js
// Encapsulates all live dashboard DOM updates during a training session.
// Called by main.js on every pose frame so UI state stays out of the main file.

import { CONST } from '../utils/constants.js';

const $ = (id) => document.getElementById(id);

export class Dashboard {
  constructor() {
    // Cached element references (avoids repeated getElementById calls)
    this._bpmVal    = $('bpm-val');
    this._bpmStatus = $('bpm-status');
    this._accVal    = $('acc-val');
    this._compVal   = $('comp-val');
    this._timer     = $('timer-badge');
    this._banner    = $('feedback-banner');
    this._fbIcon    = $('fb-icon');
    this._fbText    = $('fb-text');
    this._ruleBadge = $('rule-mode-badge');

    // Compression depth gauge drawn on a small canvas overlay
    this._gaugeCanvas = null;
    this._gaugeCtx    = null;
    this._initGauge();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  setTime(secondsLeft) {
    const m = Math.floor(secondsLeft / 60);
    const s = String(secondsLeft % 60).padStart(2, '0');
    if (this._timer) {
      this._timer.textContent = `${m}:${s}`;
      this._timer.classList.toggle('timer-low', secondsLeft <= 30);
    }
  }

  // ── BPM ───────────────────────────────────────────────────────────────────

  setBpm(bpm) {
    if (!this._bpmVal) return;
    if (bpm == null) {
      this._bpmVal.textContent    = '—';
      this._bpmVal.className      = 'metric-big';
      if (this._bpmStatus) this._bpmStatus.textContent = '';
      return;
    }
    const rounded = Math.round(bpm);
    const inRange = bpm >= CONST.CPR_BPM_MIN && bpm <= CONST.CPR_BPM_MAX;
    const isSlow  = bpm < CONST.CPR_BPM_MIN;

    this._bpmVal.textContent = rounded;
    this._bpmVal.className   = `metric-big ${inRange ? 'bpm-ok' : 'bpm-warn'}`;

    if (this._bpmStatus) {
      this._bpmStatus.textContent = inRange
        ? '✓ On Target'
        : isSlow ? '↑ Too Slow' : '↓ Too Fast';
      this._bpmStatus.style.color = inRange ? 'var(--green)' : 'var(--amber)';
    }
  }

  // ── Accuracy ──────────────────────────────────────────────────────────────

  setAccuracy(ratio) {
    if (!this._accVal) return;
    const pct = Math.round(ratio * 100);
    this._accVal.textContent = `${pct}%`;
    this._accVal.className   = `metric-big ${pct >= 80 ? 'bpm-ok' : 'bpm-warn'}`;
  }

  // ── Compression count ─────────────────────────────────────────────────────

  setCompressions(count) {
    if (this._compVal) this._compVal.textContent = count;
  }

  // ── Feedback banner ───────────────────────────────────────────────────────

  /**
   * @param {'critical'|'coaching'|'positive'|'idle'} type
   * @param {string} text   Already-translated prompt text
   */
  setFeedback(type, text) {
    if (!this._banner) return;
    this._banner.className = `feedback-banner ${type}`;
    const icons = {
      critical: '⚠️',
      coaching: '💡',
      positive: '✅',
      idle:     'ℹ️',
    };
    if (this._fbIcon) this._fbIcon.textContent = icons[type] ?? 'ℹ️';
    if (this._fbText) this._fbText.textContent = text;
  }

  showRuleModeBadge(visible) {
    if (this._ruleBadge) this._ruleBadge.classList.toggle('hidden', !visible);
  }

  // ── Depth gauge (mini canvas in top-right corner of camera view) ──────────

  _initGauge() {
    const wrap = document.querySelector('.camera-wrap');
    if (!wrap) return;

    this._gaugeCanvas = document.createElement('canvas');
    this._gaugeCanvas.width  = 28;
    this._gaugeCanvas.height = 120;
    Object.assign(this._gaugeCanvas.style, {
      position:  'absolute',
      right:     '12px',
      top:       '50%',
      transform: 'translateY(-50%)',
      zIndex:    '10',
      borderRadius: '6px',
    });
    wrap.appendChild(this._gaugeCanvas);
    this._gaugeCtx = this._gaugeCanvas.getContext('2d');
  }

  /**
   * @param {number} depth   0.0–1.0 normalised compression depth
   * @param {boolean} locked  Whether elbows are locked
   */
  setDepth(depth, locked = true) {
    const ctx = this._gaugeCtx;
    if (!ctx) return;

    const W = 28, H = 120;
    ctx.clearRect(0, 0, W, H);

    // Track
    ctx.fillStyle = 'rgba(21,21,32,0.85)';
    ctx.beginPath();
    ctx.roundRect(0, 0, W, H, 6);
    ctx.fill();

    // Target zone (30%–70% of gauge = 5–6 cm range)
    const targetLo = H * 0.30, targetHi = H * 0.70;
    ctx.fillStyle = 'rgba(67,160,71,0.15)';
    ctx.fillRect(0, H - targetHi, W, targetHi - targetLo);

    // Fill bar colour
    const d = Math.max(0, Math.min(1, depth));
    const fillH = H * d;
    const color = !locked
      ? '#FF8F00'                           // amber: elbows bent
      : d < 0.30 ? '#FF8F00'               // amber: too shallow
      : d > 0.70 ? '#E53935'               // red: too deep
      : '#43A047';                          // green: good

    if (fillH > 0) {
      ctx.fillStyle = color;
      ctx.beginPath();
      ctx.roundRect(0, H - fillH, W, fillH, 4);
      ctx.fill();

      // Glow
      ctx.shadowColor  = color;
      ctx.shadowBlur   = 8;
      ctx.fillStyle    = color;
      ctx.fillRect(0, H - fillH, W, 2);
      ctx.shadowBlur   = 0;
    }

    // Target zone borders
    ctx.strokeStyle = 'rgba(67,160,71,0.35)';
    ctx.lineWidth   = 1;
    ctx.strokeRect(0, H - targetHi, W, targetHi - targetLo);
  }

  /** Reset all metrics to idle state. */
  reset() {
    this.setBpm(null);
    this.setAccuracy(0);
    this.setCompressions(0);
    this.setFeedback('idle', 'Position yourself in front of the camera...');
    this.setDepth(0);
  }
}
