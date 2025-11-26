# Synthesis / Timing TODOs

Tasks to keep the RTL synthesis-friendly with predictable timing closure.

- TODO [P0]: Produce baseline SDC constraints (clocks, generated clocks, false/multicycle paths, async resets) for reference FPGA targets; check into `constraints/`.
- TODO [P0]: Add CDC audit/waivers (async crossings for IRQ, AXI-lite to core clocks) with small synchronizers or SVAs where missing.
- TODO [P1]: Define synthesis-time parameters (VOXEL_GRID_SIZE, SCREEN dims, DMA window) and ensure defaults match sim; add guards for unsupported configs.
- TODO [P1]: Add synthesis lint (verilator --lint-only + vendor lint) target in CI and document required pragmas/waivers.
- TODO [P1]: Create area/timing tracking table (per build) and a script to diff post-synth reports for regressions.
- TODO [P2]: Add optional clock gating enables for idle blocks (DMA/blitter/HDMI) with synthesis-friendly generates.
- TODO [P2]: Document reset strategy (async assert, sync deassert) and ensure all flops are covered; add reset-domain crossing notes if any remain.
- TODO [P2]: Provide a minimal gate-level sim recipe (GLS) for the top to spot uninitialized nets and timing issues.
