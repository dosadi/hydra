# Meta System TODOs

Focuses on keeping the TODO/meta/automation infrastructure healthy: metadata scripts, dashboards, dependency maps, session bridges, and release hygiene so the meta work itself has a living tracker.

## P1 - Automation Maintenance
- **TODO [P1]:** Keep `scripts/meta_refresh.py` (which runs `scripts/todo_metadata.py` and emits `docs/todo/todo_tracker_metadata.json`) on a scheduled reminder/automation job so `out/todo_tracker_metadata_summary.json` stays current; `scripts/automation_watchdog.sh` already uses this helper to keep the automation bundle in sync.
- **TODO [P1]:** Re-run `scripts/ai_session_report.py`, `scripts/ai_health_dashboard.py`, and `scripts/ai_dashboard_briefing.py` whenever meta documents change; document this in `docs/todo/todo_system_design.md` and link to the tracker.
- **TODO [P1]:** Have `scripts/validate_dependency_map.py` run inside CI (`scripts/automation_watchdog.sh` already calls it with `--fail-on-missing`) and log failures (or successes) to `out/meta_dependency_failures.txt` so automation responders know when dependencies break.
- **TODO [P1]:** Emit a human-readable meta status report (`scripts/meta_status_report.py`) after each automation cycle so reviewers can quickly see how many P0/P1 trackers are outstanding and which files dominate the priority list.
- **TODO [P1]:** Document meta sector status metrics (counts per priority, unknowns) and publish them to the AI dashboard summary so automation consumers know meta health at a glance.
- **TODO [P1]:** Include render pipeline instrumentation summaries (`scripts/render_pipeline_bench.py` consuming `out/render_pipeline_baseline.csv`) in the AI health dashboard so reviewers see ray-loop/HUD/frame copy baselines alongside tracker counts.

## P2 - Documentation & Release Meta
- **TODO [P2]:** Produce a meta release checklist (automation scripts, metadata, dependency checks) added to `docs/todo/todo_go_to_market.md` so releases verify the meta tooling is functional.
- **TODO [P2]:** Maintain the Agent Coordination Bridge plus `docs/todo/todo_system_continuation` entries to describe what each AI agent touched; link updates to this tracker.
- **TODO [P2]:** Keep the sector overview/map updated with new meta lot additions (sector for automation, new trackers) and document any automation dependencies introduced.
- **TODO [P2]:** Add security/ownership notes about who owns the meta scripts and what the escalation path is when they fail (log that info inside this tracker).

## P3 - Community & Governance
- **TODO [P3]:** Schedule regular meta reviews (monthly) to prune stale meta TODOs, archive old session docs into `docs/archive`, and log that cleanup here.
- **TODO [P3]:** Build a meta performance dashboard entry that tracks how long automation jobs take, queued tasks, and meta sector coverage; surface it with `scripts/ai_health_dashboard.py`.
- **TODO [P3]:** Provide a community-facing meta guide (wiki page) explaining how to extend the meta system (scripts, trackers, dashboards) so volunteers keep the automation healthy.
