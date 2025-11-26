# Meta System TODOs

Focuses on keeping the TODO/meta/automation infrastructure healthy: metadata scripts, dashboards, dependency maps, session bridges, and release hygiene so the meta work itself has a living tracker.

## P1 - Automation Maintenance
- **TODO [P1]:** Keep `scripts/todo_metadata.py` + `docs/todo/todo_tracker_metadata.json` in sync every cycle; add a scheduled reminder (cron/job) that reruns the script and publishes `out/todo_tracker_metadata_summary.json`.
- **TODO [P1]:** Re-run `scripts/ai_session_report.py`, `scripts/ai_health_dashboard.py`, and `scripts/ai_dashboard_briefing.py` whenever meta documents change; document this in `docs/todo/todo_system_design.md` and link to the tracker.
- **TODO [P1]:** Extend `scripts/validate_dependency_map.py` (or companion) to run in CI and fail when the dependency map references missing trackers; log failures in `out/meta_dependency_failures.txt`.
- **TODO [P1]:** Document meta sector status metrics (counts per priority, unknowns) and publish them to the AI dashboard summary so automation consumers know meta health at a glance.

## P2 - Documentation & Release Meta
- **TODO [P2]:** Produce a meta release checklist (automation scripts, metadata, dependency checks) added to `docs/todo/todo_go_to_market.md` so releases verify the meta tooling is functional.
- **TODO [P2]:** Maintain the Agent Coordination Bridge plus `docs/todo/todo_system_continuation` entries to describe what each AI agent touched; link updates to this tracker.
- **TODO [P2]:** Keep the sector overview/map updated with new meta lot additions (sector for automation, new trackers) and document any automation dependencies introduced.
- **TODO [P2]:** Add security/ownership notes about who owns the meta scripts and what the escalation path is when they fail (log that info inside this tracker).

## P3 - Community & Governance
- **TODO [P3]:** Schedule regular meta reviews (monthly) to prune stale meta TODOs, archive old session docs into `docs/archive`, and log that cleanup here.
- **TODO [P3]:** Build a meta performance dashboard entry that tracks how long automation jobs take, queued tasks, and meta sector coverage; surface it with `scripts/ai_health_dashboard.py`.
- **TODO [P3]:** Provide a community-facing meta guide (wiki page) explaining how to extend the meta system (scripts, trackers, dashboards) so volunteers keep the automation healthy.
