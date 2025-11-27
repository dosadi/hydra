#!/usr/bin/env bash
set -euo pipefail

# Auto-iteration helper for sim frame regression.
# - Runs `make test_frame` in `sim/`.
# - If the frame comparison fails, runs a deterministic rerun.
# - Optionally updates the golden frame in a new branch and pushes it.
# Usage: ./scripts/auto_iterate.sh [--auto-update] [--yes] [--open-pr]

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$REPO_ROOT/sim"
CHECK_SCRIPT="$REPO_ROOT/scripts/check_frame.py"

AUTO_UPDATE=0
ASSUME_YES=0
OPEN_PR=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-update) AUTO_UPDATE=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    --open-pr) OPEN_PR=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--auto-update] [--yes] [--open-pr] [--dry-run]
  --auto-update   : when a frame diff occurs, update golden automatically
  --yes, -y       : assume yes for destructive actions (push/commit)
  --open-pr       : attempt to open a PR using the `gh` CLI (if available)
  --dry-run       : run without making changes
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

echo "Auto-iterate: running sim frame regression"
pushd "$SIM_DIR" >/dev/null

set +e
make test_frame
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -eq 0 ]; then
  echo "OK: test_frame passed"
  popd >/dev/null
  exit 0
fi

echo "test_frame failed; running deterministic rerun to gather info"
FRAME_OUT="build/frame_test_safe.ppm"
SIM_BIN="./sim_voxel"
env HYDRA_SAFE_DEFAULTS=1 HYDRA_WORLD_SEED=0 HYDRA_CLEAR_EACH_FRAME=1 FRAME_DUMP="$FRAME_OUT" AUTO_EXIT=1 "$SIM_BIN" >/tmp/sim_safe.log 2>&1 || true

python3 "$CHECK_SCRIPT" tests/golden_frame.ppm "$FRAME_OUT" > build/frame_diff_safe.log 2>&1 || true
echo "--- diff log ---"
sed -n '1,240p' build/frame_diff_safe.log || true
echo "--- sim stderr (tail) ---"
tail -n 80 /tmp/sim_safe.log || true

if [ $AUTO_UPDATE -eq 0 ]; then
  echo "Golden not updated (run with --auto-update to update automatically)."
  popd >/dev/null
  exit 1
fi

if [ ${DRY_RUN:-0} -eq 1 ]; then
  echo "Dry-run: would update golden with $FRAME_OUT and push branch"
  popd >/dev/null
  exit 0
fi

echo "Preparing to update golden frame in a new branch"
TS=$(date -u +%Y%m%dT%H%M%SZ)
BR_NAME="update/golden-frame-$TS"

if [ $ASSUME_YES -eq 0 ]; then
  read -p "Create branch $BR_NAME and update golden? [y/N] " yn
  case "$yn" in
    [Yy]*) ;;
    *) echo "Aborting update"; popd >/dev/null; exit 2 ;;
  esac
fi

# Create branch, copy frame, commit, and push
git checkout -b "$BR_NAME"
mkdir -p tests
cp "$FRAME_OUT" tests/golden_frame.ppm
git add tests/golden_frame.ppm
git commit -m "Update golden frame: refresh after harness changes"
git push -u origin "$BR_NAME"

echo "Pushed branch: $BR_NAME"
echo "Create PR at: https://github.com/$(git config --get remote.origin.url | sed -e 's#.*github.com[:/]##' -e 's/\.git$//')/pull/new/$BR_NAME"

if [ $OPEN_PR -eq 1 ]; then
  if command -v gh >/dev/null 2>&1; then
    gh pr create --fill --head "$BR_NAME" || true
  else
    echo "gh CLI not found; cannot open PR automatically"
  fi
fi

popd >/dev/null

echo "Done."
