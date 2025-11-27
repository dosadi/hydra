#!/usr/bin/env bash
set -euo pipefail
# rsync_to_termux.sh
# Usage: ./scripts/rsync_to_termux.sh <user@host> [remote_path] [ssh_port]
# Example: ./scripts/rsync_to_termux.sh u@192.168.1.42 /data/data/com.termux/files/home/hydra 22

REMOTE=${1:?"remote target required (user@host)"}
REMOTE_PATH=${2:-"~/hydra"}
SSH_PORT=${3:-22}

# Defaults: exclude large/generated files and local sim obj dirs
EXCLUDES=(
  --exclude ".git/"
  --exclude "sim/obj_dir/"
  --exclude "build/"
  --exclude "*.o"
  --exclude "*.a"
  --exclude "*.log"
  --exclude "*.vcd"
  --exclude "*.ppm"
  --exclude "third_party/"
  --exclude "rtl/*_tb.v"
)

RSYNC_OPTS=( -avz --delete --compress-level=3 "${EXCLUDES[@]}" -e "ssh -p ${SSH_PORT}" )

echo "Syncing workspace to ${REMOTE}:${REMOTE_PATH} (ssh port ${SSH_PORT})"
echo "This will delete remote files not present locally under the target path."
read -p "Proceed? [y/N] " yn
case "$yn" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 1;;
esac

mkdir -p /tmp/rsync_hydra
rsync "${RSYNC_OPTS[@]}" ./ ${REMOTE}:${REMOTE_PATH}

echo "Rsync complete. On the Termux device, you may need to run: pkg install build-essential verilog-tools verilator sdl2"
echo "If you prefer pulling from Termux, run on Termux: git clone <repo> or use scp/rsync to pull this host."
