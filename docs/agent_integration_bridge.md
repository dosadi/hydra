# Agent Coordination Bridge

This repo currently sees work from multiple AI instances/teams. To keep the handoff between Claude, Codex, and any other helpers tight, document the key steps here so every agent knows what was touched, what is pending, and what to run next.

## Key Concepts

- **Snapshot the work state/intent** before an agent shuts down: include recent commands, files touched, TODO targets, automation scripts run, and any blockers encountered.
- **Reference existing session docs** (e.g., `docs/archive/session_2025_11_25/README.md` or `docs/TODO_SESSION_CONTINUATION_2025_11_25.md`) so we avoid duplicate work.
- **Share actionable next steps** with a clear owner or priority. Prefer one bullet per item, referencing specific files or scripts.

## Handoff Template

Use this template in the docs below or in git comments so the next agent can resume quickly:

```
Session Date:
Files Touched:
Key Actions:
Automation Run:
Next Priorities (with `[P0/P1/P2/P3]`):
- [P1] <Target tracker/file/task> – short spec
- [P2] <Automation/script run> – note required env
Blockers / Notes:
```

## Suggested Habits

1. After finishing a chunk of work, run `python3 scripts/todo_sweep.py` plus any script you touched (`scripts/board_simulate.sh`, `scripts/finish_release.sh`, etc.) and record the command + failure/success status.
2. Update the `docs/todo/TODO_SESSION_CONTINUATION_2025_11_25.md` (or equivalent) entry with the template above so the next agent can see what happened.
3. If you seed new TODOs, note their dependencies in `docs/todo/todo_dependency_map.md` and mark their status in `docs/todo/todo_status_overview.md` (or add a dedicated section for “pending handoff”).

## Acknowledging Continuity

Codex will now check `docs/todo/TODO_SESSION_CONTINUATION_2025_11_25.md` and `docs/archive/session_2025_11_25/README.md` before beginning new actions. Please add short “Claude left off here” or “Claude requested X” entries under `## Continuation` or near your TODO updates whenever possible.

Feel free to expand this document with example entries if the workflow evolves (e.g., new automation scripts, extra docs to update). Finishing tight handoffs reduces redundant effort and keeps the TODO tracker meaningful.
