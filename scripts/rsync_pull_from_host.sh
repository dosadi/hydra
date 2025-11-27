#!/usr/bin/env bash
set -euo pipefail
# rsync_pull_from_host.sh
# Run on Termux device to pull repo from a host via rsync over SSH.
# Usage: ./rsync_pull_from_host.sh user@host /remote/path /local/path [ssh_port]

REMOTE=${1:?"remote target required (user@host)"}
REMOTE_PATH=${2:-"~/hydra"}
LOCAL_PATH=${3:-"~/hydra"}
SSH_PORT=${4:-22}

echo "Pulling from ${REMOTE}:${REMOTE_PATH} to ${LOCAL_PATH} (ssh port ${SSH_PORT})"
pkg install -y rsync openssh || true
mkdir -p ${LOCAL_PATH}
rsync -avz -e "ssh -p ${SSH_PORT}" --delete --exclude='.git/' --exclude='sim/obj_dir/' ${REMOTE}:${REMOTE_PATH}/ ${LOCAL_PATH}/
echo "Pull complete."
