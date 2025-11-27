#!/usr/bin/env bash
set -euo pipefail
# termux_ssh_control.sh
# Start or stop SSHD on Termux. Run on Termux.
# Usage: ./termux_ssh_control.sh start|stop|status

CMD=${1:-status}
case "$CMD" in
  start)
    pkg install -y openssh
    passwd || true
    sshd
    echo "sshd started"
    ;;
  stop)
    pkill -f sshd || true
    echo "sshd stopped (if it was running)"
    ;;
  status)
    if pgrep -f sshd >/dev/null 2>&1; then
      echo "sshd running"
    else
      echo "sshd not running"
    fi
    ;;
  *)
    echo "Unknown command: $CMD"
    exit 1
    ;;
esac
