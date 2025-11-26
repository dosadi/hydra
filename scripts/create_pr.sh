#!/usr/bin/env bash
set -euo pipefail

# scripts/create_pr.sh
# Convenience script to create a branch, commit sim-related changes, push, and open a GitHub PR.
# Usage:
#   scripts/create_pr.sh [branch] [commit-message] [pr-title] [pr-body-or-file]
# Examples:
#   scripts/create_pr.sh                        # uses defaults
#   scripts/create_pr.sh my/branch "msg" "PR title" "PR body text"
#   scripts/create_pr.sh my/branch "msg" "PR title" /path/to/body.md

BRANCH=${1:-sim/cleanup-docker}
COMMIT_MSG=${2:-"chore(sim): add launcher, Docker runner, and repo cleanup"}
PR_TITLE=${3:-"$COMMIT_MSG"}
PR_BODY_ARG=${4:-""}

echo "[create_pr] branch: $BRANCH"

# Ensure we have a remote
git remote show origin >/dev/null 2>&1 || { echo "[create_pr] No 'origin' remote configured."; exit 1; }

echo "[create_pr] fetching origin"
git fetch origin --quiet

if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    echo "[create_pr] switching to existing branch $BRANCH"
    git checkout "$BRANCH"
else
    echo "[create_pr] creating branch $BRANCH from origin/main"
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        git checkout -b "$BRANCH" origin/main
    else
        git checkout -b "$BRANCH" main
    fi
fi

# Stage the files we touched during the cleanup work
echo "[create_pr] staging sim/, scripts/, and .gitignore"
git add -A sim .gitignore scripts || true

echo "[create_pr] current status (short):"
git status --short || true

if git diff --staged --quiet; then
    echo "[create_pr] No staged changes to commit."
else
    echo "[create_pr] committing staged changes"
    git commit -m "$COMMIT_MSG"
fi

echo "[create_pr] pushing branch to origin: $BRANCH"
git push -u origin "$BRANCH"

# Prepare PR body
TMP_BODY=""
if [ -n "$PR_BODY_ARG" ]; then
    if [ -f "$PR_BODY_ARG" ]; then
        BODY_FILE="$PR_BODY_ARG"
    else
        TMP_BODY="$(mktemp)"
        printf '%s' "$PR_BODY_ARG" > "$TMP_BODY"
        BODY_FILE="$TMP_BODY"
    fi
else
    TMP_BODY="$(mktemp)"
    cat > "$TMP_BODY" <<'EOF'
This PR adds a convenience run launcher, a Docker build+run helper, documentation, and repo cleanup.

- `sim/run_sim.sh`: local launcher (tmux/nohup) and default font handling
- `sim/git_commit_changes.sh`: helper to stage & commit sim changes locally
- `sim/Dockerfile` + `sim/run_container.sh`: build and run sim in a container (X11 forwarding supported)
- `sim/README.md`: instructions for Docker usage and env knobs
- `.dockerignore`: reduce Docker build context
- Update `.gitignore` to ignore `sim/obj_dir/` and add `scripts/untrack_sim_objdir.sh` to help untrack generated files

No functional RTL changes — tooling and hygiene only.
EOF
    BODY_FILE="$TMP_BODY"
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "[create_pr] 'gh' CLI not found. PR body saved to: $BODY_FILE"
    echo "You can create the PR manually with the following command:" 
    echo "gh pr create --title \"$PR_TITLE\" --body-file $BODY_FILE --base main --head $BRANCH"
    [ -n "$TMP_BODY" ] && echo "(temp body file: $TMP_BODY)"
    exit 0
fi

echo "[create_pr] creating PR via 'gh'"
if gh pr create --title "$PR_TITLE" --body-file "$BODY_FILE" --base main --head "$BRANCH"; then
    echo "[create_pr] PR created successfully"
else
    echo "[create_pr] gh pr create failed — attempting to open PR creation page in your browser"
    # Try a web fallback so the user can complete the PR manually via GitHub UI
    if command -v gh >/dev/null 2>&1; then
        gh pr create --web || true
    fi
    echo "If that doesn't work, run manually:" 
    echo "gh pr create --title \"$PR_TITLE\" --body-file $BODY_FILE --base main --head $BRANCH"
fi

# cleanup
if [ -n "$TMP_BODY" ]; then
    rm -f "$TMP_BODY"
fi

exit 0
