// web/src/services/sessionLogger.js
// Persists CPR session JSON to IndexedDB so data survives page refreshes.
// Mirrors lib/services/session_logger.dart (SQLite on mobile).

const DB_NAME    = 'cpr_coach_db';
const DB_VERSION = 1;
const STORE      = 'sessions';

export class SessionLogger {
  constructor() {
    this._db = null;
    this._ready = this._openDB();
  }

  // ── Private: open / create DB ─────────────────────────────────────────────

  _openDB() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);

      req.onupgradeneeded = (e) => {
        const db = e.target.result;
        if (!db.objectStoreNames.contains(STORE)) {
          const store = db.createObjectStore(STORE, { keyPath: 'id' });
          store.createIndex('startedAt', 'startedAt', { unique: false });
        }
      };

      req.onsuccess = (e) => {
        this._db = e.target.result;
        resolve(this._db);
      };

      req.onerror = () => {
        console.warn('[SessionLogger] IndexedDB unavailable — sessions will not persist.');
        resolve(null); // Degrade gracefully
      };
    });
  }

  async _getDB() {
    await this._ready;
    return this._db;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /** Save a session object. Overwrites if same id. */
  async save(session) {
    const db = await this._getDB();
    if (!db) return;
    return new Promise((resolve, reject) => {
      const tx    = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      const req   = store.put(session);
      req.onsuccess = () => resolve();
      req.onerror   = () => {
        console.error('[SessionLogger] Save failed:', req.error);
        reject(req.error);
      };
    });
  }

  /** Get all sessions, sorted newest first. */
  getAll() {
    // Synchronous read from in-memory cache built on first call
    // For simplicity we return from IndexedDB synchronously via a cached list.
    // Use getAllAsync() for fully async access.
    return this._cache ?? [];
  }

  /** Async version — always reads from IndexedDB. */
  async getAllAsync() {
    const db = await this._getDB();
    if (!db) return [];
    return new Promise((resolve) => {
      const tx    = db.transaction(STORE, 'readonly');
      const store = tx.objectStore(STORE);
      const req   = store.getAll();
      req.onsuccess = () => {
        const sorted = (req.result ?? []).sort(
          (a, b) => new Date(b.startedAt) - new Date(a.startedAt)
        );
        this._cache = sorted;
        resolve(sorted);
      };
      req.onerror = () => resolve([]);
    });
  }

  /** Get a single session by id. */
  get(id) {
    return (this._cache ?? []).find(s => s.id === id) ?? null;
  }

  async getAsync(id) {
    const db = await this._getDB();
    if (!db) return null;
    return new Promise((resolve) => {
      const tx    = db.transaction(STORE, 'readonly');
      const store = tx.objectStore(STORE);
      const req   = store.get(id);
      req.onsuccess = () => resolve(req.result ?? null);
      req.onerror   = () => resolve(null);
    });
  }

  /** Delete a session by id. */
  async delete(id) {
    const db = await this._getDB();
    if (!db) return;
    return new Promise((resolve) => {
      const tx    = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      store.delete(id);
      tx.oncomplete = resolve;
    });
  }

  /** Load all sessions into the synchronous cache. Call once on app start. */
  async preload() {
    this._cache = await this.getAllAsync();
    return this._cache;
  }

  /** Stats summary for home screen. */
  async getStats() {
    const all = await this.getAllAsync();
    if (all.length === 0) return { total: 0 };
    const best = Math.max(...all.map(s => s.overallScore));
    const avg  = all.reduce((sum, s) => sum + s.overallScore, 0) / all.length;
    return {
      total: all.length,
      bestScore: best,
      avgScore:  avg,
      lastSession: all[0]?.startedAt,
    };
  }
}
