#!/bin/bash
# scripts/vercel_build.sh — runs on Vercel during production build.
# Flutter is installed by installCommand. This script builds and injects config.
set -e

/tmp/flutter/bin/flutter build web --release --dart-define="RESEARCHER_PIN=2026"

python3 - <<PYEOF
import os, re, pathlib

url = os.environ["SUPABASE_URL"]
key = os.environ["SUPABASE_ANON_KEY"]
pin = "2026"

path = pathlib.Path("build/web/index.html")
html = path.read_text(encoding="utf-8")

# Strip any previously-injected config (idempotent)
html = re.sub(r'<script>window\.__NOVICE_CONFIG__=\{.*?\};</script>', '', html, flags=re.DOTALL)

snippet = f'<script>window.__NOVICE_CONFIG__={{supabaseUrl:"{url}",supabaseAnonKey:"{key}",researcherPin:"{pin}"}};</script>'
html = html.replace("</head>", snippet + "</head>", 1)
path.write_text(html, encoding="utf-8")
print(f"Config injected into build/web/index.html")
PYEOF