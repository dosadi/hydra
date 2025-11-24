#!/usr/bin/env bash
set -euo pipefail

# Print the prepared issue draft to stdout for easy copy/paste.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRAFT="${DRAFT:-"$ROOT/issue_draft_lock_coordination.md"}"

if [[ ! -f "$DRAFT" ]]; then
  echo "draft not found: $DRAFT" >&2
  exit 1
fi

cat "$DRAFT"
