#!/usr/bin/env bash
# Check for trailing whitespace and tabs in source files (SV/C/C++).
# Exits non-zero if any offending lines are found.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# File globs to scan
PATTERNS=(
  "*.sv" "*.svh" "*.v"
  "*.c" "*.cpp" "*.cc" "*.h" "*.hpp"
)

SKIP_DIRS=(
  "./third_party"
  "./build"
  "./sim/obj_dir"
  "./out"
  "./sim/build"
)

skip_args=()
for d in "${SKIP_DIRS[@]}"; do
  skip_args+=("-path" "$d" "-prune" "-o")
done

status=0
while IFS= read -r -d '' file; do
  if grep -n $'\t' "$file" >/dev/null; then
    echo "[whitespace] tabs found: $file"
    status=1
  fi
  if grep -n "[[:blank:]]$" "$file" >/dev/null; then
    echo "[whitespace] trailing space: $file"
    status=1
  fi
done < <(find "$ROOT" \( "${skip_args[@]}" -false \) -type f \( $(printf -- '-name %q -o ' "${PATTERNS[@]}") -false \) -print0)

if [ "$status" -eq 0 ]; then
  echo "[whitespace] OK: no tab or trailing whitespace issues found."
fi

exit "$status"
