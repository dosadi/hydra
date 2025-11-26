# TODO Dependency Map

This tracker documents how key TODO areas rely on one another so work can be sequenced safely. Each row below links a dependent tracker to the upstream items it consumes or needs stabilized before the dependent work can make progress.

| Dependent Tracker | Depends On | Notes |
|-------------------|------------|-------|
| `todo_system_fps.md` | `todo_rendering*.md`, `todo_simulation_viewer.md`, `todo_platform_backends.md` | FPS targets require the renderer/HUD metrics, viewer present pipeline, and backend timing stats to cooperate before regression checks are meaningful. |
| `todo_simulation_viewer.md` | `todo_rendering_debug.md`, `todo_ray_engine.md`, `todo_rendering_pipeline.md` | Viewer overlays and selection controls render the ray engine outputs, so refreshing visual toolchains should wait until ray math and pipeline instrumentation settle. |
| `todo_rendering_pipeline.md` | `todo_ray_engine.md`, `todo_depth_buffer.md`, `todo_reemissure.md` | Pipeline profiling assumes the ray marcher, depth buffers, and emissive wiring are stable; perf entries depend on the lower-level lighting behaviors being correct. |
| `todo_dma_trace_artifacts.md` | `todo_dma_pcie.md`, `todo_dma_structured_logging.md` | Trace artifact capture extends the DMA/PCIe coverage area and relies on structured logging APIs to ingest/annotate events. |
| `todo_build_ci.md` | `todo_testing_ci.md`, `todo_system_fps.md`, `todo_dma_trace_artifacts.md` | CI stability work depends on the broader testing matrix, FPS diagnostics, and DMA tracing so jobs can fail fast with actionable data. |
| `docs/driver_coverage_guide.md` | `todo_dma_hotplug.md`, `todo_dma_hang_policy.md`, `docs/driver_general_todo.md` | Driver bring-up guidance is incomplete until hotplug/hang policy docs are fleshed out and the general driver TODO list is updated with current foci. |
| `todo_ai_development.md` | `docs/mathematical_surface_analysis.md`, `todo_rendering_pipeline.md`, `todo_debugging_tools.md` | AI work touching rendering needs to reference the math analysis and debugging tool guidelines so the automation log remains consistent. |
| `todo_board_hardware_design.md` | `docs/mixed_signal_environment.md`, `scripts/board_simulate.sh` | Board/analog TODOs should wait for the mixed-signal environment doc and automation scripts to land so regressions produce reproducible artifacts. |
| `todo_debugging_tools.md` | `scripts/automation_watchdog.sh`, `scripts/ci_todo_rebalance.sh`, `scripts/board_simulate.sh` | Debug tooling often depends on automation scripts being wired into CI so new logs/artifacts are available before instrumentation work continues. |
| `todo_system_summary_2025_11_25.md` | `docs/todo/todo_session_continuation_2025_11_25.md`, `todo_project_structure.md` | Session summaries leverage continuation notes and project-structure TODOs to show next actions and automation context for future work. |

### How to Use this Map

- **Before tackling a dependent tracker**, review the upstream items in the table and note whether their TODOs are marked `[P0/P1]`. This avoids reworking work that relies on unstable foundations.  
- **When creating new trackers**, add a row here describing their dependencies (use relative links like `todo_xyz.md`).  
- **Automated tooling** can parse this doc (simple Markdown table) to compute a dependency-weighted backlog for rebalance scripts like `scripts/todo_rebalance.py`.
