#!/usr/bin/env bash
set -euo pipefail

# scripts/open_pr_url.sh
# Build and open a prefilled GitHub PR compare URL for a branch.
# Usage:
#   scripts/open_pr_url.sh [branch] [base] [title] [body]
# Examples:
#   scripts/open_pr_url.sh                        # uses defaults (sim/cleanup-docker, main)
#   scripts/open_pr_url.sh my/branch main "My Title" "Body text"

BRANCH=${1:-sim/cleanup-docker}
BASE=${2:-main}
TITLE=${3:-""}
BODY=${4:-""}

REPO_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -z "$REPO_URL" ]; then
    echo "[open_pr_url] No origin remote found. Run this from a git repo with origin set."
    exit 1
fi

# Normalize ssh or https remote to owner/repo
if [[ "$REPO_URL" =~ ^git@([^:]+):([^/]+)/(.+)\.git$ ]]; then
    OWNER=${BASH_REMATCH[2]}
    REPO=${BASH_REMATCH[3]}
elif [[ "$REPO_URL" =~ ^https?://[^/]+/([^/]+)/(.+)(\.git)?$ ]]; then
    OWNER=${BASH_REMATCH[1]}
    REPO=${BASH_REMATCH[2]}
else
    # fallback: try to strip suffix
    REPO_PATH=${REPO_URL##*:}
    REPO_PATH=${REPO_PATH##*/}
    REPO_PATH=${REPO_PATH%.git}
    OWNER=$(git remote get-url origin | sed -E 's#.*[:/](.*)/.*#\1#' )
    REPO=$REPO_PATH
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
    echo "[open_pr_url] Could not parse owner/repo from origin URL: $REPO_URL"
    exit 1
fi

# URL-encode title and body using python3
urlencode() {
    python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read(), safe=''))"
}

TITLE_ENC=""
BODY_ENC=""
if [ -n "$TITLE" ]; then
    TITLE_ENC=$(printf '%s' "$TITLE" | urlencode)
fi
if [ -n "$BODY" ]; then
    BODY_ENC=$(printf '%s' "$BODY" | urlencode)
fi

BASE_URL="https://github.com/$OWNER/$REPO/compare/$BASE...$BRANCH?expand=1"
if [ -n "$TITLE_ENC" ]; then
    BASE_URL+="&title=$TITLE_ENC"
fi
if [ -n "$BODY_ENC" ]; then
    BASE_URL+="&body=$BODY_ENC"
fi

echo "[open_pr_url] PR URL:"
echo "$BASE_URL"

if [ -n "${BROWSER:-}" ]; then
    echo "[open_pr_url] Opening in BROWSER=$BROWSER"
    "$BROWSER" "$BASE_URL" &>/dev/null || true
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$BASE_URL" &>/dev/null || true
elif command -v open >/dev/null 2>&1; then
    open "$BASE_URL" &>/dev/null || true
else
    echo "[open_pr_url] No browser opener found; copy the URL above into your browser."
fi

exit 0
