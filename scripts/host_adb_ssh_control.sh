#!/usr/bin/env bash
set -euo pipefail
# host_adb_ssh_control.sh
# Use adb to start/stop sshd in Termux on a connected Android device.
# Usage: ./host_adb_ssh_control.sh start|stop|status [adb_device_id]

CMD=${1:-status}
DEVICE_ARG=${2:-}
ADB=(adb)
if [[ -n "$DEVICE_ARG" ]]; then
  ADB+=( -s "$DEVICE_ARG" )
fi

case "$CMD" in
  start)
    echo "Installing openssh in Termux (if missing) and starting sshd via adb"
    "${ADB[@]}" shell "pkg update -y; pkg install -y openssh; passwd || true; nohup sshd >/data/data/com.termux/files/home/sshd.log 2>&1 &"
    echo "Requested sshd start via adb. Check logs on device or run status."
    ;;
  stop)
    echo "Stopping sshd via adb"
    "${ADB[@]}" shell "pkill -f sshd || true"
    ;;
  status)
    echo "Checking sshd status via adb"
    "${ADB[@]}" shell "pgrep -f sshd >/dev/null 2>&1 && echo running || echo not_running"
    ;;
  *)
    echo "Unknown command: $CMD"
    exit 1
    ;;
esac
