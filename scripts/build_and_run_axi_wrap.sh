#!/usr/bin/env bash
set -euo pipefail

# Wrapper: build the sim (if needed) and run the AXI WRAP unit test,
# capturing logs into sim/tests/axi_wrap_full_run.log

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$ROOT_DIR/sim"
LOG_FILE="$SIM_DIR/tests/axi_wrap_full_run.log"

echo "Wrapper: building sim and running AXI WRAP test"

# Build sim (no-op if already built)
( cd "$SIM_DIR" && make )

# Run the AXI wrap test and capture output
( cd "$SIM_DIR" && ./tests/run_axi_wrap_test.sh ) > "$LOG_FILE" 2>&1 || RC=$?
if [ -n "${RC-}" ] && [ "$RC" -ne 0 ]; then
    echo "AXI WRAP test FAILED (see $LOG_FILE)"
    exit "$RC"
fi

echo "AXI WRAP test completed successfully; log: $LOG_FILE"
exit 0
