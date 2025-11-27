#!/usr/bin/env bash
set -euo pipefail

# termux_rootfs_content.sh
# Run on Termux device to capture and log rootfs content summary.
# Useful for onboarding, debugging, or documenting the Termux environment.
# Outputs to stdout; redirect to file for logging.

echo "TERMUX ROOTFS CONTENT SUMMARY"
echo "=============================="
echo "Date: $(date)"
echo

if ! command -v pkg >/dev/null 2>&1; then
  echo "Error: Not running in Termux (pkg not found)." >&2
  exit 1
fi

echo "-- Termux Info --"
termux-info || true
echo

echo "-- Installed Packages (pkg list-installed) --"
pkg list-installed | head -n 200 || true
echo

echo "-- Rootfs Directory Structure (/data/data/com.termux/files) --"
find /data/data/com.termux/files -maxdepth 2 -type d | head -n 50 || true
echo

echo "-- Key Directories Content Counts --"
for dir in /data/data/com.termux/files/usr/bin /data/data/com.termux/files/usr/lib /data/data/com.termux/files/home; do
  if [ -d "$dir" ]; then
    count=$(find "$dir" -type f | wc -l)
    echo "$dir: $count files"
  fi
done
echo

echo "-- Environment Variables --"
env | grep -E "(TERMUX|PATH|HOME|PREFIX)" | sort || true
echo

echo "-- Disk Usage --"
df -h /data/data/com.termux/files || true
echo

echo "Rootfs content summary complete."
