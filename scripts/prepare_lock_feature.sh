#!/usr/bin/env bash
set -euo pipefail

# Generate an issue-ready feature request draft and optionally run prototype tests.
# Env:
#   ISSUE_OUT: output path for the draft (default: issue_draft_lock_coordination.md in repo root)
#   RUN_TESTS: if set to 1, runs pytest in prototypes/codex-lock-broker

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUE_OUT="${ISSUE_OUT:-"$ROOT/issue_draft_lock_coordination.md"}"

FR="$ROOT/docs/feature_request_lock_coordination.md"
RFC="$ROOT/docs/rfc/lock_coordination.md"
PROTO="$ROOT/prototypes/codex-lock-broker"

for f in "$FR" "$RFC"; do
  if [[ ! -f "$f" ]]; then
    echo "missing expected file: $f" >&2
    exit 1
  fi
done

{
  echo "Title: Add multi-invocation safety (locks + session outputs) to Codex CLI"
  echo
  echo "Body:"
  cat "$FR"
  echo
  echo "References:"
  echo "- RFC: $RFC"
  echo "- Prototype: $PROTO (README, CI, server/lib/tests)"
} > "$ISSUE_OUT"

echo "Wrote issue draft to $ISSUE_OUT"

if [[ "${RUN_TESTS:-0}" -eq 1 ]]; then
  echo "Running prototype tests..."
  (cd "$PROTO" && python -m pip install -e .[dev] && pytest)
fi
