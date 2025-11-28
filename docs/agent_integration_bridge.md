# Agent Coordination Bridge

This repo currently sees work from multiple AI instances/teams. To keep the handoff between Claude, Codex, and any other helpers tight, document the key steps here so every agent knows what was touched, what is pending, and what to run next.

## Key Concepts

- **Snapshot the work state/intent** before an agent shuts down: include recent commands, files touched, TODO targets, automation scripts run, and any blockers encountered.
- **Reference existing session docs** (e.g., `docs/archive/session_2025_11_25/README.md` or `docs/TODO_SESSION_CONTINUATION_2025_11_25.md`) so we avoid duplicate work.
- **Share actionable next steps** with a clear owner or priority. Prefer one bullet per item, referencing specific files or scripts.

## Inter-AI Client Interaction

- **Align on the shared instructions** before tinkering: review `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, and `docs/ai_resource_strategy.md` to understand the repo structure, build/test commands, and AI probe requirements each client should honor.
- **Keep the TODO trackers synchronized** by updating `docs/TODO_SESSION_CONTINUATION_2025_11_25.md`, `docs/TODO_MASTER_INDEX.md`, and the relevant tracker file (e.g., `docs/todo/todo_ai_development.md`, `docs/todo/todo_extension_interface.md`) with your priority tag and next action(s) before handing back control.
- **Document exclusive or high-risk work** (e.g., sim outputs, automation changes) with a reference to `docs/issue_draft_lock_coordination.md`, noting if you temporarily “lock” a resource or run long jobs so future agents can coordinate without stepping on each other.
- **Actionable handoff checklist**:
  1. Run `scripts/todo_sweep.py`, `scripts/check_required_files.py`, and `scripts/ai_session_report.py`; archive the outputs in `out/` (e.g., `out/ai_health_dashboard.txt`) and cite them in the continuity log along with the edited files.
  2. Tag the affected tracker entry with the `[P*]` priority (and owner if known) and mention the next logical task plus any blockers in the bridge’s continuity notes.
  3. Point the next client at the scripts or docs they should keep in sync (e.g., `docs/todo/todo_status_overview.md`, `out/meta_dependency_failures.txt`) so they can re-run the same probes if needed.
  4. If you hit missing tooling or conflicting edits, log the failure in `docs/todo/todo_status_overview.md` and mention it here so a follow-up agent knows why they might need to take a different approach.

## Inter-AI Coordination Log

- **Session Date:** 2025-11-26 (this update)
  - **Files Touched:** `docs/agent_integration_bridge.md`, `AGENTS.md`, `CODEX.md`, `docs/agent_template.md`
  - **Key Actions:** Created comprehensive CODEX.md documentation, updated AGENTS.md to properly document multiple agents, added agent_template.md for future agent onboarding, updated agent integration bridge references
  - **Next Priorities:** Consider adding documentation for additional AI agents (Cursor, Windsurf, etc.), implement external chat client integration webhook handler
  - **Blockers / Notes:** None - agent documentation suite now complete for Claude and Codex

## Handoff Template

Use this template in the docs below or in git comments so the next agent can resume quickly:

```
Session Date: 2025-11-27
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

## AI Session Reports

`scripts/ai_session_report.py` writes a short log of each AI interaction at the bottom of this doc. Run the script (or let a CI job do it) after each session so we track:

- Tools run (`scripts/check_build_requirements.py` with General host tooling + Simulation components).
- TODO metadata freshness (`scripts/todo_metadata.py` + top unknown/TODO trackers).
- Git HEAD/status snapshots for auditing.

The log entries are appended in the format used by the script, so reviewers can trace automation runs and quickly see which trackers still need attention.


### AI Session Report - 2025-11-26T05:35:14.956047Z
- Git HEAD: ff9e89243b7233cfda8e99f842b422da179badcd (status 0)
- Git status exit 0: ## main...origin/main [ahead 9] M docs/agent_integration_bridge.md M scripts/automation_watchdog.sh ??…
- Requirement (General host tooling): exit 0; General host tooling ✅ C compiler (gcc or clang) ✅ Make ✅ CMake (>=3.20) ✅ Ninja (optional but recommended) ✅ Python 3 ✅ pip3 ✅ Git ✅ pkg-config All checked…
- Requirement (Simulation): exit 0; Simulation (Verilator + SDL2) ✅ Verilator (5.x) ✅ SDL2 runtime (`sdl2-config`) ✅ SDL2_ttf via pkg-config All checked requirements present.
- Top unknown-priority trackers: todo_rendering_pipeline.md (22 unknown entries), TODO_SESSION_CONTINUATION_2025_11_25.md (17 unknown entries), todo_system_summary_2025_11_25.md (15 unknown entries)
- Top TODO-loaded trackers: todo_master.md (115 TODOs), todo_testing_ci.md (75 TODOs), todo_board_hardware_design.md (64 TODOs)


### AI Session Report - 2025-11-26T05:43:15.111036Z
- Git HEAD: 10277ff26c04172c9676d07d9513455ca382a059 (status 0)
- Git status exit 0: ## main...origin/main [ahead 2] M docs/ai_resource_strategy.md M docs/ci_automation_overview.md M…
- Requirement (General host tooling): exit 0; General host tooling ✅ C compiler (gcc or clang) ✅ Make ✅ CMake (>=3.20) ✅ Ninja (optional but recommended) ✅ Python 3 ✅ pip3 ✅ Git ✅ pkg-config All checked…
- Requirement (Simulation): exit 0; Simulation (Verilator + SDL2) ✅ Verilator (5.x) ✅ SDL2 runtime (`sdl2-config`) ✅ SDL2_ttf via pkg-config All checked requirements present.
- Top unknown-priority trackers: todo_rendering_pipeline.md (22 unknown entries), TODO_SESSION_CONTINUATION_2025_11_25.md (17 unknown entries), todo_system_summary_2025_11_25.md (15 unknown entries)
- Top TODO-loaded trackers: todo_master.md (115 TODOs), todo_testing_ci.md (75 TODOs), todo_board_hardware_design.md (64 TODOs)
