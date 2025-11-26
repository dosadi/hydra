# Project Structure TODOs

Tracks cross-cutting housekeeping so the repo stays discoverable, sane, and friendly to new contributors.

- **TODO [P1]:** Draft a “project roadmap” landing page that links the TODO ecosystem to concrete milestones, owners, and sprint slots so contributors know where to jump in without digging through 40+ files.
- **TODO [P2]:** Extend `scripts/check_required_files.py` or add a companion script to verify every tracker referenced in `docs/TODO_MASTER_INDEX.md` actually exists under `docs/todo/` (not just a fixed list). Run it in CI so renames can't slip.
- **TODO [P2]:** Align the build toolchain by wrapping `sim/Makefile` + Verilator under a top-level CMake preset and cross-link the new macros in `README.md`/`docs/macos_windows_build.md`; this keeps tree navigation consistent between simulators, SDK tools, and platform jobs.
- **TODO [P2]:** Reference `docs/ci_automation_overview.md` (soon to replace the old automation doc snapshot) from automation TODOs so contributors know which scripts and workflow (automation watchdog, GitHub Action) gate their PRs.
- **TODO [P1]:** Feed the RGB-range + FPS stats (`sim/live_sdl_main.cpp` instrumentation) into a lightweight dashboard or nightly `scripts/todo_inspect.py` job so the repo exposes regressions before manual inspection.
- **TODO [P3]:** Broaden `docs/todo/todo_status_overview.md` into a tracker-agnostic “status board” that lists every domain tracker’s current state/owner so reviewers can immediately see what’s in progress vs. blocked.
- **TODO [P2]:** Add a `scripts/clean_tree.py` helper that removes generated dirs (`sim/obj_dir`, `cmake-build-*`) and warns when `git status` shows these cruft files, keeping the working tree predictable for contributors.  
- **TODO [P3]:** Warn when editing a tracker listed in `docs/todo/todo_dependency_map.md` without updating its dependents (e.g., via a pre-commit hook) so the dependency graph remains accurate.
- **TODO [P2]:** Create a “tree audit” script that diffs `git status` against a whitelist of safe paths and reports unexpected new files; run it from CI or as a pre-merge check for contributors who touch big folders.
- **TODO [P2]:** Provide a `docs/todo/tree_guidelines.md` page describing directory layout conventions, when to add new top-level folders, and how to keep the toc/master index synced so contributors follow the same structuring rules.
- **TODO [P2]:** Add a “structure health” JSON summary (from `scripts/todo_metadata.py`) that surfaces in the AI dashboard so the master file knows when directories expand/shrink drastically.
- **TODO [P3]:** Document the repository growth plan (new modules, product lines, architecture expansions) as part of this tracker so future contributors can drop a note when they add whole new subsystems.

## AI Development TODOs
- **TODO [P1]:** Document the prompt templates, tool commands, and workflow sequences used by AI agents so future automation can inherit/update the same practices.
- **TODO [P2]:** Track AI-generated diffs via `scripts/ai_diff_summary.py` (hypothetical) and reconcile them with TODOs automatically using `scripts/ai_todo_sync.py`.
- **TODO [P2]:** Add credit/log metadata in `README.md` or a dedicated AI section so maintainers know which patches came from AI tooling and when to review them more carefully.
- **TODO [P3]:** Publish an “AI dev roster” note clarifying the scope of AI-driven work vs. manual tasks (docs/TODO updates vs. RTL/driver work) for better handoffs.
-
## AI Development TODOs

## GitHub / CI TODOs
- **TODO [P1]:** Add a PR template that directs contributors to run `scripts/check_required_files.py`, `scripts/todo_sweep.py`, and `scripts/check_todo_unique.py` whenever they touch README/docs or rtl assets so GH reviewers can focus on logic changes.
- **TODO [P2]:** Build a GitHub Actions workflow that runs the full `make` + `scripts/check_required_files.py` / `scripts/todo_sweep.py` + `scripts/check_todo_unique.py` matrix plus `scripts/ci_todo_rebalance.sh` and this new `scripts/automation_watchdog.sh`, publishing rebalance artifacts and failing when trackers slip.
- **TODO [P3]:** Auto-generate GitHub issue templates tied to key trackers (FPS, rendering, DMA) so triage captures priority/context by referencing `docs/todo/todo_system_fps.md`, `docs/todo/todo_rendering.md`, etc.
- **TODO [P2]:** Link release notes + session summaries in `.github/README.md` (or a repository-level wiki) so the GitHub UI surfaces the latest state before a stakeholder opens a PR.
