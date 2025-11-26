# AXI-Lite / CSR Coverage TODOs

Organizes the AXI-Lite CSR coverage effort into protocol checks, automation integration, and release gating so the control plane stays solid as the core matures.

## P0 – Protocol correctness
- **TODO [P0]:** Automate a comprehensive register-bitmap exercise that drives each address space in `rtl/voxel_csr.sv`, covers read/write masks, and verifies W1C clears using cocotb/fuzzer scripts; emit the pass/fail status to `out/axi_lite_coverage.json`.
- **TODO [P0]:** Scoreboard AW/AR handshake behavior: confirm `ready/valid` toggles, `WVALID` only asserts when `WSTRB` references valid fields, and `RVALID`/`RLAST` follow the AXI-Lite rules.
- **TODO [P0]:** Add a minimal formal property (SVA or SymbiYosys) that `dma_status[1]` equals `dma_busy_in` and `dma_status[0]` pulses during completions so the status register never drifts from the DMA controller state.

## P1 – Automation instrumentation
- **TODO [P1]:** Add a VCD-aware monitor to track mask/interrupt interactions (e.g., `INT_MASK`, `INT_STATUS`, `msi_pulse`) and log toggles into `scripts/ai_health_dashboard.py` along with `out/axi_lite_coverage.json`.
- **TODO [P1]:** Extend the coverage metadata artifact (`docs/todo/todo_tracker_metadata.json`) with a `axi_lite_coverage` summary so meta dashboards know when this tracker’s regressions last ran.
- **TODO [P1]:** Document how to invoke the coverage rig (`sim/tests/run_rtl_tests.sh`, `scripts/meta_refresh.py`) and publish the resulting counters/logs under `docs/coverage/` for future reviews.

## P2 – Release gating & maintainability
- **TODO [P2]:** Create a regression job that writes/reads every W-region to guard against address-map drift; record the expected pattern in `docs/TODO_MASTER_INDEX.md` so reviewers know the baseline behavior.
- **TODO [P2]:** Outline a open/closed-source story in this tracker (e.g., vendor CSR extensions plugged in the same address map) so future integration keeps the coverage rig beneficial regardless of which bus IP is used.
- **TODO [P2]:** Add a checklist item to `docs/todo/todo_meta_system.md` that ensures `todo_csr_coverage.md` passes its automation gate before any release so the new tracker stays in the meta health loop.
