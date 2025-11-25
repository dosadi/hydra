# Xschem Integration Plan (Schematic Capture)

## Goals
- Capture block-level schematics for Hydra components using Xschem (documentation + optional simulation netlists).
- Export viewable artifacts (PDF/PNG) into `docs/` for reviewers.
- Generate Verilog/SPICE netlists for reference and light validation (lint-only).
- Keep Xschem libraries/version pinned for reproducible renders.

## Proposed layout
- `xschem/` root with:
  - `symbols/` for Hydra-specific symbols.
  - `schematics/` for block-level schematics (per module).
  - `tech/` for Xschem rc/library configs (version-pinned).
- Scripts:
  - `scripts/xschem_render.sh` to batch-export schematics to PNG/PDF.
  - `scripts/xschem_netlist.sh` to generate Verilog/SPICE netlists (lint-only).

## Flow
1. Author schematics in `xschem/schematics/*.sch` using symbols in `xschem/symbols/`.
2. Run `scripts/xschem_render.sh` to emit PNG/PDF into `docs/xschem/`.
3. Run `scripts/xschem_netlist.sh` to generate netlists into `out/xschem_netlists/` and optionally run Verilog lint.
4. CI (best-effort) to render schematics and check netlists when Xschem is available; otherwise skip with notice.

## TODOs
- TODO: Add an example symbol + schematic template (with metadata block) to onboard new contributors quickly.
- TODO: Provide a headless smoke test that runs xschem render on a tiny schematic and fails clearly if xschem/ngspice missing.
- TODO: Add a simple Makefile include for xschem so `make xschem-*` hooks work from repo root.
- TODO: Add `xschem/` directory with starter rc/config and symbol library for Hydra modules.
- TODO: Add `scripts/xschem_render.sh` to batch-export schematics to PNG/PDF (headless Xschem usage).
- TODO: Add `scripts/xschem_netlist.sh` to generate Verilog/SPICE netlists and run lint (optional).
- TODO: Pin/record Xschem version and dependencies (ngspice, imagemagick) in docs.
- TODO: Create a sample schematic (e.g., voxel framebuffer block) and export artifacts into `docs/xschem/`.
- TODO: Wire a CI job to render schematics and netlists when Xschem is available; skip gracefully otherwise.
- TODO: Add a README section pointing to `docs/xschem/` artifacts and how to regenerate them.
- TODO: Add a Makefile target (`make xschem-render`, `make xschem-netlist`) for local automation.
- TODO: Add a script to diff generated netlists against RTL for basic consistency (port names/counts).
- TODO: Provide symbol templates for common buses (AXI-lite, AXI, AXI-stream) to keep schematics consistent.
- TODO: Add a lint/check that schematics reference the pinned symbol library (no stray deps).
- TODO: Export SVG alongside PNG/PDF for higher quality embeds in docs.
- TODO: Document how to install Xschem/Ngspice on supported platforms (Debian/Ubuntu notes).
- TODO: Add a CI artifact upload of rendered schematics on failure/success for quick review.
- TODO: Provide a CONTRIBUTING note on schematic naming conventions and where to place new sheets.
- TODO: Add a version stamp/metadata block in rendered schematics (commit hash, date).
- TODO: Add a simple bus hookup example schematic showing AXI-lite + AXI-stream connectivity.
- TODO: Integrate a check that netlists don't drift (git diff fail if regenerated artifacts change unexpectedly).
- TODO: Add a README section explaining how schematics map to RTL modules (index/table).
- TODO: Provide a script to list available schematics and associated outputs (PNG/PDF/SVG).
- TODO: Add a “clean” target to remove generated xschem outputs (netlists, renders).
- TODO: Define color/style conventions for symbols/wiring to keep visuals consistent.
- TODO: Add a lint to ensure schematics include SPDX/license info in metadata/comments.
