// web/src/main.js — CPR AI Coach · Web App Entry Point
// Wires PoseService → FeedbackEngine → TTSService → Dashboard → SessionLogger

import { PoseService }      from './services/poseService.js';
import { InferenceService } from './services/inferenceService.js';
import { FeedbackEngine }   from './services/feedbackEngine.js';
import { TTSService }       from './services/ttsService.js';
import { SessionLogger }    from './services/sessionLogger.js';
import { DriveService }     from './services/driveService.js';
import { Dashboard }        from './components/dashboard.js';
import { drawPose, drawNoPose } from './components/poseOverlay.js';
import { CONST, PROMPTS_EN, PROMPTS_RW } from './utils/constants.js';
import {
  featureVector,
  meanWristY,
  shoulderWidth,
  estimateBpm,
} from './utils/landmarkMath.js';

// ── DOM helpers ───────────────────────────────────────────────────────────────
const $ = (id) => document.getElementById(id);
const SCREEN_IDS = [
  'home-screen', 'demo-screen',
  'training-screen', 'results-screen', 'history-screen',
];
function showScreen(id) {
  SCREEN_IDS.forEach((s) =>
    document.getElementById(s)?.classList.toggle('hidden', s !== id)
  );
}

// ── Service instances ─────────────────────────────────────────────────────────
const tts       = new TTSService();
const inference = new InferenceService();
const logger    = new SessionLogger();
const drive     = new DriveService();
const dashboard = new Dashboard();

let poseService = null;

// ── App state ─────────────────────────────────────────────────────────────────
let lang            = 'en';
let sessionActive   = false;
let sessionTimer    = null;
let timeLeft        = CONST.SESSION_DURATION_S;
let sessionStartTs  = null;
let currentSession  = null;
let engine          = null;

// ── Boot ──────────────────────────────────────────────────────────────────────
async function init() {
  setProgress(5, 'Loading TensorFlow.js...');
  await inference.load((p) => setProgress(5 + p * 40, 'Loading AI model...'));

  setProgress(50, 'Loading pose estimation model...');
  poseService = new PoseService({ onResults: onPoseResults });
  try {
    await poseService.init((p) => setProgress(50 + p * 45, 'Loading pose model...'));
  } catch (err) {
    setProgress(0, '⚠ Error: ' + err.message);
    console.error('[Boot] Pose init failed:', err);
    return;
  }

  await logger.preload();

  setProgress(100, 'Ready!');
  await sleep(400);
  $('loading-overlay').style.display = 'none';

  if (!inference.loaded) {
    $('model-notice') && ($('model-notice').style.display = 'block');
    $('stat-mode') && ($('stat-mode').textContent = 'Rules');
  } else {
    if ($('stat-mode')) {
      $('stat-mode').textContent = 'AI';
      $('stat-mode').style.color = 'var(--green)';
    }
  }

  await refreshHomeStats();
  showScreen('home-screen');
  bindEvents();
}

// ── Event binding ─────────────────────────────────────────────────────────────
function bindEvents() {
  $('start-btn')?.addEventListener('click',   startSession);
  $('stop-btn')?.addEventListener('click',    () => endSession());
  $('demo-btn')?.addEventListener('click',    () => { initDemo(); showScreen('demo-screen'); });
  $('history-btn')?.addEventListener('click', () => { loadHistory(); showScreen('history-screen'); });
  $('retry-btn')?.addEventListener('click',   startSession);
  $('drive-btn')?.addEventListener('click',   uploadToDrive);
  $('dl-btn')?.addEventListener('click',      downloadSession);
  $('lang-btn')?.addEventListener('click',    toggleLang);
  $('demo-next')?.addEventListener('click',   demoNext);
  $('demo-prev')?.addEventListener('click',   demoPrev);

  document.querySelectorAll('.back-btn[data-target]').forEach((btn) => {
    btn.addEventListener('click', () => showScreen(btn.dataset.target + '-screen'));
  });
}

// ── Language ──────────────────────────────────────────────────────────────────
function toggleLang() {
  lang = lang === 'en' ? 'rw' : 'en';
  $('lang-btn') && ($('lang-btn').textContent = lang === 'en' ? '🇬🇧 EN' : '🇷🇼 RW');
  tts.setLang(lang);
}

