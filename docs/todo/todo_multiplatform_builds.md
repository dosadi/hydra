# Multiplatform Build Support TODOs

Improve parity across Linux, FreeBSD, macOS, and Windows host builds.

- TODO [P0]: Add CI matrix entries (best-effort) for FreeBSD/macOS/Windows host builds of libhydra/tools, capturing dependency notes and failures.
- TODO [P0]: Document platform-specific deps/flags (SDL2/TTF install paths, pthread/WSL quirks, Homebrew/MacPorts packages) in `docs/platform_backends.md`.
- TODO [P1]: Provide cross-compile presets/toolchain files (MinGW/clang-cl) for Windows DLL builds and test the sample tools.
- TODO [P1]: Add FreeBSD `make check` target parity (driver stub + userspace tools) and note kernel headers/module build steps.
- TODO [P1]: Add macOS build notes for SDL/GL backends and gate unsupported backends with clear errors.
- DONE [P1]: Provide platform-specific bootstrap scripts (`scripts/setup_macos_env.sh`, `scripts/windows-env.ps1`) that install SDL2/TTF/Python deps and document usage in `docs/macos_windows_build.md`.
- TODO [P2]: Bundle a minimal CI smoke script to run `sim_voxel --help`, `hydra_* --help`, and libhydra unit tests on each platform where available.
- TODO [P2]: Create a platform capability table (supported backends/features per OS) and link it from README.
- DONE [P1]: Add dedicated CMake presets/scripts for macOS (`cmake/presets/macos-default.json`) and Windows (`cmake/presets/windows-msvc.json`) and register them in `CMakePresets.json`.
- TODO [P1]: Add a Hydra cross-platform bootstrap script that sets up per-platform toolchains (Linux, FreeBSD, macOS, Windows) via `scripts/bootstrap_build_env.sh` and records the commands in `docs/ai_resource_strategy.md` for AI prep.
- TODO [P2]: Provide sanitized Docker + Nix containers for each platform that can run `cmake --preset` and ensure `scripts/ai_health_dashboard.py` sees the platform-specific tracker updates.
- TODO [P2]: Create cross-platform unit/regression wrappers (`scripts/build_matrix.sh`) that iterate over `CMakePresets` and record successes/failures in `out/build_matrix.log` with quick summaries for the AI dashboard.
- TODO [P3]: Add virtualization support notes (QEMU for FreeBSD, Parallels for macOS, WSL for Windows) describing how to run Hydra builds/test frameworks inside each virtualization/compatibility layer.
