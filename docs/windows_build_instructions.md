# Windows Driver Build Instructions

## MSVC Solution

- Visual Studio 2022 (or Build Tools) is required.
- The solution `drivers/windows/hydra_driver.sln` contains a driver project referencing `hydra_kmdf_stub.c`.
- The project supports Debug/Release x86 and x64 configurations; use `msbuild` to build both.

## Command-line build

```bash
./scripts/windows-build.sh
```

This script invokes `msbuild drivers/windows/hydra_driver.sln` twice (Win32 and x64). It fails if `msbuild` is missing or if the build outputs cannot be found.

## Outputs

- `build/windows/Win32/Release/hydra_driver.dll` (x86)
- `build/windows/x64/Release/hydra_driver.dll` (x64)

The installer script `scripts/windows-installer.sh` consumes these files and creates a simple INF-based bundle under `out/windows-installer/`.

## TODOs (from docs/todo/todo_mesa_drivers.md)

- Document the MSVC configurations in `docs/todo/todo_mesa_drivers.md`.
- Keep `scripts/test_litex_stubs.sh` in the loop to verify the stub RTL under the same environment.