function t(key) {
  const map = lang === 'rw' ? PROMPTS_RW : PROMPTS_EN;
  return map[key] ?? PROMPTS_EN[key] ?? key;
}

// ── Session lifecycle ─────────────────────────────────────────────────────────
async function startSession() {
  showScreen('training-screen');
  sessionActive  = true;
  timeLeft       = CONST.SESSION_DURATION_S;
  sessionStartTs = Date.now();
  currentSession = null;

  engine = new FeedbackEngine({
    onFeedback: (key, priority, uiType) => {
      tts.enqueue(key, priority);
      dashboard.setFeedback(uiType, t(key));
    },
  });

  inference.reset();
  tts.stop();
  tts.setLang(lang);
  dashboard.reset();
  dashboard.setTime(timeLeft);

  $('rule-mode-badge')?.classList.add('hidden');
  if (!inference.loaded) $('rule-mode-badge')?.classList.remove('hidden');

  const started = await poseService.startCamera($('video'));
  if (!started) {
    alert('Camera access required. Allow camera permission and refresh.');
    showScreen('home-screen');
    return;
  }

  tts.enqueue('start', CONST.PRIORITY_CRITICAL);
  sessionTimer = setInterval(() => {
    timeLeft = Math.max(0, timeLeft - 1);
    dashboard.setTime(timeLeft);
    if (timeLeft === 15) tts.enqueue('almost_there', CONST.PRIORITY_COACHING);
    if (timeLeft <= 0)   endSession();
  }, 1000);
}

function endSession() {
  if (!sessionActive) return;
  sessionActive = false;
  clearInterval(sessionTimer);
  poseService.stopCamera();
  tts.stop();
  tts.enqueue('session_complete', CONST.PRIORITY_CRITICAL);

  const elapsed = CONST.SESSION_DURATION_S - timeLeft;
  currentSession = engine.buildSession({
    id:              Date.now().toString(),
    startedAt:       new Date(sessionStartTs).toISOString(),
    durationSeconds: elapsed,
    language:        lang,
  });

  logger.save(currentSession).then(() => refreshHomeStats());
  showResults(currentSession);
}

// ── Pose frame processing ─────────────────────────────────────────────────────
function onPoseResults(landmarks) {
  if (!sessionActive) return;

  const videoEl = $('video');
  const canvas  = $('pose-canvas');
  if (canvas && videoEl) {
    landmarks ? drawPose(canvas, videoEl, landmarks) : drawNoPose(canvas);
  }

  const wristY = landmarks ? meanWristY(landmarks) : null;
  const sw     = landmarks ? shoulderWidth(landmarks) : null;

  // ML inference
  let mlResult = null;
  if (landmarks && engine?.calibrated) {
    const fv = featureVector(landmarks, {
      prevWristY:       engine.prevWristY,
      prevVelY:         engine.prevVelY,
      baselineWristY:   engine.baselineWristY,
      refShoulderWidth: engine.refShoulderWidth,
    });
    if (fv && inference.loaded) mlResult = inference.run(fv);
  }

  // BPM
  if (engine?.calibrated && wristY != null) {
    const bpm = estimateBpm(engine.wristYBuffer, 25, CONST.PEAK_MIN_DISTANCE);
    if (bpm) engine.pushBpm(bpm);
  }

  engine?.processFrame({ landmarks, features: null, inference: mlResult, wristY, sw });

  if (engine) {
    dashboard.setBpm(engine.currentBpm);
    dashboard.setAccuracy(engine.accuracy());
    dashboard.setCompressions(engine.totalCompressions);
    if (wristY != null) dashboard.setDepth(engine.depthNorm(wristY), true);
  }
}

