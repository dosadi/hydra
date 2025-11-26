# Hydra Platform Backends TODOs (SDL/GL/Vulkan/Wayland/X11/Headless) - 0.0.7 Cycle

**Focus:** Backend testing and validation, multi-platform stability.
See `docs/TODO_MASTER_INDEX.md` for complete tracker reference.

**Related Trackers:** `todo_multiplatform_builds.md`, `todo_testing_ci.md`, `todo_simulation_viewer.md`

**Completed in 0.0.6:** CLI backend override, HUD info display, backend probe script, triage guide, window resize handling.

---

## P0 - Critical (All Complete)

- DONE [P0]: Add a short "backend triage" guide (common errors + fixes) linked from startup logs (`docs/backend_triage.md`).
- DONE [P0]: Provide a scripted backend probe (`scripts/check_backends.sh`) that prints available video drivers and exits non-zero on mismatch (skips if SDL missing).
- DONE [P0]: Add a CI note to skip GL/Vulkan tests when drivers are missing, but still capture backend capability logs as artifacts (documented in `docs/platform_backends.md`).
- DONE [P0]: Surface backend choice and vsync status in the HUD so recordings show which path was used (HUD line added in sim).
- DONE [P0]: Handle window resize events gracefully (recreate textures, clear framebuffer) across backends (SDL path recreates texture + clears fb on resize).
- DONE [P0]: Add a backend selection CLI flag (in addition to env) for scripting (`--backend`/`-b`).
- DONE [P0]: Implement a backend preference order that prefers compiled GPU backends and falls back cleanly (HYDRA_BACKEND_PREFS env to override order).
- DONE [P0]: Add a "backend summary" printed at exit (frames rendered, backend used, vsync state).
- DONE [P0]: Add a guard to warn/fail when requested backend isn't compiled in (clear stderr message for HYDRA_BACKEND).

## P1 - High Priority (Validation & Stability)

**Dependencies:** Requires P0 backend selection infrastructure

- TODO [P1]: Add a unit test that exercises backend selection precedence (CLI > env > compiled availability) to prevent regressions. *Critical for: release testing*
- TODO [P1]: Expand backend support matrix and document which platforms are exercised in CI vs. untested. *Blocking: multi-platform support*
- TODO [P1]: Add better detection/logging of available backends (GL/Vulkan/X11/Wayland) with fallbacks noted. *Depends on: P0 backend probe*
- TODO [P1]: Implement headless backend parity (frame dumps, HUD toggles) and add a CI smoke for it. *Blocking: CI regression testing*
- TODO [P1]: Add backend-specific error logs (e.g., missing SDL_ttf, GL init failures) with actionable hints. *Critical for: user experience*
- TODO [P1]: Provide a "minimal backend smoke" target that builds/runs SDL-only for quick checks. *Critical for: CI*
- TODO [P1]: Add a platform capabilities dump (GPU/driver versions, SDL/GL/Vulkan availability) printed at startup. *Related to: debugging*
- TODO [P1]: Add CI smoke for SDL+GL (when available) to catch backend-specific regressions. *Critical for: release testing*
- TODO [P1]: Provide startup logging of SDL/GL/Vulkan versions and detected drivers for repros. *Related to: P1 capabilities dump*

## P2 - Medium Priority (Testing & CI Infrastructure)

**Dependencies:** Requires P1 smoke tests and validation

