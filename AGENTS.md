# Repository Guidelines

## Project Structure & Module Organization
- RTL SystemVerilog lives in `../rtl` with `voxel_framebuffer_top.sv` as the DUT; simulation harnesses live in `sim/`.
- `sim/Makefile` drives Verilator + SDL2 builds; `live_sdl_main.cpp` is the interactive viewer harness that applies camera/flag inputs and displays frames.
- Build outputs land in `sim/obj_dir/` and the `sim/sim_voxel` executable; clean with `make clean` to reset.

## Build, Test, and Development Commands
- `cd sim && make` – Verilates the top module and builds `sim_voxel` (uses `verilator`, `g++`, `sdl2-config`, and `SDL2_ttf`).
- `cd sim && VERILATOR=<path> make` – override toolchain if a non-default Verilator is installed.
- `cd sim && ./sim_voxel` – run the interactive viewer (WASD/mouse to move; number keys toggle render flags).
- `cd sim && make clean` – remove generated artifacts (`obj_dir`, `sim_voxel`).

## Coding Style & Naming Conventions
- C++: prefer 4-space indents, snake_case for variables and lambda names, and short helper lambdas over macros; keep SDL/Verilator setup and event handling organized into small blocks.
- SystemVerilog: keep signal and module names in snake_case; use descriptive prefixes (`cam_`, `cfg_`, `sel_`, `dbg_`) consistent with `voxel_framebuffer_top`.
- Keep includes ordered by library, then project headers; avoid trailing whitespace and align with existing formatting in `live_sdl_main.cpp`.

## Testing Guidelines
- Primary verification is the SDL-based simulation. Build with `make` and exercise rendering paths via movement and flag toggles; watch stdout/stderr for assertions or SDL errors.
- If you add RTL that should be inspected, enable Verilator tracing (already set with `--trace`) and review VCDs in `obj_dir`.
- Add small, targeted checks inside the harness (e.g., validating camera ranges) rather than broad test frameworks unless you introduce them.

## Commit & Pull Request Guidelines
- Use short, imperative commit subjects (e.g., `Improve camera clamp logic`, `Add selection HUD text`); keep scope tight.
- In PRs, include a brief summary of changes, how you validated them (`make`, `./sim_voxel` interactions), and any new dependencies or flags.
- Link related issues where applicable and include screenshots or short notes for UI/runtime-facing changes (viewer behavior, controls, HUD updates).

## Dependencies & Environment
- Requires `verilator`, `g++`, `make`, `SDL2`, and `SDL2_ttf`; ensure `sdl2-config` is on `PATH`.
- Fonts: harness defaults to `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`; adjust if your distro differs or include a path override when adding font options.