// ── Results ───────────────────────────────────────────────────────────────────
function showResults(s) {
  const pct   = Math.round(s.overallScore * 100);
  const color = pct >= 85 ? 'var(--green)' : pct >= 60 ? 'var(--amber)' : 'var(--red)';
  const grade = pct >= 85 ? 'EXCELLENT'
    : pct >= 70 ? 'GOOD'
    : pct >= 50 ? 'FAIR'
    : 'NEEDS PRACTICE';

  const card = $('score-card');
  if (card) {
    card.style.background  = `linear-gradient(135deg, ${color}22, var(--card))`;
    card.style.borderColor = color + '44';
  }
  if ($('score-grade')) { $('score-grade').textContent = grade; $('score-grade').style.color = color; }
  if ($('score-pct')) {
    $('score-pct').style.color = color;
    let cur = 0;
    const tick = () => { if (cur < pct) { cur++; $('score-pct').textContent = `${cur}%`; requestAnimationFrame(tick); } };
    tick();
  }
  if ($('score-date'))  $('score-date').textContent  = new Date(s.startedAt).toLocaleString();
  if ($('r-bpm'))       $('r-bpm').textContent       = s.avgBpm ? Math.round(s.avgBpm) : '—';
  if ($('r-comp'))      $('r-comp').textContent      = s.totalCompressions;
  if ($('r-dur'))       $('r-dur').textContent       = `${s.durationSeconds}s`;
  if ($('r-lang'))      $('r-lang').textContent      = s.language.toUpperCase();

  renderCircle('br-rate',    Math.round(s.rateAdherenceScore * 100), 'var(--green)');
  renderCircle('br-posture', Math.round(s.postureScore * 100),       'var(--amber)');
  renderCircle('br-overall', pct,                                    color);
  renderResultsChart();

  showScreen('results-screen');
}

function renderCircle(id, pct, color) {
  const el = $(id);
  if (!el) return;
  el.textContent            = `${pct}%`;
  el.style.color            = color;
  el.style.borderColor      = color;
  el.style.borderTopColor   = color + '33';
}

