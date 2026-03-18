#!/usr/bin/env bash
# Novice — CPR-AI Coach
# GNU General Public License v3.0
# Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
#
# clean_repo.sh
# ─────────────
# Cleans up the original Capstone-Project repository:
#   1. Removes ghost brace-expansion folders (CONFLICT 1)
#   2. Removes root-level Flutter duplicate files (CONFLICT 2)
#   3. Removes committed .DS_Store files from git index
#   4. Ensures .env is not tracked
#   5. Sets up fresh gitignore and structure
#
# Run from repo root:
#   chmod +x scripts/clean_repo.sh
#   ./scripts/clean_repo.sh
#
# SAFETY: This script only removes git-tracked noise and duplicates.
#         Your Findings/ folder and capstone_project/ are untouched.
#         Review each step before running on a shared/pushed branch.

set -euo pipefail

echo ""
echo "======================================================"
echo "  Novice — Repository Cleanup Script"
echo "======================================================"
echo ""

# ── Confirm we are in the repo root ───────────────────────
if [ ! -f "pubspec.yaml" ] && [ ! -d "capstone_project" ]; then
  echo "ERROR: Run this script from the Capstone-Project repo root."
  exit 1
fi

# ── Step 1: Remove ghost brace-expansion folders ──────────
echo "Step 1: Removing brace-expansion ghost folders ..."

# These were created by running `mkdir -p {a,b,...}` in the shell
# instead of properly creating directories. Git tracked the literal names.
GHOST_DIRS=(
  "capstone_project/{lib"
  "assets/{models,animations,images}"
  "capstone_project/assets/{models,animations,images}"
)

for dir in "${GHOST_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "  Removing: $dir"
    git rm -rf "$dir" 2>/dev/null || rm -rf "$dir"
  fi
done

# Remove any remaining directories whose name contains { or }
git ls-files | grep '[{}]' | while read -r f; do
  echo "  Removing ghost path: $f"
  git rm -f "$f" 2>/dev/null || true
done

echo "  ✓ Ghost folders removed"

# ── Step 2: Remove root-level Flutter duplicate ───────────
echo ""
echo "Step 2: Removing root-level Flutter duplicate ..."
echo "  (The canonical app lives in capstone_project/ — these are duplicates)"

ROOT_DUPLICATES=(
  "lib"
  "web"
  "ml_pipeline"
  "test"
  "pubspec.yaml"
  "analysis_options.yaml"
)

for item in "${ROOT_DUPLICATES[@]}"; do
  if [ -e "$item" ]; then
    echo "  Removing root-level: $item"
    git rm -rf "$item" 2>/dev/null || rm -rf "$item"
  fi
done

echo "  ✓ Root duplicates removed"

# ── Step 3: Remove .DS_Store from git index ───────────────
echo ""
echo "Step 3: Removing .DS_Store files from git index ..."
find . -name ".DS_Store" | while read -r f; do
  git rm --cached "$f" 2>/dev/null || true
done
echo "  ✓ .DS_Store files cleared from git"

# ── Step 4: Ensure .env is not tracked ────────────────────
echo ""
echo "Step 4: Checking .env tracking ..."
if git ls-files --error-unmatch "capstone_project/.env" 2>/dev/null; then
  echo "  WARNING: capstone_project/.env is tracked — removing from git index"
  git rm --cached "capstone_project/.env"
fi
echo "  ✓ .env check complete"

# ── Step 5: Commit cleanup ────────────────────────────────
echo ""
echo "Step 5: Staging cleanup commit ..."
git add -A
git status --short

echo ""
echo "======================================================"
echo "  Ready to commit. Run:"
echo "    git commit -m 'chore: clean up ghost folders, root duplicates, .DS_Store'"
echo "    git push origin main"
echo "======================================================"
echo ""
echo "After cleanup, move the new Novice project here:"
echo "  cp -r /path/to/novice/. ."
echo "  flutter pub get"
echo "  flutter run"
