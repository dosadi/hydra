#!/usr/bin/env bash
set -euo pipefail

# Safe helper to remove Verilator-generated `sim/obj_dir/` from git tracking.
# Run this locally from the repo root. It will:
#  - show what would be removed
#  - remove `sim/obj_dir` from the index (git rm --cached)
#  - create a commit that documents the change
#
# Usage: ./scripts/untrack_sim_objdir.sh

if [ ! -d "sim/obj_dir" ]; then
    echo "[untrack_sim_objdir] No sim/obj_dir directory present. Nothing to do."
    exit 0
fi

echo "[untrack_sim_objdir] The following tracked files under sim/obj_dir will be removed from git (kept on disk):"
git ls-files -- "sim/obj_dir" || true

read -r -p "Proceed to untrack and commit these changes? [y/N] " ans
if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

git rm -r --cached "sim/obj_dir"
git commit -m "chore: remove Verilator-generated sim/obj_dir from repository; add to .gitignore"
echo "[untrack_sim_objdir] Committed. Note: sim/obj_dir/ remains on disk but is no longer tracked."
