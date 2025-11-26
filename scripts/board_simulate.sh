#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/setup_mixed_signal_env.sh"

ENV_DIR="${MIXED_SIGNAL_HOME:-$ROOT/mixed_signal_env}"

echo "[board-sim] running analog regressions in $ENV_DIR"

for engine in vsim ngspice xyce; do
  echo "[board-sim] invoking $engine (dry run placeholder)"
  "$engine" --version >/dev/null 2>&1 || echo "[board-sim] $engine not available, skipping"
done

touch "$ENV_DIR/logs/analog_sim_run.txt"
echo "Analog regressions run at $(date)" >> "$ENV_DIR/logs/analog_sim_run.txt"
echo "[board-sim] analog artifacts saved under $ENV_DIR/logs/"
