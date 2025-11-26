#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
echo "==> Release summary since $LAST_TAG"

echo "Recent commits:"
if [ "$LAST_TAG" = "none" ]; then
  git log -n 20 --oneline
else
  git log "${LAST_TAG}..HEAD" --oneline
fi

echo
echo "TODO tracker stats:"
python3 scripts/todo_sweep.py | head -n 20

echo
echo "New files under docs/todo/:"
find docs/todo -maxdepth 1 -type f -printf "  - %f\n"
