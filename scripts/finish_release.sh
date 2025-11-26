#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Building sim"
(cd "$ROOT" && make)

echo "==> Running TODO / sanity scripts"
(cd "$ROOT" && python3 scripts/todo_sweep.py)
(cd "$ROOT" && python3 scripts/check_required_files.py)
(cd "$ROOT" && python3 scripts/check_todo_unique.py)

if ! git describe --tags --exact-match >/dev/null 2>&1; then
  echo "==> Tagging v0.0.7"
  (cd "$ROOT" && git tag -a v0.0.7 -m "Hydra 0.0.7")
else
  echo "==> Current commit already tagged"
fi

echo "==> Pushing commits + tags"
(cd "$ROOT" && git push)
(cd "$ROOT" && git push --tags)

echo "Release prep complete."
