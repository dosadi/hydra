#!/usr/bin/env bash
set -euo pipefail

# scripts/check_hygiene.sh
# Fast repo hygiene checks for CI and local runs.

echo "[hygiene] Checking for tracked Verilator artifacts..."
# Check whether any files under sim/obj_dir are tracked
if git ls-files -- "sim/obj_dir" | grep -q .; then
    echo "ERROR: tracked files under sim/obj_dir detected. Please run scripts/untrack_sim_objdir.sh locally and push the result."
    git ls-files "sim/obj_dir" | sed -n '1,200p'
    exit 1
else
    echo "[hygiene] OK: sim/obj_dir not tracked"
fi

echo "[hygiene] Running shellcheck on scripts/"
set +e
shellcheck -x scripts/*.sh
SH_OK=$?
set -e
if [ $SH_OK -ne 0 ]; then
    echo "shellcheck reported issues. Fix warnings or adjust rules." >&2
    exit $SH_OK
fi

echo "[hygiene] Scanning for TODO/FIXME occurrences (report only)"
git grep -n "TODO\|FIXME" || true

echo "[hygiene] Done"
exit 0
