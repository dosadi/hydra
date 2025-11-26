#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Simple driver coverage runner that exercises key helper tools.

set -euo pipefail

OUT_DIR="${OUT_DIR:-out/driver-coverage}"
mkdir -p "$OUT_DIR"

declare -a DRIVER_TOOLS=(
  "scripts/hydra_cam_reset"
  "scripts/hydra_irq_test"
  "scripts/hydra_bar1_hexdump"
)

for tool in "${DRIVER_TOOLS[@]}"; do
  if [[ -x "$tool" ]]; then
    echo "Running $tool"
    "$tool" >"$OUT_DIR/$(basename "$tool").log" 2>&1 || {
      echo "Tool $tool failed; see $OUT_DIR/$(basename "$tool").log"
      exit 1
    }
  else
    echo "Tool $tool not found or not executable; skipping"
  fi
done

echo "Driver coverage run complete; logs in $OUT_DIR"
