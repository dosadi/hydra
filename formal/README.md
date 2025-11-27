# SymbiYosys Formal Verification Integration

This directory contains configuration and setup for running formal property checks on Hydra RTL modules using SymbiYosys (SBY).

## Structure
- `sby_config.sby`: Main SBY config for proving properties on `voxel_framebuffer_top.sv` and `voxel_raycaster_core_pipelined.sv`.
- Add additional `.sby` configs for other modules or properties as needed.

## Usage
1. **Install SymbiYosys and Yosys**
   - On Ubuntu: `sudo apt install symbiyosys yosys`
   - Or see: https://github.com/YosysHQ/sby
2. **Run a formal check**
   - From this directory: `sby sby_config.sby`
   - Results will be in a subfolder (e.g., `sby_config/`).
3. **Add properties**
   - Use SystemVerilog `assert property` in your RTL.
   - For liveness/sequence checks, use SVA syntax supported by Yosys/SBY.

## Example Properties
- Frame start always leads to frame_done.
- Pixel address monotonicity.
- No overlapping pixel writes.

## Extending
- Add more `.sby` configs for other modules.
- Document new properties and results here.

## References
- [SymbiYosys Documentation](https://github.com/YosysHQ/sby)
- [YosysHQ Formal Guide](https://yosyshq.readthedocs.io/en/latest/formal.html)
