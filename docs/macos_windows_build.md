# macOS & Windows Build Notes

Document the environment quirks and next steps required to keep the Hydra host tools cross-platform.

## macOS (Apple Silicon / Intel)

- **Current status:** Clang/LLVM toolchain works for CMake (using `cmake --preset linux-default` with `CMAKE_C_COMPILER=clang`, `CMAKE_CXX_COMPILER=clang++`). SDL/glad dependencies are satisfied via Homebrew (`brew install sdl2 sdl2_ttf python3`).
- **Todo:** Create a `cmake/presets/macos-default.json` with preconfigured SDL/FreeType/PKGCONFIG paths and document the `scripts/setup_macos_env.sh` bootstrap script that installs Homebrew deps + Python packages (`cocotb`, `pytest`).
- **Todo:** Ensure `CMAKE_SYSTEM_NAME` stays `Darwin` when building libhydra so `#include <mach/mach.h>` logic is guarded, and add a `HYDRA_EXPORT` macro for Win/mac dylib exports.
- **Todo:** Document Apple-specific sanity checks (Homebrew prefix, SDL2 `pkg-config` path, how to run `cmake --build`/`ninja`) in this file and link from README.

## Microsoft (MinGW64 / MSVC)

- **Current status:** MinGW64 (with `gcc`, `g++`, `pkg-config`) can build the SDK via `cmake --preset linux-default` if the toolset is overridden and SDL2 is installed with `vcpkg` or DLL drop-in. MSVC/Visual Studio requires rewriting `Makefile` targets to use `cl.exe` and `nmake`.
- **Todo:** Add a Windows preset (`cmake/presets/windows-msvc.json`) that sets `SDL2_INCLUDE_DIR`, `SDL2_LIBRARY`, and `VULKAN_SDK` stubs if needed. Document the `cl` flags required and how to run `hydra_pcie_drv.sln`.
- **Todo:** Provide a small PowerShell script (or batch) under `scripts/windows-env.ps1` to install dependencies via `choco install sdl2 sdl2-ttf python3` and describe how to integrate its environment with `cmake --preset windows`.
- **Todo:** Capture common linker issues (no `-pthread`, MSVC `WS2_32` dependencies) and note them in this file for the driver and libhydra builds.

## Testing & CI

- **Todo:** Add a macOS/Windows job in CI (best-effort) that runs `cmake --preset macos-default && cmake --build build/macos && cmake --preset windows-msvc && cmake --build build/windows`, even if vanilla `make` targets fail.
- **Todo:** Document how to run `sim_voxel` on macOS/Windows (SDL backend choice, env overrides for `HYDRA_BACKEND`, `HYDRA_FONT`) and how to set `PATH` for bundled DLLs.

## Next steps

- Keep this doc in sync with `docs/todo_multiplatform_builds.md`. When you decide to tackle a TODO above, mark it completed with pointers to the commits or scripts that fulfil the requirement.
