# Hydra Xschem Workspace

This directory is the home for Hydra schematics captured in Xschem.

- `schematics/` holds `.sch` sheets (one per block).
- `symbols/` contains Hydra-specific symbols (AXI-lite, AXI, voxel blocks).
- `tech/` is for shared config/rc files (pin the Xschem version/libs here).

Guidelines:
- Keep symbols under version control; prefer bus terminals for AXI/AXI-lite.
- Include a metadata block (title, revision, commit hash, date) on each sheet.
- Avoid external libraries beyond the pinned tech config to keep renders reproducible.
