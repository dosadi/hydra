# AXI-Lite Coverage TODOs

Checklist to keep the CSR block exercised across regressions.

- TODO [P0]: Add cocotb smoke tests that toggle `INT_MASK` bits individually and verify `irq_out/msi_pulse` reacts only when the mask is enabled (build on `test_hydra_smoke`).
- TODO [P1]: Instrument a VCD-based parser or cocotb monitor to track `W1C` behavior on `INT_STATUS`: ensure writes clear only the requested bits and leave others intact.
- TODO [P1]: Add a lightweight formal check (SVA or SymbiYosys) that `dma_status[1]` mirrors `dma_busy_in` and `dma_status[0]` pulses on completion/clear; re-use the covergroup previously added.
- TODO [P2]: Document how to trigger AXI-Lite coverage runs (using `sim/tests/run_rtl_tests.sh`) and include sample coverage counters/logs under `docs/coverage/`.
- TODO [P2]: Add a regression that writes to every W-region in `voxel_axil_csr` and reads it back (e.g., a Python script) to catch future address map changes.