- TODO [P2]: Add VSYNC toggle exposure in HUD/backends and ensure renderer flags reflect it.
- TODO [P2]: Add resize handling tests (manual bench) to ensure backends recreate textures/buffers correctly.
- TODO [P2]: Provide a fallback font detection/log when TTF init fails, per backend.
- TODO [P2]: Implement a headless "batch render N frames" mode and add a CI artifact upload for PPMs. *Depends on: P1 headless parity*
- TODO [P2]: Add debug flags to log backend-specific timing (present, texture upload) for perf tuning.
- TODO [P2]: Add backend-specific environment overrides (e.g., GL/Vulkan validation layers) and document.
- TODO [P2]: Provide a backend health check at startup (init + dummy present) with clear error messages.
- TODO [P2]: Add a HUD/backlog message when falling back from a requested backend to SDL.
- TODO [P2]: Implement Wayland/X11 input handling parity checks (mouse capture toggle behavior).
- TODO [P2]: Add a "backend info" HUD overlay showing current backend, vsync, capabilities.
- TODO [P2]: Add a CLI/env knob to select SDL video driver (x11/wayland/dummy) explicitly.
- TODO [P2]: Add a bench that simulates backend init failure and confirms fallback behavior.
- TODO [P2]: Implement a "headless verify" mode that renders N frames to PPM without creating a window.
- TODO [P2]: Add CI artifact capture of backend logs (stderr) when backend selection fails.
- TODO [P2]: Add a small unit test to ensure HYDRA_BACKEND parsing is case-insensitive and defaults correctly.
- TODO [P2]: Provide a doc section on backend env vars (HYDRA_BACKEND, SDL_VIDEODRIVER, validation flags).
- TODO [P2]: Add coverage for backend-specific key/mouse mapping consistency (e.g., Wayland vs. X11).
- TODO [P2]: Implement a "backend quiet" mode to suppress non-fatal warnings during batch runs.
- TODO [P2]: Add a script to exercise backends with `--help` or dry-run modes for CI availability checks.
- TODO [P2]: Provide a fallback font search path per platform to reduce HUD init failures.
- TODO [P2]: Add coverage for window focus/alt-tab handling across backends (mouse capture restore).
- TODO [P2]: Implement a backend watchdog that tears down/reinits on repeated present failures.
- TODO [P2]: Add a CI note on required packages/libs per backend (GL/Vulkan/X11/Wayland) for repros.
- TODO [P2]: Add a HUD toggle to display backend timing stats (fps, present latency, texture upload).
- TODO [P2]: Provide env flags to force software rendering paths (e.g., SDL_RENDER_DRIVER=software) for debugging.
- TODO [P2]: Add a tiny backend self-test that loads font, creates texture, presents one frame, and exits.
- TODO [P2]: Implement per-backend cleanup to ensure resources are freed (avoid leaks across runs).
- TODO [P2]: Add a backend-specific logging prefix in stderr to ease triage in CI logs.
- TODO [P2]: Add a CI matrix entry to run backend smokes on multiple SDL video drivers (x11/wayland/dummy).
- TODO [P2]: Provide a troubleshooting section for common backend errors (Wayland permissions, Vulkan loader missing).
- TODO [P2]: Add coverage for backend selection precedence (env vs. CLI vs. compiled availability). *Related to: P1 unit test*
- TODO [P2]: Provide a script to list available backends and their compile/runtime status.
- TODO [P2]: Add a CI artifact that captures backend capabilities dump and HUD screenshot on failure.
- TODO [P2]: Add coverage for audio/no-audio startup paths to ensure SDL init doesn't block on audio devices.
- TODO [P2]: Add watchdogs/timeouts around backend init to avoid hangs when drivers misbehave.
- TODO [P2]: Provide a "backend retry" path if init fails once (try SDL fallback automatically).
- TODO [P2]: Add a bench to simulate missing fonts/resources and ensure graceful degradation (HUD off, warnings).
- TODO [P2]: Document known backend limitations (e.g., Vulkan path stability) and update README accordingly.
- TODO [P2]: Add a CI lint/check that required backend libs are present (or jobs are skipped with a clear reason).
- TODO [P2]: Add a debug toggle to dump SDL/GL/Vulkan extension lists for troubleshooting.
- TODO [P2]: Provide a per-backend "capabilities JSON" export for CI artifacts.
- TODO [P2]: Add coverage for window creation flags (fullscreen/borderless) to ensure consistent behavior.

## P3 - Low Priority (Advanced Features)

**Dependencies:** Requires P2 testing infrastructure

- TODO [P3]: Implement an env/hotkey to toggle between backends at runtime when supported (or log unsupported).
- TODO [P3]: Add a "help overlay" hotkey that shows backend selection keybinds and current backend.
- TODO [P3]: Implement per-backend hotkeys (e.g., toggle vsync) with consistent messaging.
- TODO [P3]: Implement a backend selector priority env var to tweak preference order without code changes.
- TODO [P3]: Add a "no-HUD" mode that still allows overlays (backend info) for clean screenshots.

---

## Priority Summary

- **P0:** 9 items (all DONE) - Foundation complete ✅
- **P1:** 9 items - Validation, CI infrastructure, error handling
- **P2:** 43 items - Comprehensive testing, coverage, tooling
- **P3:** 5 items - Advanced runtime features

**Next Steps:** Focus on P1 unit tests and headless backend for CI regression testing.

## Automation & Reporting Expansion

- **TODO [P2]:** Automate backend capability discovery (SDL/GL/Vulkan/Wayland) and emit `out/backend_capabilities.json` so dashboards know which backends are available per runner.
- **TODO [P2]:** Log backend selection stats (which backend wins per build) and surface them via `scripts/ai_health_dashboard.py` to highlight flaky paths.
- **TODO [P2]:** Add a backend triage log (`docs/backend_triage.md`) that correlates backend failures with TODO shifts for rapid triage.
- **TODO [P2]:** Wire virtualization/compat notes (QEMU, WSL, Parallels, VMware) into this tracker so replicating backend issues inside VMs is easier.
- **TODO [P3]:** Document multi-backend regression flows (how multiple backends interact) and reference these docs within the AI dashboard summary.
