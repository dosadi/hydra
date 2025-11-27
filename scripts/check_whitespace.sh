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

# Directories to exclude from the scan (relative to repo root)
EXCLUDES=(
  "third_party"
  "build"
  "sim/obj_dir"
  "out"
  "sim/build"
)

status=0

# Build the find expression for names
name_expr=""
for p in "${PATTERNS[@]}"; do
  if [ -n "$name_expr" ]; then
    name_expr+=" -o "
  fi
  name_expr+="-name '$p'"
done

# Build the exclude expression
exclude_expr=""
for d in "${EXCLUDES[@]}"; do
  exclude_expr+=" ! -path '*/$d/*'"
done

eval "find \"$ROOT\" $exclude_expr -type f \( $name_expr \) -print0" | \
while IFS= read -r -d '' file; do
  if grep -n $'\t' "$file" >/dev/null; then
    echo "[whitespace] tabs found: $file"
    status=1
  fi
  if grep -n "[[:blank:]]$" "$file" >/dev/null; then
    echo "[whitespace] trailing space: $file"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "[whitespace] OK: no tab or trailing whitespace issues found."
fi

exit "$status"
