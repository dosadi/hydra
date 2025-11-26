# libhydra SDK TODOs

Tracks improvements to the libhydra userspace library (C API, bindings, docs) so host tooling remains ergonomic as Hydra surfaces expand (GL32/GL64, gaming integrations, automation).

## P1 - API Stability & Bindings
- **TODO [P1]:** Document libhydra public API (handles, ioctls, DMA helpers) with usage examples for C and Python consumers; link to `docs/todo/todo_support_and_licensing.md`.
- **TODO [P1]:** Create bindings for higher-level languages (Python, Rust, C#) and add TODO entries referencing `todo_content_creation` and `todo_design_gaming_integration` so automation knows which sectors rely on the bindings.
- **TODO [P1]:** Expose helper functions for GL32/GL64 texture updates so `docs/todo/todo_gl_support.md` can reference them and the AI dashboard can watch for regression when GL paths change.
- **TODO [P1]:** Harden libhydra error handling (returns, logging) and add debug helpers that dump CSR/watchdog info for downstream automation (linked to ai_dashboard scripts).

## P2 - Tooling & Tests
- **TODO [P2]:** Add libhydra unit tests running in CI (cross-platform) and capture coverage in `out/libhydra_coverage.json` so `scripts/ai_health_dashboard.py` sees test health.
- **TODO [P2]:** Provide a libhydra “health check” CLI that reports driver presence, CSR values, firmware version, and uploads the info via `scripts/ci_collect_logs.sh`.
- **TODO [P2]:** Document how libhydra packaging integrates with `docs/todo/todo_multiplatform_builds.md` and automate building wheels or packages for Linux/Windows/macos.

## P3 - Future Enablement
- **TODO [P3]:** Track ideas for libhydra-based service endpoints (gRPC/rest) for remote management and tie the concepts to `docs/todo/todo_go_to_market.md`.
- **TODO [P3]:** Add a libhydra changelog entry per release and surface metadata in this tracker so automation can include it in dashboards.
