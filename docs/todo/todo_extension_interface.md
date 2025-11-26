# Unified Extension Interface TODOs

Focuses on designing a single extensibility layer across the system, driver, rendering, automation, content, and AI/automation subsystems. This tracker ensures future extensions use consistent APIs, lifecycle hooks, and documentation.

## P1 - Interface Specification
- **TODO [P1]:** Define the unified extension interface (“Hydra Extension API”) that covers:
  * driver hooks (PCIe, DMA callbacks)
  * libhydra bindings (C/C#/Rust/Python)
  * rendering pipeline extensibility (post-processing, backends)
  * automation/AI hooks (dashboard, metadata, AI session reports)
  Document the API in `docs/design_extension_interface.md` and link to `todo_system_design.md`.
- **TODO [P1]:** Create a set of extension lifecycle events (init, enable, disable, shutdown, health-check) and ensure every subsystem (driver, viewer, automation, content) can register callbacks via the same interface.
- **TODO [P1]:** Provide a driver-level plugin loader that enumerates extension metadata, validates licenses (refer to `todo_support_and_licensing.md`), and exposes standardized diagnostics via `/sys/devices/hydra`.
- **TODO [P1]:** Log extension usage (names, versions) to `out/extensions.json` and hook `scripts/ai_health_dashboard.py` to surface when new extensions are enabled so automation/tracking knows what's running.

## P2 - Tooling & Automation
- **TODO [P2]:** Build a CLI helper (`scripts/extension_registry.py`) that lists available extensions, cross-references `docs/todo/todo_dependency_map.md`, and verifies required trackers exist for each extension.
- **TODO [P2]:** Extend `scripts/todo_metadata.py` to include metadata about extensions (owner, sectors impacted, automation dependencies), feeding the AI dashboard.
- **TODO [P2]:** Create integration tests that load extensions (mocked) into the driver, simulator, and viewer, logging the health output into `out/extension_health.log`.
- **TODO [P2]:** Document how extension manifests tie into the AI dashboard/Go-to-market tracker for release planning, so enabling a new driver feature also surfaces marketing/backlog automation.

## P3 - Community & Growth
- **TODO [P3]:** Write a contributor guide for building extensions (driver, renderer, automation, content) referencing this tracker and `todo_ai_development.md` so new contributors follow the unified interface.
- **TODO [P3]:** Maintain a registry of approved extensions (IDs, maintainers, status) and keep it in sync with `docs/todo/todo_sector_map.json` so the system knows where each extension lives.
- **TODO [P3]:** Plan extension deprecation/removal workflow (versioning, migration docs, automation alerts) so the interface evolves safely.
