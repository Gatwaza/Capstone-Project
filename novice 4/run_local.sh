#!/bin/bash
# run_local.sh — Novice CPR Coach
# Keys are read from ~/.novice_env — not hardcoded
set -e
cd "$(dirname "$0")"

# load env
[ -f "$HOME/.novice_env" ] && source "$HOME/.novice_env"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "✗  Missing env vars. Add to ~/.novice_env:"
  echo "   export SUPABASE_URL=\"https://xxx.supabase.co\""
  echo "   export SUPABASE_ANON_KEY=\"eyJ...\""
  exit 1
fi

echo "✓  SUPABASE_URL      = ${SUPABASE_URL:0:30}..."
echo "✓  SUPABASE_ANON_KEY = ${SUPABASE_ANON_KEY:0:12}..."
echo ""

echo "▶  Building Flutter web (release build)..."
flutter build web --release \
  --dart-define="RESEARCHER_PIN=${RESEARCHER_PIN:-2026}"

echo "▶  Copying Flutter output into web/ (skipping index.html)..."
cp    build/web/main.dart.js              web/
cp    build/web/flutter_bootstrap.js      web/
cp    build/web/flutter.js                web/ 2>/dev/null || true
cp    build/web/flutter_service_worker.js web/
cp    build/web/version.json              web/ 2>/dev/null || true
cp -r build/web/assets                    web/
cp -r build/web/canvaskit                 web/ 2>/dev/null || true

echo "▶  Injecting runtime config into web/index.html..."

# Strip any previously-injected config first, then inject exactly once.
python3 - "$SUPABASE_URL" "$SUPABASE_ANON_KEY" "${RESEARCHER_PIN:-2026}" <<'PYEOF'
import re, sys, hashlib, pathlib, time

supabase_url, anon_key, researcher_pin = sys.argv[1], sys.argv[2], sys.argv[3]

# ── 1. Inject config into index.html ────────────────────────────────────────
idx_path = pathlib.Path("web/index.html")
html = idx_path.read_text(encoding="utf-8")

html = re.sub(
    r'<script>window\.__NOVICE_CONFIG__=\{.*?\};</script>',
    '',
    html,
    flags=re.DOTALL,
)

injection = (
    '<script>window.__NOVICE_CONFIG__={'
    f'supabaseUrl:"{supabase_url}",'
    f'supabaseAnonKey:"{anon_key}",'
    f'researcherPin:"{researcher_pin}"'
    '};</script>'
)

if "</head>" not in html:
    print("✗  </head> not found in web/index.html — aborting.", file=sys.stderr)
    sys.exit(1)

html = html.replace("</head>", injection + "</head>", 1)
idx_path.write_text(html, encoding="utf-8")
print("✓  Config injected into index.html")

# ── 2. Recompute index.html MD5 and patch the service worker ─────────────────
# The flutter build copies flutter_service_worker.js with a hash computed
# from the PRE-injection index.html. After injection the file changes, so
# the SW's cached hash is stale. The browser keeps serving the old cached
# index.html (without __NOVICE_CONFIG__), which is why Env returns '' and
# ParticipantService throws "Not configured" in the run_local.sh build.
new_idx_hash = hashlib.md5(idx_path.read_bytes()).hexdigest()

sw_path = pathlib.Path("web/flutter_service_worker.js")
sw = sw_path.read_text(encoding="utf-8")

old_match = re.search(r'"index\.html":\s*"([a-f0-9]+)"', sw)
if old_match:
    old_hash = old_match.group(1)
    sw = sw.replace(f'"index.html": "{old_hash}"', f'"index.html": "{new_idx_hash}"')
    sw = sw.replace(f'"/": "{old_hash}"',          f'"/": "{new_idx_hash}"')
    print(f"✓  Service worker: index.html hash {old_hash[:8]}… → {new_idx_hash[:8]}…")
else:
    print("⚠  index.html entry not found in service worker — skipping hash patch")

# ── 3. Bump serviceWorkerVersion in flutter_bootstrap.js ────────────────────
# The SW registers as flutter_service_worker.js?v=<version>. If the version
# string doesn't change between runs, the browser treats the SW as unchanged
# and never re-fetches it — so our patched SW (with the correct index.html
# hash) is never picked up, and the browser keeps serving stale cache.
new_version = str(int(time.time()))
boot_path = pathlib.Path("web/flutter_bootstrap.js")
boot = boot_path.read_text(encoding="utf-8")

old_ver_match = re.search(r'serviceWorkerVersion:\s*"([^"]+)"', boot)
if old_ver_match:
    old_ver = old_ver_match.group(1)
    boot = boot.replace(
        f'serviceWorkerVersion: "{old_ver}"',
        f'serviceWorkerVersion: "{new_version}"',
    )
    boot_path.write_text(boot, encoding="utf-8")
    print(f"✓  flutter_bootstrap.js: SW version {old_ver} → {new_version}")

    # Patch the SW file name reference inside the SW itself too (if present)
    sw = sw.replace(f'?v={old_ver}', f'?v={new_version}')
else:
    print("⚠  serviceWorkerVersion not found in flutter_bootstrap.js")

# ── 4. Write patched SW ──────────────────────────────────────────────────────
sw_path.write_text(sw, encoding="utf-8")
print("✓  Service worker written")
PYEOF

echo "✓  Config injected and service worker cache-busted"
echo ""
echo "▶  Serving on http://localhost:8080 ..."
echo "   (open in a fresh tab, or Cmd+Shift+R to hard-reload past any cached SW)"
python3 - 127.0.0.1 8080 web <<'PYEOF'
import sys
from http.server import SimpleHTTPRequestHandler, HTTPServer
from pathlib import Path

host, port, webdir = sys.argv[1], int(sys.argv[2]), sys.argv[3]
root = Path(webdir).resolve()

# Extensions that must never fall back to index.html — return real 404 if missing.
# This prevents a missing asset silently returning index.html as a fake 200,
# which previously masked broken icon/wasm/JS requests as confusing non-errors.
ASSET_EXTENSIONS = {
    '.js', '.css', '.png', '.jpg', '.jpeg', '.svg', '.ico',
    '.woff', '.woff2', '.ttf', '.otf',
    '.json', '.wasm', '.map', '.frag',
    '.bin', '.txt', '.md',
    '.mp3', '.mp4', '.webm',
}

class SpaFallbackHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)

    def translate_path(self, path):
        clean = path.split('?', 1)[0].split('#', 1)[0]
        candidate = (root / clean.lstrip('/')).resolve()
        try:
            candidate.relative_to(root)
        except ValueError:
            return str(root / 'index.html')
        if candidate.is_file():
            return str(candidate)
        # Missing asset → real 404, not a silent SPA fallback
        if candidate.suffix.lower() in ASSET_EXTENSIONS:
            return str(candidate)
        # Clean URL paths (/participant, /history, /training/P001) → SPA
        return str(root / 'index.html')

    def log_message(self, fmt, *args):
        msg = fmt % args
        if '304' in msg and ('icon' in msg.lower() or 'favicon' in msg.lower()):
            return
        super().log_message(fmt, *args)

print(f"Serving HTTP on {host} port {port} (http://{host}:{port}/) with hardened SPA fallback ...")
HTTPServer((host, port), SpaFallbackHandler).serve_forever()
PYEOF