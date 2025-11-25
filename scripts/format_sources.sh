#!/usr/bin/env bash
# Best-effort source formatter for C/C++ and SystemVerilog.
# Requires clang-format for C/C++ and verible-verilog-format for SV.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

SKIP_DIRS=(
  "$ROOT/third_party"
  "$ROOT/build"
  "$ROOT/sim/obj_dir"
  "$ROOT/out"
  "$ROOT/sim/build"
)

in_skip() {
  local path="$1"
  for d in "${SKIP_DIRS[@]}"; do
    [[ "$path" == "$d"* ]] && return 0
  done
  return 0
}

c_files=()
while IFS= read -r -d '' f; do
  c_files+=("$f")
done < <(find "$ROOT" -type f \( -name "*.c" -o -name "*.cc" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \( -path "$ROOT/third_party/*" -prune -o -print \) 2>/dev/null | tr '\n' '\0')

sv_files=()
while IFS= read -r -d '' f; do
  sv_files+=("$f")
done < <(find "$ROOT/rtl" -type f \( -name "*.sv" -o -name "*.svh" -o -name "*.v" \) 2>/dev/null | tr '\n' '\0')

status=0

if [[ ${#c_files[@]} -gt 0 ]]; then
  if command -v clang-format >/dev/null 2>&1; then
    echo "[fmt] clang-format on ${#c_files[@]} files"
    clang-format -i "${c_files[@]}"
  else
    echo "[fmt] clang-format not found; skipping C/C++ files." >&2
    status=1
  fi
fi

if [[ ${#sv_files[@]} -gt 0 ]]; then
  if command -v verible-verilog-format >/dev/null 2>&1; then
    echo "[fmt] verible-verilog-format on ${#sv_files[@]} files"
    verible-verilog-format --inplace "${sv_files[@]}"
  else
    echo "[fmt] verible-verilog-format not found; skipping SystemVerilog files." >&2
    status=1
  fi
fi

if [[ ${#c_files[@]} -eq 0 && ${#sv_files[@]} -eq 0 ]]; then
  echo "[fmt] No matching files found."
fi

exit "$status"
