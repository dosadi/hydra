#!/usr/bin/env bash
set -euo pipefail

# run_sim.sh - convenience launcher for running sim_voxel with sane defaults
# - ensures XDG_RUNTIME_DIR exists
# - sets a sensible HYDRA_FONT if available
# - prefers running in a detached tmux session, falls back to nohup background

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

: "${XDG_RUNTIME_DIR:=/tmp/runtime-$(id -u)}"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR

# Prefer a reasonable default font for HUD; allow HYDRA_FONT override
DEFAULT_FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
if [ -z "${HYDRA_FONT:-}" ]; then
    if [ -f "$DEFAULT_FONT" ]; then
        export HYDRA_FONT="$DEFAULT_FONT"
    else
        echo "[run_sim] Warning: default font not found ($DEFAULT_FONT); HUD text may be disabled"
    fi
fi

LOG_FILE="${SIM_RUN_LOG:-run.log}"

if command -v tmux >/dev/null 2>&1; then
    session="hydra_sim"
    if tmux has-session -t "$session" 2>/dev/null; then
        echo "[run_sim] Attaching to existing tmux session '$session'"
        tmux attach -t "$session"
        exit 0
    else
        echo "[run_sim] Starting detached tmux session '$session' and running sim_voxel"
        tmux new-session -d -s "$session" "./sim_voxel 2>&1 | tee -a \"$LOG_FILE\""
        echo "[run_sim] Detached; reattach with: tmux attach -t $session"
        exit 0
    fi
else
    echo "[run_sim] tmux not found; launching with nohup -> $LOG_FILE"
    nohup ./sim_voxel > "$LOG_FILE" 2>&1 &
    pid=$!
    disown "$pid" || true
    echo "[run_sim] Launched sim_voxel (PID $pid); logs: $here/$LOG_FILE"
    exit 0
fi
