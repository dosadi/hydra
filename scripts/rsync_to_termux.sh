#!/usr/bin/env bash
set -euo pipefail
# rsync_to_termux.sh
# Usage: ./scripts/rsync_to_termux.sh <user@host> [remote_path] [ssh_port]
# Example: ./scripts/rsync_to_termux.sh u@192.168.1.42 /data/data/com.termux/files/home/hydra 22

DRY_RUN=0
EXTRA_EXCLUDES=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --exclude) EXTRA_EXCLUDES+=("--exclude" "$2"); shift 2;;
    --) shift; break;;
    -*) echo "Unknown option $1"; exit 1;;
    *) break;;
  esac
done

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

EXCLUDE_ARGS=("${EXCLUDES[@]}" "${EXTRA_EXCLUDES[@]}")
RSYNC_BASE=( -a -v -z )
if [[ $DRY_RUN -eq 1 ]]; then
  RSYNC_BASE+=(--dry-run)
fi
RSYNC_OPTS=( "${RSYNC_BASE[@]}" --delete --compress-level=3 "${EXCLUDE_ARGS[@]}" -e "ssh -p ${SSH_PORT}" )

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
