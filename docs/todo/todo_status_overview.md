# TODO Status Overview

This living document tracks the status of the biggest TODO areas so contributors can see which work is already in-progress, blocked, or ready-to-start.

| Tracker / Area | Status | Notes |
|----------------|--------|-------|
| `todo_system_fps.md` | **In Progress** | Instrumentation HUD + backend logging work is underway; planned nightly `hydra_fps_benchmark` CI job pending. |
| `docs/render_pipeline_layers.md` (optimizations) | **Candidate** | Fast-path ideas (lighting guard, HUD caching, bias mix simplification) are documented; need owners to pick one and implement. |
| `todo_ray_mechanics.md` | **Pending Review** | Broad dependency plan built; more detailed tasks (ray replay, structured HUD feeds) are waiting for prioritization. |
| `todo_rendering_pipeline.md` | **In Progress** | Dashboard flagged unknown counts; now assigning explicit priorities and documenting instrumentation/refinement checkpoints so the pipeline tracker has actionable goals for the ray engine/depth dependencies. |
| `todo_dma_trace_artifacts.md` | **In Progress** | Trace capture schema and report generator TODOs added; requires structured logging tracker outputs before closing. |
| `todo_build_ci.md` | **Ready** | Build/test enhancements scoped; needs sprint slot/nominated owner to pick up jobs arising from new FPS/dependency instrumentation. |

## Automation Status

| Automation Task | Status | Notes |
|-----------------|--------|-------|
| `scripts/automation_watchdog.sh` | **Active** | Runs rebalance/todo sweep/AI dashboard + briefing; feed results into `out/todo_rebalance_report.txt` and `out/ai_health_dashboard.txt`. |
| `scripts/ai_session_report.py` | **Active** | Logs AI sessions and triggers dashboard refreshing + briefing updates. |
| `scripts/ai_health_dashboard.py` | **Active** | Aggregates tracker metadata for the AI dashboard artifact; summary posted to GitHub workflow runs. |
| `scripts/todo_metadata.py` | **Active** | Outputs JSON metadata used by every automation job; needs occasional reviews when new tracker files appear. |
| `scripts/ai_dashboard_briefing.py` | **Pending Review** | Keeps `docs/todo/todo_ai_dashboard.md` in sync with automation; should run automatically after dashboards regenerate. |

## Meta TODOs

- `scripts/meta_refresh.py` now populates `docs/todo/todo_tracker_metadata.json` and `out/todo_tracker_metadata_summary.json` (2025-11-26T18:07:03.166336Z snapshot: 98 trackers, 2025 TODO lines, 205 done lines, priority counts P0=93/P1=403/P2=897/P3=520/unknown=112) so downstream automation can reference fresh stats.
- `scripts/ai_health_dashboard.py` refreshed `out/ai_health_dashboard.txt` (see top unknowns `TODO_SESSION_CONTINUATION_2025_11_25.md` 17 unknown, `todo_system_summary_2025_11_25.md` 15, `TODO_README.md` 11, `TODO_MASTER_INDEX.md` 10, `todo_status_overview.md` 7; top TODO-heavy `todo_master.md`, `todo_testing_ci.md`, `todo_board_hardware_design.md`) so reviewers know which trackers to prioritize and can follow the render baseline note.
- `scripts/ai_dashboard_briefing.py` pushed the latest live briefing into `docs/todo/todo_ai_dashboard.md`, keeping the “Live Briefing” and “Follow-up Actions” blocks synchronized with the current metadata run (live briefing timestamp 2025-11-26T18:07:45.766441Z).
- `scripts/meta_status_report.py` summarized the priority counts/top P0 trackers in `out/meta_status.txt` (98 trackers, TODO lines=2025; priority totals P0=93, P1=403, P2=897, P3=520, unknown=112; top P0 targets: `todo_board_hardware_design.md`, `todo_ip_integration.md`, `todo_testing_ci.md`, `todo_hardware_validation.md`, `todo_board_fpga.md`) for quick status referencing.
- `scripts/validate_dependency_map.py --fail-on-missing` reported success in `out/meta_dependency_failures.txt` (see the 2025-11-26T18:07:27.210217Z entry), confirming all dependency rows still point to existing files after the latest metadata sweep.
- `scripts/render_pipeline_bench.py` now consumes `out/render_pipeline_baseline.csv` and the AI dashboard output contains a “Render Pipeline Baseline” block so render instrumentation runs can surface ray-loop/HUD/copy stats to automation consumers.

## How to Use

- **Update the row** for a tracker whenever status changes (e.g., mark “In Progress” when someone picks it up, “Blocked” when a dependency is still open).  
- **Add fresh entries** for new trackers or ongoing initiatives; include dependencies or blocking factors if relevant.  
- **Use this doc** as the canonical “What’s happening now” reference for daily stand-ups or sprint check-ins.  
- **Meta TODO coordination**: Refer to `docs/todo/todo_meta_todo_plan.md` for the pull-around strategy (priority/dependency ordering, automation refresh cadence, logging). After running `scripts/todo_metadata.py`/`scripts/validate_dependency_map.py`, update this doc’s meta section with the latest snapshot and note when automation dashboards were refreshed so the plan’s execution trail stays visible.  

## Sector Layout Refresh

- Added new sectors for bus infrastructure (`todo_bus_infrastructure.md`, `todo_dma_controller.md`, `todo_crossbar.md`), memory systems (`todo_memory_system.md`, `todo_hbm_integration.md`, `todo_dram_stub.md`, `todo_compression.md`), and the rendering color pipeline (`todo_rendering_color_pipeline.md`, `todo_reemissure.md`) so the TODO directory reflects logical subdomains. Update the sector map (`docs/todo/todo_sector_map.json`) whenever you split out another subsector so automation scripts stay aligned.
- Treat the new bus/memory sections as high-priority (P0/P1) because they feed both hardware bring-up and rendering features; mention blockers or gating tickets back here so the meta-plan knows where to push resources.
