# AI Dashboard Tracker

This tracker captures work items around the AI health dashboard and ensures the workflow summary generated in CI becomes a first-class artifact for reviewers and contributors.

## Purpose

- Link the automation job summary (Appended with `actions/github-script` at the end of `.github/workflows/ci.yml`'s `ai-dashboard` job) back into the TODO system so humans and future AI agents can react immediately.
- Highlight the top unknown-priority trackers and TODO-heavy areas identified by `scripts/ai_health_dashboard.py`.
- Capture follow-on TODOs triggered by dashboard insights (e.g., retargeting AI effort, reducing unknown counts, improving metadata coverage).

## Current Priorities

- **TODO [P1]:** Ensure the workflow summary is referenced from `docs/ai_resource_strategy.md` and `docs/ci_automation_overview.md` so contributors know where to read the latest metrics (done).
- **TODO [P2]:** Seed a follow-up entry in `docs/todo/todo_dependency_map.md` or `docs/todo/todo_status_overview.md` whenever the dashboard shows a previously stable tracker with rising unknowns.
- **TODO [P2]:** Automate a dashboard notice when the unknown count remains above 50 for more than 3 builds (via a quick script that parses `out/ai_health_dashboard.txt`).
- **TODO [P3]:** Create a short note (HUD or doc) that explains how to interpret “unknown-priority” vs. “TODO-heavy” trackers for the dashboard’s readership (humans and automation).

## Live Briefing
- Generated: 2025-11-26T05:43:15.178453Z
- Trackers: 65
- TODO items: 1477
- DONE items: 199
- Priority-tagged items: 1360
- Unknown-priority items: 117
- Top unknown-priority trackers:
  - todo_rendering_pipeline.md (22 unknown)
  - TODO_SESSION_CONTINUATION_2025_11_25.md (17 unknown)
  - todo_system_summary_2025_11_25.md (15 unknown)
- Leading TODO-heavy trackers:
  - todo_master.md (115 TODOs)
  - todo_testing_ci.md (75 TODOs)
  - todo_board_hardware_design.md (64 TODOs)

## Follow-up Actions
- TODO [P2]: Investigate todo_rendering_pipeline.md (22 unknown) now that it exceeds 20 unknown entries (dashboard flagged it).
<Follow-up TODO entries generated from the latest dashboard run will appear here.>

## Usage Notes

- The AI health dashboard summary appears in the workflow run summary for easy consumption—no download required.
- Run `python3 scripts/ai_health_dashboard.py --top 10` locally to preview the artifact before submitting a change or when triaging CI failures.
- When you act on one of the highlighted trackers, add a short status note under this tracker (e.g., “TODO [P1]: Investigated `todo_rendering_pipeline.md` unknowns; added [P2] entries for shader profiling”) so the dashboard has a narrative path.
