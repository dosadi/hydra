#!/usr/bin/env bash
set -euo pipefail

# Best-effort headless Xschem render helper.
# Exits 77 when Xschem is not installed so CI can skip gracefully.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
schem_dir="${repo_root}/xschem/schematics"
out_dir="${repo_root}/docs/xschem"
rcfile="${repo_root}/xschem/tech/xschemrc"

if ! command -v xschem >/dev/null 2>&1; then
  echo "xschem_render: xschem not found; skipping renders" >&2
  exit 77
fi

mkdir -p "${out_dir}"

status=0
shopt -s nullglob
for sch in "${schem_dir}"/*.sch; do
  base="$(basename "${sch}" .sch)"
  # PNG/PDF outputs; using --no_x for headless export.
  if ! xschem --no_x -r "${rcfile}" -n "${sch}" -o "${out_dir}/${base}.pdf"; then
    status=1
  fi
  if ! xschem --no_x -r "${rcfile}" -n "${sch}" -o "${out_dir}/${base}.png"; then
    status=1
  fi
done

if [[ ${status} -ne 0 ]]; then
  echo "xschem_render: one or more renders failed" >&2
fi

exit "${status}"
