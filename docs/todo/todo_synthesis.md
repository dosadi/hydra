# Synthesis / Timing TODOs

Tasks to keep the RTL synthesis-friendly with predictable timing closure.

- DONE [P0]: Produce baseline SDC constraints (clocks, generated clocks, false/multicycle paths, async resets) for reference FPGA targets; check into `constraints/`.
- DONE [P0]: Add CDC audit/waivers (async crossings for IRQ, AXI-lite to core clocks) with small synchronizers or SVAs where missing.
- TODO [P1]: Define synthesis-time parameters (VOXEL_GRID_SIZE, SCREEN dims, DMA window) and ensure defaults match sim; add guards for unsupported configs.
- TODO [P1]: Add synthesis lint (verilator --lint-only + vendor lint) target in CI and document required pragmas/waivers.
- TODO [P1]: Create area/timing tracking table (per build) and a script to diff post-synth reports for regressions.
- TODO [P2]: Add optional clock gating enables for idle blocks (DMA/blitter/HDMI) with synthesis-friendly generates.
- TODO [P2]: Document reset strategy (async assert, sync deassert) and ensure all flops are covered; add reset-domain crossing notes if any remain.
- TODO [P2]: Provide a minimal gate-level sim recipe (GLS) for the top to spot uninitialized nets and timing issues.
- TODO [P2]: Audit held timing paths from the raycaster and render pipeline (clock crossings) and document which paths can tolerate slack vs. which must stay low-latency.
- TODO [P2]: Add a synthesis power estimation log (per rails) and tie it to `docs/todo/todo_power.md` so power budgeting stays visible across RTL changes.
- TODO [P2]: Feed synthesis metadata (timing slack, area, power) into `scripts/ai_health_dashboard.py` so regressed paths trigger TODO updates.
- TODO [P2]: Create a synthesis change log that records each major bitstream tweak (grid size, clock, DMA width) and cross-links to this tracker for traceability.
- TODO [P3]: Capture a guideline for vendor-tuned synth scripts (Vivado/Quartus) that includes which macros to pass and which XDC constraints to update when top-level ports change.
- TODO [P3]: Document how to rerun the synthesis flow in Docker/CI (`scripts/synth_docker.sh`) so contributors can reproduce area/timing numbers before shipping.
- TODO [P2]: Record slack histograms per timing path and link them to `docs/todo/todo_performance.md` so bench runs can catch regressions relative to 0.0.7.
- TODO [P1]: Add regression plots (FFT or hist) tracking path delay vs. configuration knobs (grid size, DMA width) for release notes.
- TODO [P3]: Build an incremental synthesis check that only reruns affected modules when core parameters change, reducing turnaround time on small changes.
- TODO [P2]: Capture a set of golden post-synth netlists (or hashed signatures) to compare against new synth runs before committing.
- TODO [P2]: Track register pipe/util toggle coverage in synthesis reports to know which macros are still pulling area and identify unused registers.
- TODO [P1]: Tie synthesis flows to `scripts/todo_rebalance.py` so when timing numbers slip the tracker automatically surfaces the cause and suggests related TODO entries.
- TODO [P3]: Document the path-specific constraints that should be suppressed when we run the viewer at debug settings, ensuring gating doesn’t affect the release bitstream.
- TODO [P2]: Build an automated warning when the synthesis build size (LUT/FF utilization) exceeds a threshold recorded in `docs/todo/todo_build_devtools.md`.
- TODO [P3]: Add a synthesis task size guide describing when to treat a change as a quick tweak vs. a major re-architecture, keeping the tracker flexible for everything from small fixes to whole product expansions.
