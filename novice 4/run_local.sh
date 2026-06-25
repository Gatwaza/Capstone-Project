#!/bin/bash
# run_local.sh — Novice CPR Coach
# Keys are read from your shell environment — never hardcode them here.
# Set them once in ~/.zshrc:
#   export SUPABASE_URL="..."
#   export SUPABASE_ANON_KEY="..."
set -e
cd "$(dirname "$0")"

# ── Validate keys are present in the current shell ─────────────────────────
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "✗  Supabase env vars not found in this shell session."
  echo "   Run:  source ~/.zshrc  then try again."
  exit 1
fi

echo "✓  Keys present (not shown)"
echo ""

echo "▶  Building Flutter web..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=RESEARCHER_PIN=2026

echo "▶  Copying Flutter output into web/ (skipping index.html)..."
cp    build/web/main.dart.js         web/
cp    build/web/flutter_bootstrap.js web/
cp    build/web/flutter.js           web/ 2>/dev/null || true
cp -r build/web/assets               web/
cp -r build/web/canvaskit            web/ 2>/dev/null || true

echo "▶  Serving on http://localhost:8080 ..."
python3 -m http.server 8080 --directory web/