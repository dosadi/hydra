#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/tests"

VERILATOR=${VERILATOR:-verilator}

echo "Building AXI WRAP test with verilator..."
$VERILATOR -Wall --cc axi_sdram_stub.sv --top-module axi_sdram_stub --public-flat-rw -I../rtl --exe axi_wrap_test.cpp -CFLAGS '-O2'
make -C obj_dir -f Vaxi_sdram_stub.mk
cp obj_dir/Vaxi_sdram_stub ./axi_wrap_test
echo "Running AXI WRAP test..."
./axi_wrap_test
