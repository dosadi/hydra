#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/tests"

VERILATOR=${VERILATOR:-verilator}

echo "Building AXI WRAP test with verilator..."
TEST_STUB="$ROOT/tests/axi_sdram_stub.sv"
$VERILATOR -Wall -sv --cc "$TEST_STUB" --top-module axi_sdram_stub --public-flat-rw --exe axi_wrap_test.cpp -CFLAGS '-O2'
make -C obj_dir -f Vaxi_sdram_stub.mk
cp obj_dir/Vaxi_sdram_stub ./axi_wrap_test
echo "Running AXI WRAP test..."
./axi_wrap_test
