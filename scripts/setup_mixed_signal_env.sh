#!/usr/bin/env bash
set -euo pipefail
TOOLS=(vsim ngspice xyce matlab octave)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${MIXED_SIGNAL_HOME:-$ROOT/mixed_signal_env}"

check_tool() {
  local tool=$1
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[mixed-signal] warning: $tool not found on PATH" >&2
    return 1
  fi
  return 0
}

echo "[mixed-signal] initializing workspace at $HOME_DIR"
mkdir -p "$HOME_DIR/models" "$HOME_DIR/logs" "$HOME_DIR/results"
missing=0
for tool in "${TOOLS[@]}"; do
  if ! check_tool "$tool"; then
    missing=$((missing+1))
  fi
done

if [ $missing -gt 0 ]; then
  echo "[mixed-signal] please install missing tools or set PATH" >&2
  exit 1
fi

echo "[mixed-signal] MIXED_SIGNAL_HOME=$HOME_DIR"
