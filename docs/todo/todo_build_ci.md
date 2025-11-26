# Build & CI Reliability TODOs

Tracks the critical CI and release flow work from `todo_build_tooling.md`. This subset focuses on the high-priority infrastructure (P0/P1) that must be rock-solid for 0.0.7 builds.

**Session Reference:** See [`docs/TODO_SESSION_CONTINUATION_2025_11_25.md`](../TODO_SESSION_CONTINUATION_2025_11_25.md) "Immediate (Sprint 1)" for prioritized P0 action items from the TODO system expansion session.

- **P0:** Fix `make test_frame` flakiness immediately after `make clean` so CI can run clean builds consecutively.
- **P0:** Ensure `hydra_dev_loop.sh` exits non-zero on any building/testing failure (`set -e` and remove `|| true` usage).
- **P0:** Add multi-distro CI matrix (Ubuntu 20.04/22.04/24.04) with full test suite to guard kernel/drivers.
- **P0:** Pin Verilator >= 5.028 in CI and dev-loop, failing loudly on mismatches.
- **P0:** Log SDL2/SDL2_ttf version info in CI via `scripts/env_probe.sh`.
- **P1:** Add formatting/lint CI targets: `make fmt` (clang-format + verilator fmt), `make lint` (clang-tidy + verilator --lint-only), plus pre-commit hooks.
- **P1:** Add ccache/Verilator cache support in CI to halve wall time.
- **P1:** Add strict kernel driver builds (W=1, KCFLAGS="-Werror") as a CI job.
- **P1:** Upload frame diff logs/artifacts on failure for quick triage.
- **P1:** Create headless dummy backend CI job to avoid X11/GL dependencies.
- **P2:** Extend CI to nightly cocotb runs (`test-cocotb-nightly`).
- **P2:** Add SDL/GL/headless backend matrix jobs to cover rendering variants.
- **P2:** Add cross-compilation CI runs (aarch64, riscv64) for ARM/RISC-V preps.
- **P2:** Track performance regressions (frame time, build time) in CI with historical graphs.
