# 3D Blitter & Voxel Manipulation TODOs

Tracks the current 3D blitter utility plus the broader functionality it should evolve into (scene updates, streaming, giant DMA moves) so we can treat it as a general voxel manipulation engine.

## P1 - Blitter Modernization
- **TODO [P1]:** Document the 3D blitter’s current capabilities (copy volume, fill region) and define the “next-gen” feature set (scene stitching, voxel streaming, micro batching) in `docs/voxel_pipeline.md`.
- **TODO [P1]:** Add CTA to the AI dashboard by logging 3d blitter usage metrics (ops/sec, bytes moved) via `scripts/ai_health_dashboard.py`.
- **TODO [P1]:** Enhance the blitter DSL so scripts can define sequences (transform, copy, merge) that map to higher-level “scene update” APIs for game engine integrations described in `docs/design_gaming_integration.md`.
- **TODO [P1]:** Provide interactive viewer tools (HDR UI or Python wrapper) that call the blitter for world-editing operations, logging each action so automation can replay them.

## P2 - Generalized Voxel Operations
- **TODO [P2]:** Evolve the blitter into a general voxel data mover (copy, fill, move, streaming upload) with configurable rate limits; document the API and tie to `todo_system_fps.md` so automation understands perf trade-offs.
- **TODO [P2]:** Add DMA-friendly metadata (region handles, bounding boxes) so the blitter can work with hardware RLE compression (`todo_rle_compression.md`) and streaming loaders.
- **TODO [P2]:** Build integration tests that exercise the blitter from the Linux driver, libhydra, and simulation viewer, ensuring each pathway logs events to `out/blitter_events.json` for analytics.
- **TODO [P2]:** Expose blitter macros/DSL via the AI dashboard so team members can record scripted updates and re-run them while tracking TODO counts for each scenario.

## P3 - Streaming, Clustering & Blitter Automation
- **TODO [P3]:** Allow the blitter to work across multiple Hydra boards (clustered blit), distributing region handles and coordinating DMA (tie into `docs/todo/todo_clustering.md`).
- **TODO [P3]:** Automate blitter workload reports (counts, bytes, errors) into `docs/todo/todo_testing_ci.md` so regression scripts know when to rerun blitter-heavy workloads.
- **TODO [P3]:** Create a “blitter readiness” doc that outlines what extra hardware (DMA engines, memory) is required and how the general blitter functionality helps integrate with games and rendering pipelines.
