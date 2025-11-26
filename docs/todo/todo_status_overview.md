# TODO Status Overview

This living document tracks the status of the biggest TODO areas so contributors can see which work is already in-progress, blocked, or ready-to-start.

| Tracker / Area | Status | Notes |
|----------------|--------|-------|
| `todo_system_fps.md` | **In Progress** | Instrumentation HUD + backend logging work is underway; planned nightly `hydra_fps_benchmark` CI job pending. |
| `docs/render_pipeline_layers.md` (optimizations) | **Candidate** | Fast-path ideas (lighting guard, HUD caching, bias mix simplification) are documented; need owners to pick one and implement. |
| `todo_ray_mechanics.md` | **Pending Review** | Broad dependency plan built; more detailed tasks (ray replay, structured HUD feeds) are waiting for prioritization. |
| `todo_rendering_pipeline.md` | **Blocked** | Depends on ray engine, depth buffer, and reemissure stability (see `todo_dependency_map.md`). |
| `todo_dma_trace_artifacts.md` | **In Progress** | Trace capture schema and report generator TODOs added; requires structured logging tracker outputs before closing. |
| `todo_build_ci.md` | **Ready** | Build/test enhancements scoped; needs sprint slot/nominated owner to pick up jobs arising from new FPS/dependency instrumentation. |

## How to Use

- **Update the row** for a tracker whenever status changes (e.g., mark “In Progress” when someone picks it up, “Blocked” when a dependency is still open).  
- **Add fresh entries** for new trackers or ongoing initiatives; include dependencies or blocking factors if relevant.  
- **Use this doc** as the canonical “What’s happening now” reference for daily stand-ups or sprint check-ins.  
