# CI Automation Overview

This document describes the automated workflows, scripts, and gating policies that keep Hydra’s TODO system, Hardware/RTL stubs, and mixed-signal tooling in sync.

## Key Scripts
- `scripts/todo_sweep.py` / `scripts/check_required_files.py` / `scripts/check_todo_unique.py`: validate tracker densities, required files, and duplicate TODOs.
- `scripts/todo_rebalance.py`: computes tracker averages, fails when any tracker drops below 65% of the mean, and writes a report.
- `scripts/ci_todo_rebalance.sh`: runs the rebalance script and emits `out/todo_rebalance_report.txt`.
- `scripts/automation_watchdog.sh`: bundles the CI checks (rebalancer + sweeps) so a single command can gate a workflow.
- `scripts/ai_health_dashboard.py`: consumes `docs/todo/todo_tracker_metadata.json` (regenerated via `scripts/todo_metadata.py`) and writes an AI health dashboard (`out/ai_health_dashboard.txt`) that highlights unknown priority clusters and TODO counts.
- `scripts/test_litex_stubs.sh`: lint-checks the new LiteX bridge/DMA stubs via Verilator.
- `scripts/board_simulate.sh`: dry-run analog regressions after `scripts/setup_mixed_signal_env.sh` ensures the workspace is configured.
- `scripts/finish_release.sh`: automates the release build/lint/tag/push steps when you are ready to cut a version.

## GitHub Action (automation.yml)
- Runs `scripts/test_litex_stubs.sh` on every push/PR to keep stub RTL clean.
- Executes `scripts/automation_watchdog.sh` to produce TODO rebalance + sanity outputs.
- Uploads `out/todo_rebalance_report.txt` as a build artifact for reviewers.
- Runs the `ai-dashboard` job (after `linux`) which rebuilds the metadata, runs `scripts/ai_health_dashboard.py`, and uploads `out/ai_health_dashboard.txt` so reviewers can see the latest AI TODO priorities.
- Appends the dashboard text to the workflow summary via `actions/github-script`, so you can read the latest unknown/tracker stats directly from the GitHub run page without downloading artifacts.
- When `RUN_ANALOG=1`, runs `scripts/board_simulate.sh` to collect analog logs (requires analog tool licenses).

## How to Run Locally
```bash
./scripts/automation_watchdog.sh
```
This reproduces the CI actions (except artifacts). Use `OUT_DIR` to capture custom reports, and rerun `scripts/test_litex_stubs.sh` manually when editing `rtl/litex/`.

## CI Failures & Follow-up
- If rebalance fails, consult `out/todo_rebalance_report.txt` (published by CI) and add TODOs to the listed trackers or adjust automation scripts.
- When `scripts/test_litex_stubs.sh` reports lint errors, fix the RTL stub notes or disable the job via env guard.
- Mixed-signal jobs require `setup_mixed_signal_env.sh`; CI toggles these via `RUN_ANALOG=1`.

Document this doc in `docs/todo/todo_project_structure.md` and reference it from automation-related TODOs (rebalancing/docs).
