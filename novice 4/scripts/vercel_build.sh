#!/usr/bin/env bash
# Novice — CPR-AI Coach
# GNU General Public License v3.0
# Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
#
# scripts/vercel_build.sh
# ───────────────────────
# Called by vercel.json's buildCommand.
# Flutter is cloned to /tmp/flutter by vercel.json's installCommand.
#
# Config injection strategy:
#   Credentials are injected into build/web/index.html AFTER flutter build web
#   via the Python block below. The source web/index.html may already contain
#   hardcoded values (for local dev convenience) — this script strips and
#   re-injects from Vercel env vars so the production build always uses the
#   values set in the Vercel dashboard, never whatever was committed to source.
#
# Required Vercel environment variables (Settings → Environment Variables):
#   SUPABASE_URL      — e.g. https://xyzxyz.supabase.co
#   SUPABASE_ANON_KEY — your project's anon/public key

set -euo pipefail

FLUTTER="/tmp/flutter/bin/flutter"

# ── Validate required env vars BEFORE building ──────────────────────────────
# Fail fast with a clear message rather than silently producing a broken build.
if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "[vercel_build] ✗ SUPABASE_URL is not set in Vercel Environment Variables."
  echo "  Go to: Vercel dashboard → novice → Settings → Environment Variables"
  exit 1
fi
if [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "[vercel_build] ✗ SUPABASE_ANON_KEY is not set in Vercel Environment Variables."
  echo "  Go to: Vercel dashboard → novice → Settings → Environment Variables"
  exit 1
fi

echo "[vercel_build] ✓ Env vars present."
echo "[vercel_build] SUPABASE_URL = ${SUPABASE_URL:0:30}..."

# ── Build ────────────────────────────────────────────────────────────────────
echo "[vercel_build] Flutter version:"
"$FLUTTER" --version

echo "[vercel_build] pub get..."
"$FLUTTER" pub get

echo "[vercel_build] Building release web..."
"$FLUTTER" build web \
  --release \
  --no-tree-shake-icons

echo "[vercel_build] Flutter build complete."

# ── Inject window.__NOVICE_CONFIG__ into build/web/index.html ───────────────
# Strips any previously-injected block (idempotent) then re-injects from env.
python3 - <<PYEOF
import os, re, pathlib, sys

url = os.environ["SUPABASE_URL"]
key = os.environ["SUPABASE_ANON_KEY"]
pin = "2026"

path = pathlib.Path("build/web/index.html")
if not path.exists():
    print("[inject] ERROR: build/web/index.html not found — did flutter build web succeed?", file=sys.stderr)
    sys.exit(1)

html = path.read_text(encoding="utf-8")

# Strip any previously-injected block (handles both source-committed and
# previously-injected values — makes this script fully idempotent).
html = re.sub(
    r'<script>\s*window\.__NOVICE_CONFIG__\s*=\s*\{.*?\};\s*</script>',
    '',
    html,
    flags=re.DOTALL,
)

snippet = (
    f'<script>window.__NOVICE_CONFIG__={{'
    f'supabaseUrl:"{url}",'
    f'supabaseAnonKey:"{key}",'
    f'researcherPin:"{pin}"'
    f'}};</script>'
)

if "</head>" not in html:
    print("[inject] ERROR: </head> not found in index.html — cannot inject config.", file=sys.stderr)
    sys.exit(1)

html = html.replace("</head>", snippet + "</head>", 1)
path.write_text(html, encoding="utf-8")

# Verify injection landed
if snippet in path.read_text(encoding="utf-8"):
    print(f"[inject] ✓ window.__NOVICE_CONFIG__ injected into build/web/index.html")
    print(f"[inject]   supabaseUrl     = {url[:30]}...")
    print(f"[inject]   supabaseAnonKey = {key[:20]}...")
else:
    print("[inject] ERROR: injection verification failed.", file=sys.stderr)
    sys.exit(1)
PYEOF

echo "[vercel_build] Done. Deployment output: build/web/"