async function renderResultsChart() {
  const wrap   = $('history-chart-wrap');
  const canvas = $('history-chart');
  if (!wrap || !canvas) return;

  const all = logger.getAll().slice(0, 8).reverse();
  if (all.length < 2) { wrap.classList.add('hidden'); return; }
  wrap.classList.remove('hidden');

  if (!window.Chart) {
    await loadScript('https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js');
  }
  if (canvas._chartInstance) canvas._chartInstance.destroy();

  canvas._chartInstance = new window.Chart(canvas, {
    type: 'line',
    data: {
      labels: all.map((_, i) => `#${i + 1}`),
      datasets: [{
        data:             all.map((s) => Math.round(s.overallScore * 100)),
        borderColor:      '#43A047',
        backgroundColor:  'rgba(67,160,71,0.12)',
        borderWidth:      2,
        pointRadius:      4,
        fill:             true,
        tension:          0.35,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: { ticks: { color: '#888' }, grid: { color: 'rgba(255,255,255,0.05)' } },
        y: {
          min: 0, max: 100,
          ticks: { color: '#888', stepSize: 25, callback: (v) => `${v}%` },
          grid: { color: 'rgba(255,255,255,0.05)' },
        },
      },
    },
  });
}

// ── Drive / download ──────────────────────────────────────────────────────────
async function uploadToDrive() {
  if (!currentSession) return;
  const el = $('drive-status');
  if (el) el.textContent = 'Uploading…';
  const id = await drive.upload(currentSession);
  if (el) {
    el.textContent = id
      ? '✓ Saved to Google Drive'
      : '✗ Upload failed — check OAuth setup in SETUP.md §6';
    el.className = 'drive-status ' + (id ? 'drive-ok' : 'drive-err');
  }
}

function downloadSession() {
  if (!currentSession) return;
  const blob = new Blob([JSON.stringify(currentSession, null, 2)], { type: 'application/json' });
  const url  = URL.createObjectURL(blob);
  const a    = Object.assign(document.createElement('a'), {
    href:     url,
    download: `cpr_session_${currentSession.id}.json`,
  });
  a.click();
  URL.revokeObjectURL(url);
}

// ── Home stats ────────────────────────────────────────────────────────────────
async function refreshHomeStats() {
  const stats = await logger.getStats();
  if ($('stat-sessions')) $('stat-sessions').textContent = stats.total;
  if ($('stat-best') && stats.bestScore != null)
    $('stat-best').textContent = `${Math.round(stats.bestScore * 100)}%`;
}

// ── History ───────────────────────────────────────────────────────────────────
async function loadHistory() {
  const all  = await logger.getAllAsync();
  const list = $('history-list');
  if (!list) return;

  if (all.length === 0) {
    list.innerHTML = `<p style="color:var(--text-muted);text-align:center;padding:40px 0">
      No sessions yet. Complete your first training to see results here.</p>`;
    return;
  }

  list.innerHTML = all.map((s) => {
    const pct   = Math.round(s.overallScore * 100);
    const color = pct >= 85 ? 'var(--green)' : pct >= 60 ? 'var(--amber)' : 'var(--red)';
    return `<div class="history-card" role="button" tabindex="0"
                 onclick="viewSession('${s.id}')"
                 onkeydown="if(event.key==='Enter')viewSession('${s.id}')">
      <div>
        <div class="h-score" style="color:${color}">${pct}%</div>
        <div class="h-meta">
          ${new Date(s.startedAt).toLocaleDateString()} · ${s.durationSeconds}s · ${s.language.toUpperCase()}
        </div>
      </div>
      <div style="color:var(--text-muted);font-size:13px">
        ${s.avgBpm ? Math.round(s.avgBpm) + ' BPM' : '—'}
      </div>
    </div>`;
  }).join('');
}

window.viewSession = async (id) => {
  const s = await logger.getAsync(id);
  if (s) { currentSession = s; showResults(s); }
};

// ── Demo ──────────────────────────────────────────────────────────────────────
const DEMO_STEPS = [
  { icon: '🤲', color: '#E53935', title: 'Hand Placement',
    body: 'Place the heel of your dominant hand on the CENTER of the chest, between the nipples. Interlock your fingers.' },
  { icon: '📐', color: '#7B1FA2', title: 'Body Position',
    body: 'Keep your arms STRAIGHT — lock your elbows. Your shoulders should be directly above your hands.' },
  { icon: '⬇️', color: '#FF8F00', title: 'Compression Depth',
    body: 'Press down HARD — at least 5 cm (2 inches). Allow FULL chest recoil between compressions.' },
  { icon: '🥁', color: '#43A047', title: 'Compression Rate',
    body: 'Compress at 100–120 times per minute. Think: "Stayin\' Alive" by the Bee Gees — that\'s the right rhythm.' },
  { icon: '📞', color: '#1976D2', title: 'Call for Help',
    body: 'ALWAYS call 112 (Rwanda emergency) first. Continue CPR until professional help arrives or the person recovers.' },
];
let demoStep = 0;

function initDemo() { demoStep = 0; renderDemo(); }
function demoNext()  {
  if (demoStep < DEMO_STEPS.length - 1) { demoStep++; renderDemo(); }
  else showScreen('home-screen');
}
function demoPrev()  { if (demoStep > 0) { demoStep--; renderDemo(); } }

function renderDemo() {
  const s = DEMO_STEPS[demoStep];
  $('demo-icon')         && ($('demo-icon').textContent         = s.icon);
  $('demo-title')        && ($('demo-title').textContent        = s.title);
  $('demo-body-text')    && ($('demo-body-text').textContent    = s.body);
  $('demo-step-counter') && ($('demo-step-counter').textContent = `Step ${demoStep + 1} of ${DEMO_STEPS.length}`);
  if ($('demo-icon-wrap')) {
    $('demo-icon-wrap').style.borderColor = s.color;
    $('demo-icon-wrap').style.color       = s.color;
  }
  if ($('demo-next')) {
    $('demo-next').textContent      = demoStep < DEMO_STEPS.length - 1 ? 'Next →' : "I'm Ready";
    $('demo-next').style.background = s.color;
  }
  if ($('demo-prev')) $('demo-prev').style.display = demoStep === 0 ? 'none' : 'flex';

  const track = $('demo-progress');
  if (track) {
    const fill = Object.assign(document.createElement('div'), { className: 'demo-progress-inner' });
    fill.style.cssText = `width:${((demoStep + 1) / DEMO_STEPS.length) * 100}%;background:${s.color};transition:width .3s ease`;
    track.replaceChildren(fill);
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────
function setProgress(pct, msg) {
  $('progress-bar') && ($('progress-bar').style.width = `${pct}%`);
  $('load-msg')     && ($('load-msg').textContent     = msg);
}
function loadScript(src) {
  return new Promise((res, rej) => {
    const s = Object.assign(document.createElement('script'), { src, onload: res, onerror: rej });
    document.head.appendChild(s);
  });
}
function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

// ── Bootstrap ─────────────────────────────────────────────────────────────────
init();
