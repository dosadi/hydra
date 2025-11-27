#!/usr/bin/env bash
set -euo pipefail

# termux_preflight_check.sh
# Run this on a Termux device to collect environment info and report missing items
# Recommended: run before attempting the proot setup or rsync pulls

echo "TERMUX PREFLIGHT CHECK"
echo "======================="

if ! command -v pkg >/dev/null 2>&1; then
  echo "Not running in Termux (pkg not found). This script is intended for Termux." >&2
  exit 2
fi

echo "Date: $(date)"
echo
echo "-- Basic system info --"
uname -a
echo
echo "-- Termux info --"
termux-info || true
echo
echo "-- Disk free (home) --"
df -h ~ || true
echo
echo "-- Installed packages (pkg) --"
pkg list-installed | sed -n '1,200p' || true
echo
echo "-- Check key tools --"
check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK: $1 -> $(command -v $1)"
  else
    echo "MISSING: $1"
  fi
}

check_cmd git
check_cmd rsync
check_cmd proot-distro
check_cmd openssh
check_cmd adb
check_cmd sshd || true

echo
echo "-- SSHD status --"
if pgrep -f sshd >/dev/null 2>&1; then
  echo "sshd is running"
else
  echo "sshd not running"
fi

echo
echo "-- proot-distro distro list (if proot-distro present) --"
if command -v proot-distro >/dev/null 2>&1; then
  proot-distro list || true
else
  echo "proot-distro not installed"
fi

echo
echo "-- Verilator and toolchain checks (likely in proot) --"
if command -v verilator >/dev/null 2>&1; then
  echo "Verilator: $(verilator --version)"
else
  echo "Verilator: MISSING (usually installed inside proot/distro)"
fi

if command -v gcc >/dev/null 2>&1; then
  echo "gcc: $(gcc --version | head -n1)"
else
  echo "gcc: MISSING"
fi

echo
echo "-- Recommended next steps --"
echo "If you plan to build the sim (Verilator, g++, SDL2), use the proot approach:" \
     "run 'pkg install proot-distro' then 'proot-distro install ubuntu-22.04' and use the provided" \
     "scripts/termux_proot_setup.sh to finish setup inside the distro."

echo
echo "If you want to accept files from your workstation, start sshd on Termux and run the host-side rsync:" \
     "on Termux: ./scripts/termux_ssh_control.sh start" \
     "on host: ./scripts/rsync_to_termux.sh user@TERMUX_IP /data/data/com.termux/files/home/hydra 22"

echo
echo "Preflight check complete."
