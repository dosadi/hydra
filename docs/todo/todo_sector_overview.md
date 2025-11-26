# Sector Work Overview

This snapshot orders the major areas of the tree by remaining TODOs/regressions so you can focus on the most pressing work.

1. **RTL + AXI/IP flow (highest priority)**
   - Most active TODOs live in `docs/todo/todo_master.md` and `docs/todo/todo_axi_lite_coverage.md` (AXI/INT assertions, coverage, frame_done tracking).
   - Follow-up work: add targeted SV coverage, formal checks/covergroups (int_status, frame_done), and extend the DMA/backpressure guards.
2. **DRAM/SDRAM stub infrastructure**
   - `docs/todo/todo_dram_stub.md` lists outstanding items (burst support, error handling, debugging guides, poison mode documentation).
   - `docs/dram_stub_debug.md` + `sim/tests/rtl/test_axi_sdram_*` capture the current status; remaining gaps include DECERRs and ECC hooks.
3. **Driver toolchain & coverage**
   - `docs/driver_coverage_todo.md` and `docs/driver_general_todo.md` outline the remaining Linux/FreeBSD/Windows driver/dependency work (kselftests, FreeBSD stats, coverage scripts, Windows toolkit).
   - `scripts/driver_coverage.sh`, `scripts/setup_macos_env.sh`, and `scripts/windows-env.ps1` now exist, but more coverage logging and integration (kselftest, CLI tools) is pending.
4. **Simulation/viewer UX & docs**
   - `docs/todo/todo_master.md`, `docs/todo/todo_simulation_viewer.md`, and `docs/todo/todo_rendering*.md` track viewer enhancements (HUD toggles, input recording, config persistence).
   - Remaining work includes joystick support, grid overlays, and HUD telemetry export.
5. **Testing/CI automation**
   - `docs/todo/todo_testing_ci.md` currently outlines job additions (cocotb nightlies, frame diff artifacts, formatting checks).
   - Focus areas: add CI coverage for new RTL tests, generate machine-readable logs for driver coverage, and automate `scripts/driver_coverage.sh`.
6. **Multiplatform builds & docs**
   - `docs/todo/todo_multiplatform_builds.md` and `docs/macos_windows_build.md` describe outstanding presets/notes; completed items include presets and bootstrap scripts.
   - Future work includes documenting capability tables, tying coverage logs into README, and polishing Windows/macOS driver instructions.

Use this ordered list as a lightweight “sector TODO” before jumping to more granular items. Each numbered sector can reference its detailed todo doc for concrete work packages.

7. **Underrepresented trackers**
   - `docs/todo/todo_sector_overview.md` currently mirrors the big trackers but should also point to the quieter lists (site wiki, xschem, board level) so people can add new anchors when those areas need attention.
   - Add small, high-impact TODO items to the shorter lists (sector overview, site wiki, Xschem) whenever the large documents are already saturated; that balances contributor load and keeps every section fresh.

8. **Release automation / tooling**
   - `scripts/automation_watchdog.sh`, `scripts/ci_todo_rebalance.sh`, and `scripts/finish_release.sh` now bundle the TODO checks plus build/test steps, but they still need integration into the CI pipeline and documentation for non-CLI users.
   - TODO: Document the “automation automation” workflow in this sector overview so new team members know when/why the watchdog runs, and link to the generated rebalance artifact (`out/todo_rebalance_report.txt`).

9. **Toolchain health**
   - Keep an eye on `scripts/setup_mixed_signal_env.sh` + `scripts/board_simulate.sh` for analog regression coverage; the sector tracker should suggest follow-ups when analog artifacts move (VAMS model versions, log outputs).
   - TODO: Track new debug tools (remote logging, automation watchdog, DMA dashboard) and cross-link them here so the sector overview remains a quick reference for tooling-related TODOs.
