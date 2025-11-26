#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/out}"
REPORT="$OUT_DIR/todo_rebalance_report.txt"

mkdir -p "$OUT_DIR"

echo "[ci] running todo rebalance check"
python3 "$ROOT/scripts/todo_rebalance.py" --output "$REPORT"
echo "[ci] rebalance report written to $REPORT"
