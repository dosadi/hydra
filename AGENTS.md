# AI Agent Documentation Suite

This repository supports multiple AI coding assistants. Each agent has specific guidance and coordination protocols documented below.

## Supported Agents

### Claude Code
- **Documentation**: `CLAUDE.md`
- **Primary Interface**: claude.ai/code
- **Specialties**: Comprehensive project understanding, documentation, multi-file changes
- **Coordination**: Updates `docs/agent_integration_bridge.md` for handoffs

### Codex CLI
- **Documentation**: `CODEX.md`
- **Primary Interface**: GitHub Copilot CLI
- **Specialties**: Terminal-based development, lock coordination, session management
- **Coordination**: Uses lock broker for multi-session safety, updates TODO trackers

### General Agent Guidelines
- **Documentation**: This file (`AGENTS.md`)
- **Applies to**: Any AI assistant working on the repository
- **Coordination**: Follow protocols in `docs/agent_integration_bridge.md`

## Agent Coordination Protocols

### Session Management
1. **Check current state**: Review `docs/agent_integration_bridge.md` and `docs/TODO_SESSION_CONTINUATION_2025_11_25.md`
2. **Run health checks**: Execute `scripts/todo_sweep.py` and `scripts/check_required_files.py`
3. **Document work**: Update continuity logs and TODO trackers
4. **Coordinate locks**: Use lock broker for shared resources (Codex CLI)

### File Organization
- **Agent-specific docs**: `CLAUDE.md`, `CODEX.md`, etc.
- **Coordination docs**: `docs/agent_integration_bridge.md`, `docs/ai_resource_strategy.md`
- **Lock coordination**: `docs/rfc/lock_coordination.md`, `prototypes/codex-lock-broker/`

### Adding New Agents
When adding support for a new AI agent:

1. Create `{AGENT_NAME}.md` in repository root
2. Follow the template structure from existing agent docs
3. Update this file to include the new agent
4. Add agent-specific coordination protocols to `docs/agent_integration_bridge.md`
5. Use `docs/agent_template.md` as a starting point for new agent documentation

## Repository Guidelines

## Project Structure & Module Organization
- `rtl/` houses the SystemVerilog core; `voxel_framebuffer_top.sv` is the top.
- `sim/` contains the Verilator + SDL viewer; harness in `sim/viewer.cpp`, platform backends in `sim/platform/`, outputs to `sim/obj_dir/` and `sim/sim_voxel`.
- `drivers/` host stubs (`drivers/libhydra`, `drivers/linux`, `drivers/bsd`); `scripts/` utility tools; `docs/` platform notes; `third_party/` vendored IP; `docker/` dev images.
- CMake presets build host libs/tools into `build/linux` or `build/windows`; RTL/SDL sim stays in `sim/` via Make.

## Build, Test, and Development Commands
- `make` – top-level alias for `cd sim && make`.
- `cd sim && make` – Verilate and build `sim_voxel` (needs `verilator`, `g++`, `sdl2-config`, `SDL2_ttf`).
- `cd sim && ./sim_voxel` – run the viewer (WASD/mouse flight; number keys toggle render flags; `F` selects a voxel).
- `cd sim && make clean` – drop `obj_dir/` and `sim_voxel`.
- `cmake --preset linux-default && cmake --build build/linux` – optional host-only libhydra/tools build; swap preset for Windows/MSVC.
- `./scripts/setup_sdk.sh` – build libhydra + helper tools (Linux stub expects kernel headers).

## Coding Style & Naming Conventions
- C++: 4-space indents, snake_case locals, minimal globals; order includes std/lib/project; favor small helpers over macros in SDL/Verilator setup.
- SystemVerilog: snake_case signals/modules with RTL prefixes (`cam_`, `cfg_`, `sel_`, `dbg_`); keep combinational vs sequential blocks separate and lightly commented when behavior is subtle.
- Preserve existing formatting and tight diffs; avoid trailing whitespace.

## Testing Guidelines
- Primary check: `make` then `./sim_voxel`; watch stdout/stderr; set `LOG_FRAMES=1` or `LOG_KEYS=1` while running.
- Waveforms: tracing is enabled; inspect `sim/obj_dir/*.vcd` when debugging RTL changes.
- Cocotb scaffold: `cd sim/tests/cocotb_hydra && make SIM=icarus` (requires cocotb + supported simulator). RTL stubs live in `sim/tests/rtl/`.
- Add targeted assertions as you touch logic; document new keybinds or flags when user-visible.
- **Rendering Architecture**: See `docs/rendering_separation.md` and `docs/rendering_architecture_diagram.md` for detailed fake vs real rendering separation.

## Commit & Pull Request Guidelines
- Commit subjects: short, imperative, single-scope (e.g., `Clamp camera bounds`, `Add voxel edit hotkeys`).
- PRs: note what changed, how you validated (`make`, `./sim_voxel`, cocotb), new dependencies/flags, and screenshots or clips for user-visible behavior.
- Link issues and flag known limitations or TODOs you deferred.

## Dependencies & Configuration Notes
- Required: `verilator` 5.x, `g++`, `make`, `libsdl2-dev`, `libsdl2-ttf-dev`; ensure `sdl2-config` on `PATH` or set `SDL_CFLAGS`/`SDL_LIBS`.
- Override toolchains with `VERILATOR=...` or `CXX=...`; set `WAYLAND=1` when building Wayland support (supply `WAYLAND_CFLAGS`/`WAYLAND_LIBS`).
