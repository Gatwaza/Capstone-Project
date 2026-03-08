// web/src/services/driveService.js
// Uploads session JSON to the user's Google Drive using the Google Identity
// Services (GIS) OAuth2 popup flow + Drive REST API v3.
//
// SETUP REQUIRED (see SETUP.md §6):
//   1. Create an OAuth 2.0 Web Client ID at console.cloud.google.com
//   2. Replace GOOGLE_WEB_CLIENT_ID below with your real client ID
//   3. Enable the Drive API in your project
//
// Without setup: upload button is shown but will fail gracefully.

const GOOGLE_WEB_CLIENT_ID = import.meta.env?.VITE_GOOGLE_WEB_CLIENT_ID
  ?? 'REPLACE_WITH_YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

const DRIVE_SCOPE     = 'https://www.googleapis.com/auth/drive.file';
const DRIVE_API       = 'https://www.googleapis.com/drive/v3/files';
const FOLDER_NAME     = 'CPR_Coach_Sessions';

export class DriveService {
  constructor() {
    this._accessToken = null;
    this._folderId    = null;
    this._gisLoaded   = false;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  async _loadGIS() {
    if (this._gisLoaded) return;
    await new Promise((resolve, reject) => {
      if (window.google?.accounts?.oauth2) { resolve(); return; }
      const s = document.createElement('script');
      s.src = 'https://accounts.google.com/gsi/client';
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
    this._gisLoaded = true;
  }

  async _requestToken() {
    await this._loadGIS();
    return new Promise((resolve, reject) => {
      const client = window.google.accounts.oauth2.initTokenClient({
        client_id: GOOGLE_WEB_CLIENT_ID,
        scope:     DRIVE_SCOPE,
        callback:  (resp) => {
          if (resp.error) { reject(new Error(resp.error)); return; }
          this._accessToken = resp.access_token;
          resolve(resp.access_token);
        },
      });
      client.requestAccessToken({ prompt: 'consent' });
    });
  }

  async _getToken() {
    if (this._accessToken) return this._accessToken;
    return this._requestToken();
  }

  // ── Folder management ─────────────────────────────────────────────────────

  async _ensureFolder(token) {
    if (this._folderId) return this._folderId;

    // Search for existing folder
    const q = encodeURIComponent(
      `mimeType='application/vnd.google-apps.folder' and name='${FOLDER_NAME}' and trashed=false`
    );
    const listResp = await fetch(`${DRIVE_API}?q=${q}&fields=files(id,name)`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const listData = await listResp.json();
    if (listData.files?.length > 0) {
      this._folderId = listData.files[0].id;
      return this._folderId;
    }

    // Create folder
    const createResp = await fetch(DRIVE_API, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name:     FOLDER_NAME,
        mimeType: 'application/vnd.google-apps.folder',
      }),
    });
    const folder = await createResp.json();
    this._folderId = folder.id;
    return this._folderId;
  }

  // ── Upload ────────────────────────────────────────────────────────────────

  /**
   * Upload a session object as JSON to Google Drive.
   * @param {Object} session
   * @returns {string|null}  Drive file ID on success, null on failure
   */
  async upload(session) {
    try {
      const token    = await this._getToken();
      const folderId = await this._ensureFolder(token);

      const filename  = `cpr_session_${session.id}.json`;
      const jsonStr   = JSON.stringify(session, null, 2);
      const boundary  = '-------CPRCoachBoundary';

      // Multipart upload: metadata + file body in one request
      const body = [
        `--${boundary}`,
        'Content-Type: application/json; charset=UTF-8',
        '',
        JSON.stringify({ name: filename, parents: [folderId] }),
        `--${boundary}`,
        'Content-Type: application/json',
        '',
        jsonStr,
        `--${boundary}--`,
      ].join('\r\n');

      const resp = await fetch(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id',
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': `multipart/related; boundary="${boundary}"`,
          },
          body,
        }
      );

      if (!resp.ok) {
        console.error('[DriveService] Upload failed:', resp.status, await resp.text());
        return null;
      }

      const data = await resp.json();
      console.log(`[DriveService] Uploaded ${filename} → id=${data.id}`);
      return data.id;
    } catch (err) {
      console.error('[DriveService] Upload error:', err);
      // Token may be expired — reset for next attempt
      this._accessToken = null;
      return null;
    }
  }
}
