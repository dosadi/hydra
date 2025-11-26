# Hydra 0.0.7 Release Notes

## Highlights
- Completely reorganized the TODO/tracker system under `docs/todo/`, added dependency/status dashboards, and captured new render/FPS/AI/project-structure TODOs so contributors can discover work faster.
- Built render instrumentation: the raycaster now records RGB range stats, HUD shows FPS/hit counters, and `scripts/todo_sweep.py` + `scripts/check_*` enforce tracker/TOC sanity for each CI run.
- Added AI documentation, GitHub workflow TODOs, project-structure trackers, and scripts that ensure the tree layout and tracker references stay in sync.

## Tooling & Infrastructure
- `scripts/check_required_files.py` now enforces tracker references from `docs/TODO_MASTER_INDEX.md`.
- `scripts/todo_sweep.py` scans every `docs/todo/todo_*.md`; new `docs/todo/todo_master.md` duplicates guard duplicates.
- Added `docs/render_pipeline_layers.md`, `docs/todo/todo_system_fps.md`, `docs/todo/todo_project_structure.md`, `docs/todo/todo_ai_development.md`, and supporting metadata so FPS/debug instrumentation and tree rules have explicit TODOs.

## Documentation & Releases
- `docs/TODO_README.md` and `docs/TODO_MASTER_INDEX.md` now point at the reorganized tracker folder, include the dependency map, and link the status/AI docs.
- Structured logging (RGB ranges, HUD stats) is now ready for Machine/CI consumption; release candidates should rerun `scripts/check_required_files.py`, `scripts/check_todo_unique.py`, and `scripts/todo_sweep.py` before tagging.

## Testing Recommendations
- `make` (top-level) – builds the Verilator sim; expect the usual warnings about bit widths.  
- `python3 scripts/todo_sweep.py`, `python3 scripts/check_required_files.py`, `python3 scripts/check_todo_unique.py` – sanity-check TODO trackers and deduplicate entries.
- Optional viewer run: `cd sim && ./sim_voxel` (not run here; run to confirm HUD/FPS overlays and the new RGB-range readout display correctly).
