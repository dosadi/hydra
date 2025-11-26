# Meta TODO Orchestration Plan

This tracker codifies a method for “pulling around” all of the meta-level TODOs (automation, dashboards, dependency management, rebalance policy, AI health, etc.) so they can be processed in dependency/priority order and so that subsequent releases have a predictable cadence.

## 1. Inventory of Meta Trackers

- `docs/todo/todo_meta_system.md` – defines how metadata feeds automation dashboards, health summaries and the Claude/Codex bridge.
- `docs/todo/todo_dependency_map.md` – records cross-tracker dependencies and feeds `scripts/validate_dependency_map.py`.
- `docs/todo/todo_rebalance_policy.md` – explains how to distribute TODO intake between sectors.
- `docs/todo/todo_status_overview.md` – surfaces build/test readiness and gating for top-level trackers.
- `docs/todo/todo_tracker_metadata_integration.md` – explains the JSON outputs consumed by automation dashboards and release heuristics.
- `docs/todo/todo_ai_dashboard.md` & `todo_ai_development.md` – describe AI/automation-specific tasks that should stay synchronized with the meta system.
- `docs/todo/todo_master.md` & `docs/todo/todo_project_structure.md` – house cross-cutting priorities that must obey the meta dependencies above.

## 2. Priority + Dependency Pull Strategy

1. **Rebuild metadata/status tables** – run `scripts/todo_metadata.py` → `out/todo_tracker_metadata.json` and `scripts/validate_dependency_map.py` to capture each tracker’s priority, status, and dependency edges. Capture the current health snapshot in `out/ai_health_dashboard.txt` as part of the automation guard rails.
2. **Sort by priority/dependency** – start with P0/P1 trackers that have no unmet dependencies, then work outward. Use `todo_dependency_map.md` + `todo_sector_map.json` to identify the minimal set of upstream trackers (e.g., `todo_status_overview` must exist before `todo_ai_dashboard` etc.).
3. **Document blockers/status** – for each tracker, capture status updates (in `docs/todo/todo_status_overview.md` or new per-tracker sections) so automation dashboards don’t lose track of partial progress. Mark gating items (metadata output, rebalance policy, CI job definitions) explicitly.
4. **Plan bundling** – use this document as the “bundle gate” that ensures meta work is done before other sectors (per `todo_rebalance_policy`), then update dashboards/release notes accordingly.

## 3. Execution Plan

- **Weekly cadence**: Run `scripts/automation_watchdog.sh`, `scripts/ai_session_report.py`, and `scripts/ai_dashboard_briefing.py`. After each run, record the results into `out/` artifacts and add TODO updates where coverage is missing (using `todo_master` or `todo_status_overview` as hook points).
- **Dependency sweeps**: After each change to a meta tracker, rerun `scripts/validate_dependency_map.py` and `scripts/todo_metadata.py` so the priority/dependency status is fresh; treat failures as immediate TODO cards. Use `todo_meta_system.md` to describe how those scripts integrate.
- **Meta backlog grooming**: Once metadata is refreshed, pick the highest priority meta item (typically `todo_status_overview`, `todo_dependency_map`, `todo_rebalance_policy`, `todo_ai_dashboard`, `todo_meta_system` in that order) and carve out work for the next sprint; update this file with notes on progress and next dependencies.
- **Cross-sector announcements**: When a meta tracker completes (e.g., automation job added, dashboards stabilized), note the dependency release in `docs/todo/todo_sector_overview.md` and the relevant sector map entry, so dependent sectors can continue.

## 4. Logging & Automation Hooks

- Add a `Meta-TODOs` section to `docs/todo/todo_status_overview.md` that references the latest outputs from this plan.
- Each automation script that touches metadata should append a short summary to `out/ai_health_dashboard.txt`; keep this plan aware by noting the required artifacts.
- If additional meta trackers appear, list them under the “Inventory” section above and tag them with dependencies so this plan can absorb them cleanly.
- Document how the render instrumentation harness populates `out/render_pipeline_baseline.csv`, and ensure `scripts/render_pipeline_bench.py`/`scripts/ai_health_dashboard.py` consume that file so the dashboard and meta watchers can spot ray-loop/HUD/copy regressions alongside priority counts.
