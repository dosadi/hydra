#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "[litex-test] linting stub RTL"
cd "$ROOT"
verilator --lint-only rtl/litex/litex_pcie_bridge.sv rtl/litex/litex_dma_engine.sv >/tmp/litex-lint.log 2>&1 || {
    cat /tmp/litex-lint.log
    exit 1
}
echo "[litex-test] lint passed"
