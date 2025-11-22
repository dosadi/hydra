# Windows/MinGW Build & Sim Notes

Host-side builds (libhydra + tools) use CMake; the RTL/SDL sim remains Makefile-driven and is easier on Linux/WSL.

## Host builds (MSVC)
```bash
cmake --preset windows-msvc
cmake --build build/windows
```
Builds `libhydra` (and POSIX tools are skipped on Windows).

## MinGW/MSYS2 prerequisites
- Packages: `mingw-w64-ucrt-x86_64-gcc`, `mingw-w64-ucrt-x86_64-SDL2`, `mingw-w64-ucrt-x86_64-SDL2_ttf`, `mingw-w64-ucrt-x86_64-ninja` (optional for CMake).
- Verilator 5.x (build from source or use a prebuilt package if available).
- `sdl2-config` may be absent; set `SDL_CFLAGS`/`SDL_LIBS` manually for the sim:
  ```bash
  export SDL_CFLAGS="-I/mingw64/include/SDL2 -D_REENTRANT"
  export SDL_LIBS="-L/mingw64/lib -lSDL2 -lSDL2_ttf"
  ```

## Sim build (experimental on Windows/MinGW)
```bash
cd sim
make VERILATOR=<path-to-verilator> CXX=g++ SDL_CFLAGS="$SDL_CFLAGS" SDL_LIBS="$SDL_LIBS"
```
Notes:
- Verilator on Windows is community-supported; expect warnings. WSL2/Linux is recommended for the sim.
- Cocotb smoke (`sim/tests/cocotb_hydra`) is best run on Linux/WSL2; Windows flows require a compatible simulator/Python environment.

## WSL2 option
If native Windows tooling is cumbersome, use WSL2 with the Linux instructions (`make`, `make SIM=icarus` for cocotb, `cmake --preset linux-default`).
