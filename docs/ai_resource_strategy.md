# Efficient AI Resource Usage for Hydra

This reference captures how to get the most value from your paid AI instances while keeping the Hydra TODO system, docs, and automation in sync.

## 1. Pre-work checklist (run before each AI session)

1. **Run the lightweight environment probes**:
   - `python3 scripts/check_build_requirements.py --component "General host tooling"`
   - `python3 scripts/check_build_requirements.py --component Simulation`
   - `python3 scripts/todo_metadata.py --output docs/todo/todo_tracker_metadata.json`
   This ensures the tools mentioned in `docs/PACKAGE_REQUIREMENTS.md` are available and the metadata describing every tracker is fresh for the AI to reason about.

2. **Capture the starting state**:
   - `git status -sb && git diff --stat`
   - Save the outputs in a short note or append to `docs/agent_integration_bridge.md` under a fresh “Snapshot” entry.
   - If you expect the AI to seed TODOs, copy the relevant tracker subset so the model can cite the current context.

3. **Feed the AI the summary**:
   - Provide the AI with the latest `docs/todo/todo_tracker_metadata.json` (or a filtered subset) and the log of the probes above.
   - Highlight high-priority trackers (`todo_dma_pcie.md`, `todo_ray_engine.md`, etc.) using the metadata counts.
   - Reference the continuity log in `docs/TODO_SESSION_CONTINUATION_2025_11_25.md` so the AI knows what Claude/Codex previously worked on.

## 2. While the AI is working

- Ask the AI to limit changes to one top-priority area per pass; seed a single `[P*]` entry at the end of the relevant tracker after it proposes edits.
- Have the AI run `python3 scripts/todo_sweep.py` and `scripts/check_required_files.py` just before finishing to keep counts accurate.
- If automation fails (e.g., missing binaries), log the exact command and error in the Continuity Log or `docs/agent_integration_bridge.md`.

## 3. Post-work steps

1. **Record actions**:
   - Use the Agent Bridge template (`docs/agent_integration_bridge.md`) to note the commands run, files touched, and next priorities.
   - Add a short entry in `docs/TODO_SESSION_CONTINUATION_2025_11_25.md` under “Continuity Log” so the next agent sees the outcome.

2. **Update TODOs**:
   - If the AI touched `docs/todo/*.md`, add a matching `[P*]` bullet describing what changed and why (owner notes help); consider linking to `docs/ai_resource_strategy.md`.
   - Mark the tracker(s) in `docs/todo/todo_dependency_map.md` to keep dependencies current.

3. **Verify automation**:
   - Rerun `python3 scripts/todo_sweep.py` and `python3 scripts/check_todo_unique.py`.
   - If any script output changed (new unknown counts or requirement warnings), document them as part of the follow-up TODO in this tracker.

## 4. Suggested automation ideas

- Add a CI job that runs `python3 scripts/todo_metadata.py` and publishes the JSON as an artifact; link to the job from `docs/ai_resource_strategy.md`.
- Expand `scripts/automation_watchdog.sh` to call `scripts/todo_metadata.py` so the metadata is always fresh when automation runs.
- Build a helper that merges the metadata into a “priority briefing” (e.g., top 5 unknowns + high TODO counts) and prints it for the AI before you start a session.

## 5. Continuous improvement

- Periodically review this document and the “AI Development” tracker to ensure the workflows listed there (prompt validation, automation logs, etc.) remain accurate.  
- If you find redundant tasks, add TODOs to `docs/todo/todo_ai_development.md` referencing this doc so future agents can refine the strategy further.
