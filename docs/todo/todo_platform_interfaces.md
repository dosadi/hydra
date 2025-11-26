# Platform Interfaces & Subplatform TODOs

Tracking the variety of viewer/runtime interfaces (SDL, headless, remote-control, automation, legacy APIs) and their platform-specific subtypes.

- TODO [P1]: Outline a clear catalog of supported platform interfaces (SDL viewer, VNC, REST control, CLI dump, legacy VGA, DirectX/Metal/Wayland backends) and expose it via `docs/todo/todo_platform_backends.md`.
- TODO [P2]: Draft adaptor guidelines so new subplatform implementations can register themselves (name, capabilities, dependencies) via a table under `docs/todo/todo_sector_overview.md`.
- TODO [P1]: Add CI smoke coverage that iterates each platform interface, runs its basic startup/teardown, and reports success, failing through `scripts/automation_watchdog.sh` for quick triage.
- TODO [P2]: Split the viewer configuration into subtypes (SDL, headless, automation, remote) with shared base code and plugin-like extensions; capture the design in `docs/todo/todo_project_structure.md`.
- TODO [P2]: Track dependencies between platform interfaces and renderer subsystems (lighting, DMA, ray engine) via `docs/todo/todo_dependency_map.md` so rebalance proposals can enforce coverage.
- TODO [P3]: Document how platform-specific hooks tie into driver stacks (SDL ⇄ X11/Wayland, VNC ⇄ framebuffer emulation, CLI-targeted `render_pipe`) and expose troubleshoot steps in `docs/todo/todo_status_overview.md`.
- TODO [P3]: Seed automation for interface adoption by adding metadata to `out/todo_tracker_metadata.json` (via `scripts/todo_metadata.py`) whenever new subplatform TODOs land.
- TODO [P2]: Build a map of platform interface performance characteristics (latency, CPU load, GPU load) and include it in `docs/todo/todo_system_fps.md` as part of the `fps_health` dashboards.
- TODO [P3]: Schedule a monthly audit of platform interfaces to ensure driver compatibility across host OSes and GPU vendors, recording findings back into this tracker for continuity.
