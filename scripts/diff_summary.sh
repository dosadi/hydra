#!/usr/bin/env bash
# Summarize git diff stats and TODO-related changes for PR descriptions.
set -euo pipefail

BASE="${1:-origin/main}"

# Fallback if base ref is missing.
if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  BASE="HEAD~1"
fi

echo "[diff-summary] Comparing against ${BASE}"
echo "[diff-summary] Files changed and line stats:"
git diff --stat "$BASE"...HEAD || true

echo ""
echo "[diff-summary] TODO lines touched in diff:"
git diff "$BASE"...HEAD -U0 | grep -n "TODO" || echo "  (none)"
