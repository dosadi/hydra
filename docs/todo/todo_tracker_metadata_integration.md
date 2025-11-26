# Tracker Metadata Infrastructure TODOs

Focuses on keeping `docs/todo/todo_tracker_metadata.json` fresh, accurate, and wired into automation.

## P1 - Metadata Reliability
- **TODO [P1]:** Ensure every automation job (AI dashboard, watchdog, session report) reruns `scripts/todo_metadata.py` when trackers change and logs the output path in `docs/todo/todo_system_design.md`.
- **TODO [P1]:** Add validation that no tracker path is missing from `todo_tracker_metadata.json` (via schema check or script) so new TODO files are detected immediately.

## P2 - Metadata Features
- **TODO [P2]:** Extend the metadata file with summary stats (per priority totals, unknown counts) and embed automation artifact references so dashboards can display “last update” info without re-parsing Markdown.
- **TODO [P2]:** Publish `out/todo_tracker_metadata_summary.json` containing a filtered view for dashboards plus a `docs/todo/todo_sector_overview.md` reference.

## P3 - Metadata History
- **TODO [P3]:** Maintain a simple changelog recording when metadata is regenerated (timestamp, creator script) so automation audits know when counts shifted unexpectedly.
