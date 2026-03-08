// web/src/services/ttsService.js
// Priority-queued TTS using Web Speech API (EN + RW fallback)
// and optional Umuganda HTTP TTS server for Kinyarwanda.
// Mirrors the behaviour of lib/services/tts_service.dart.

import { CONST, PROMPTS_EN, PROMPTS_RW } from '../utils/constants.js';

class QueueItem {
  constructor(key, priority) {
    this.key = key;
    this.priority = priority;
    this.ts = Date.now();
  }
}

export class TTSService {
  constructor() {
    this._lang = 'en';
    this._queue = [];
    this._speaking = false;
    this._lastSpoken = {};   // { key: timestamp }
    this._globalLast = 0;
    this._synth = window.speechSynthesis ?? null;
    this._umugandaUrl = 'http://127.0.0.1:5002/api/tts';
    this._audioCtx = null;   // Created on first Umuganda response
  }

  setLang(lang) {
    this._lang = lang;
    this.stop();
  }

  /**
   * Add a feedback cue to the priority queue.
   * Lower priority number = higher urgency (mirrors Dart constants).
   */
  enqueue(key, priority) {
    const last = this._lastSpoken[key] ?? 0;
    if (Date.now() - last < CONST.FEEDBACK_COOLDOWN_MS) return;

    // Critical prompts flush lower-priority items
    if (priority === CONST.PRIORITY_CRITICAL) {
      this._queue = this._queue.filter(i => i.priority <= CONST.PRIORITY_CRITICAL);
    }

    this._queue.push(new QueueItem(key, priority));
    // Sort: ascending priority, then FIFO within same priority
    this._queue.sort((a, b) =>
      a.priority !== b.priority ? a.priority - b.priority : a.ts - b.ts
    );

    if (!this._speaking) this._processQueue();
  }

  stop() {
    this._synth?.cancel();
    this._queue = [];
    this._speaking = false;
  }

  _processQueue() {
    if (this._speaking || this._queue.length === 0) return;
    const elapsed = Date.now() - this._globalLast;
    if (elapsed < CONST.FEEDBACK_MIN_INTERVAL_MS) {
      setTimeout(() => this._processQueue(), CONST.FEEDBACK_MIN_INTERVAL_MS - elapsed);
      return;
    }
    const next = this._queue.shift();
    this._speak(next.key);
  }

  async _speak(key) {
    const text = this._resolveText(key);
    if (!text) { this._processQueue(); return; }

    this._speaking = true;
    this._lastSpoken[key] = Date.now();
    this._globalLast = Date.now();

    // Try Umuganda HTTP TTS for Kinyarwanda
    if (this._lang === 'rw') {
      const ok = await this._speakUmuganda(text);
      if (ok) return;
      // Falls through to Web Speech API with rw-RW language tag
    }

    this._speakWebSpeech(text);
  }

  _speakWebSpeech(text) {
    if (!this._synth) {
      this._speaking = false;
      this._processQueue();
      return;
    }
    const utt = new SpeechSynthesisUtterance(text);
    utt.lang  = this._lang === 'rw' ? 'rw-RW' : 'en-US';
    utt.rate  = 0.88;
    utt.pitch = 1.0;
    utt.volume = 1.0;

    utt.onend = () => {
      this._speaking = false;
      this._processQueue();
    };
    utt.onerror = () => {
      this._speaking = false;
      this._processQueue();
    };

    // Chrome bug: speechSynthesis hangs on long idle. Cancel first.
    this._synth.cancel();
    this._synth.speak(utt);
  }

  async _speakUmuganda(text) {
    try {
      const resp = await fetch(this._umugandaUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, speaker_id: 0 }),
        signal: AbortSignal.timeout(3000),
      });
      if (!resp.ok) return false;

      const buffer = await resp.arrayBuffer();
      if (!this._audioCtx) {
        this._audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      }
      const audioBuffer = await this._audioCtx.decodeAudioData(buffer);
      const source = this._audioCtx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(this._audioCtx.destination);
      source.onended = () => {
        this._speaking = false;
        this._processQueue();
      };
      source.start(0);
      return true;
    } catch (_) {
      // Umuganda server not running — fall back to Web Speech API
      return false;
    }
  }

  _resolveText(key) {
    const map = this._lang === 'rw' ? PROMPTS_RW : PROMPTS_EN;
    return map[key] ?? PROMPTS_EN[key] ?? null;
  }
}
