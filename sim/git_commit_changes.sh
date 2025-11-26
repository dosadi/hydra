#!/usr/bin/env bash
set -euo pipefail

# Helper to stage and commit the sim-related changes I added.
# Run this locally to create the commit.

git add -A sim || true

msg="Fix sim harness: remove duplicate instrumentation, fix timing scope; add run_sim.sh launcher"

if git diff --staged --quiet; then
    echo "[git_commit_changes] No staged changes (nothing to commit)."
    exit 0
fi

git commit -m "$msg"
echo "[git_commit_changes] Committed changes with message: $msg"
