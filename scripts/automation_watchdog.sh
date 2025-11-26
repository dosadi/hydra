#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[automation-watchdog] running repo automation bundle"
(cd "$ROOT" && ./scripts/ci_todo_rebalance.sh)
(cd "$ROOT" && python3 scripts/todo_sweep.py)
(cd "$ROOT" && python3 scripts/check_required_files.py)
(cd "$ROOT" && python3 scripts/check_todo_unique.py)
(cd "$ROOT" && python3 scripts/todo_metadata.py)
(cd "$ROOT" && python3 scripts/ai_health_dashboard.py)

echo "[automation-watchdog] automation bundle complete"
