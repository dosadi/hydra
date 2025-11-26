# Physical Testing & Validation TODOs

Focuses on lab/physical hardware tests: fixtures, environmental stress, metrology, and automation that keeps physical labs aligned with the TODO system.

## P1 - Lab Fixtures & Basic Validation
- **TODO [P1]:** Define standard physical test fixtures (power, PCIe, HDMI, debug) and document wiring steps for each board so technicians can reproduce tests consistently.
- **TODO [P1]:** Add a lab validation checklist (cold boot, warm reset, firmware load, driver probe) and log pass/fail results in `out/physical_test_run.json` consumed by `scripts/ai_health_dashboard.py`.
- **TODO [P1]:** Create scripts that orchestrate test sequences via USB/UART (e.g., `scripts/physical_power_cycle.sh`), record telemetry, and automatically seed new TODOs when failures occur (link to `docs/todo/todo_tracking`).
- **TODO [P1]:** Add basic environmental monitoring (temperature/voltage logging) to the lab fixtures and surface the readings through `docs/todo/todo_support_and_licensing.md` so support teams see when thresholds are violated.

## P2 - Stress & Compliance Testing
- **TODO [P2]:** Run thermal/vibration/shock stress tests (using standard lab equipment) and capture logs; reference failed channels in `docs/todo/todo_hardware_validation.md` so automation can react.
- **TODO [P2]:** Automate physical signal measurements (PCIe eye, HDMI timing) with fixtures and feed measured stats into `out/physical_signal_stats.json` for the AI dashboard to track stability across builds.
- **TODO [P2]:** Document how physical tests map to release requirements (e.g., 1000 frame throughput, DMA stress) on this tracker so release managers know the gating criteria.
- **TODO [P2]:** Link physical test reports to the dependency map so automation scripts know when hardware tests block other trackers (e.g., HQ manuf, drivers).

## P3 - Automated Data & Field Feedback
- **TODO [P3]:** Build a physical test data portal (maybe via `docs/support_and_licensing` link) that summarizes fixture results, notable regressions, and actions; tie it to `scripts/ci_collect_logs.sh`.
- **TODO [P3]:** Maintain a “field feedback” log (customer/lab notes) that automatically adds TODOs when issues are reported, feeding them into the AI dashboard via automation scripts.
- **TODO [P3]:** Add a physical test schedule table describing when labs rerun major suites vs quick checks; log adherence as TODOs so the tracker stays in sync with operations.
