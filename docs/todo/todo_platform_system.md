# Platform System & Target TODOs

Tracks the higher-level platform system (targets/backends, OS integration points, deployment targets) so Hydra can support modules across Windows/Linux/macOS/FreeBSD plus embedded/virtualized runtimes.

## P1 - Platform Target Readiness
- **TODO [P1]:** Catalog each supported platform target (SDL, GLFW, Vulkan, Wayland, Windows, FreeBSD, macOS) including required libs/toolchains, build presets, and automation gating steps; reference `docs/todo/todo_platform_backends.md` and `docs/todo/todo_multiplatform_builds.md`.
- **TODO [P1]:** Define platform system APIs (plugin registration, capability queries, backend selection) and document them in `docs/system_platform_interface.md`.
- **TODO [P1]:** Ensure platform-specific installers/packaging scripts (Linux packages, Windows installer, macOS DMG) are anchored to this tracker so release automation knows what to trigger.
- **TODO [P1]:** Add automation notes for each platform target in the AI dashboard summary (link to tracker and instrumentation).

## P2 - Embedded / Virtual Targets
- **TODO [P2]:** Add support notes for embedded/virtualized targets (e.g., QEMU, Docker, VMs) including required kernel modules, virtualization flags, and automation hooks for running Hydra in constrained environments.
- **TODO [P2]:** Document how Hydra exposes OS-specific features (udev rules, systemd units, FreeBSD devfs, Windows service) per platform in this tracker so operations teams can configure them.
- **TODO [P2]:** Provide a capability table listing which targets have SDL/GL/Vulkan/Tunnel support plus automation status (CI health) for each.
- **TODO [P2]:** Add virtualization regression scripts (VM snapshots, hardware pass-through) and record failing targets in `out/platform_target_health.json` so AI dashboards can highlight unstable platforms.

## P3 - Expansion & Tools
- **TODO [P3]:** Plan future platform targets (e.g., Wayland, embedded Linux, RTOS) and ensure each proposal adds TODO rows here with automation references.
- **TODO [P3]:** Maintain platform-target release notes (per OS/target) in `docs/todo/todo_go_to_market.md` so marketing/docs know which platforms are polished vs experimental.
