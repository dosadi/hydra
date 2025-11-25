#!/usr/bin/env bash
# Run a simple spellcheck on Markdown docs using codespell if available.
set -euo pipefail

if ! command -v codespell >/dev/null 2>&1; then
  echo "[spellcheck] codespell not found; skipping."
  exit 0
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Skip third_party and build artifacts.
find "$ROOT" -name "*.md" \
  -not -path "$ROOT/third_party/*" \
  -not -path "$ROOT/build/*" \
  -not -path "$ROOT/.git/*" \
  -print0 | xargs -0 codespell --skip="" --quiet-level=2

echo "[spellcheck] Completed."
