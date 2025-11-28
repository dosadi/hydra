#!/usr/bin/env bash
set -euo pipefail
# termux_ssh_control.sh
# Start or stop SSHD on Termux. Run on Termux.
# Usage: ./termux_ssh_control.sh start|stop|status

# Check if running on Termux
if ! command -v pkg >/dev/null 2>&1; then
    echo "Error: This script must be run on Termux (pkg command not found)" >&2
    exit 1
fi

CMD=${1:-status}
case "$CMD" in
  start)
    echo "Starting SSHD..."
    pkg install -y openssh
    # Only set password if not already set
    if ! passwd -S | grep -q "Password set"; then
        echo "Setting password for SSH access..."
        passwd || { echo "Failed to set password"; exit 1; }
    fi
    # Check if sshd is already running
    if pgrep -f sshd >/dev/null 2>&1; then
        echo "SSHD already running"
    else
        sshd
        sleep 1
        if pgrep -f sshd >/dev/null 2>&1; then
            echo "SSHD started successfully"
        else
            echo "Failed to start SSHD"
            exit 1
        fi
    fi
    ;;
  stop)
    echo "Stopping SSHD..."
    if pgrep -f sshd >/dev/null 2>&1; then
        pkill -f sshd || true
        sleep 1
        if pgrep -f sshd >/dev/null 2>&1; then
            echo "Failed to stop SSHD"
            exit 1
        else
            echo "SSHD stopped"
        fi
    else
        echo "SSHD not running"
    fi
    ;;
  status)
    if pgrep -f sshd >/dev/null 2>&1; then
      echo "sshd running (PID: $(pgrep -f sshd))"
    else
      echo "sshd not running"
    fi
    ;;
  *)
    echo "Unknown command: $CMD"
    echo "Usage: $0 start|stop|status"
    exit 1
    ;;
esac
