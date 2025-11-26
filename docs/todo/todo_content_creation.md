# Content Creation & Export Toolchain TODOs

**Focus:** 3ds Max, Maya, Blender, and other creative tools used to craft demo scenes, assets, and tutorials for Hydra.

## Overview

Tracks pipelines for exporting voxel scenes, automating render capture, and keeping tutorials/demos in sync with the 3D tools that artists use. Includes renderer interoperability, material/export templates, and automation hooking into our AI/dashboard tooling.

## P1 - Artist Workflow & Export Automation

- **TODO [P1]:** Document the official Hydra export workflow for Blender/3ds Max/Maya (configuration, target format, environment setup) and publish it under `docs/content_creation.md`.
- **TODO [P1]:** Create Blender/Max/Maya export templates (scripts/presets) that produce Hydra-compatible voxel/mesh data along with metadata (camera, lighting, emissive flags) for the renderer.
- **TODO [P1]:** Add `scripts/export_demo_assets.sh` that drives the preferred tool CLI (Blender headless, Max batch, Maya batch) to bake demo scenes, record inputs, and stash outputs under `examples/` so automation has fixed inputs for regressions.
- **TODO [P1]:** Hook exported asset health into `scripts/ai_health_dashboard.py` by logging asset generation counts and warnings (missing textures, export failures) so the dashboard flags content pipeline issues.

## P2 - Tool Integration & Validation

- **TODO [P2]:** Build a Blender addon (or Maya/3dsMax script) that auto-tags exports with Hydra metadata (ID, emissive flags, HDR exposure) and therewith ensures consistent scene playback.
- **TODO [P2]:** Create regression scripts that load exported assets into Blender and replay them, generating frame dumps to compare against golden assets (`scripts/check_export_assets.sh` + AI dashboard).
- **TODO [P2]:** Capture HDR/config differences across tools (Blender vs Maya vs 3ds Max) and record them in `docs/camera_constants.md` for release notes; feed differences into AI automation.
- **TODO [P2]:** Add an asset dependency map linking Blender/Maya files to TODO trackers (rendering, demos, docs) inside `docs/todo/todo_dependency_map.md`.
- **TODO [P2]:** Automate asset metadata publishing (`scripts/export_asset_metadata.py`) that writes summary JSON consumed by `scripts/ai_health_dashboard.py` so asset health appears on the dashboard alongside code TODOs.
- **TODO [P2]:** Add a “content consistency” tracker in `docs/todo/todo_dependency_map.md` referencing Blender/Maya scenes tied to reemissure/hardening TODOs so the board knows when content updates need follow-up in performance/renderer trackers.

## P3 - Pipeline Extensions & Education

- **TODO [P3]:** Build tutorial videos (Blender/Max/Maya) showing how to author Hydra scenes, capturing the recorded macros and linking them to `docs/tutorials/content_creation.md`.
- **TODO [P3]:** Document a “3D tool regression checklist” referencing Hydra automation (AI dashboard + build reacquire) so rapid content changes feed the tracker.
- **TODO [P3]:** Explore generating animated demos directly from Blender/Maya that can be consumed by Hydra’s timeline/capture scripts (e.g., Hydra-specific camera paths or scripted scene toggles).
- **TODO [P3]:** Maintain a living art release note (via this tracker) listing scene updates, expected visual differences, and how they map to TODOs so the AI workflow knows the difference between a quick art tweak and a whole new demo suite.
