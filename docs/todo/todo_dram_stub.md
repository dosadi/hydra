# DRAM Stub TODOs

Simulation SDRAM/DDR stub improvements and coverage targets.

- DONE [P0]: Add burst-length handling beyond single-beat in `axi_sdram_stub` (AR/AW LEN + WLAST/RLAST sequencing) and expand benches.
- DONE [P0]: Gate AR/AW ready on valid (avoid X/unknown accepts) and add SVAs for handshake stability under WAIT_JITTER/latency knobs.
- DONE [P1]: Inject error responses (SLVERR/DECERR) for out-of-range accesses and add cocotb coverage for error propagation to INT_STATUS (outlined in `sim/tests/rtl/test_axi_sdram_error.sv`).
- TODO [P1]: Add data-poison/X-propagation mode to catch uninitialized reads and stale writes in sim benches.
- TODO [P1]: Expand wait-state model: programmable read/write latency distributions plus max outstanding queue depth coverage.
- TODO [P2]: Parameterize memory size/stride for BAR1 vs. framebuffer windows and document expected address maps for FPGA builds.
- TODO [P2]: Add ECC parity stub hooks (optional) with a simple single-bit error injector for resilience testing.
- TODO [P2]: Provide waveform checkpoints/guides for common bugs (WLAST missing, ARLEN off-by-one) in `docs/dram_stub_debug.md`.
- TODO [P2]: Document the word-valid / poison-on-uninit mode in `docs/todo/todo_dram_stub.md` (the RTL can now flag/read unwritten data as X to help catch bugs) and add a dedicated test (`sim/tests/rtl/test_axi_sdram_poison.sv`).
