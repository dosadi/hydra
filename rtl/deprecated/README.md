# Deprecated RTL Modules

This directory contains RTL modules that are no longer used in the active codebase but are kept for reference or potential future use.

## Modules

### axil_csr_stub.sv
**Status**: Unused
**Reason**: Generic AXI-Lite CSR stub. Superseded by `voxel_axil_csr.sv` which provides the actual register map for Hydra.
**Potential Use**: Could be useful as a template for simple AXI-Lite slaves in other projects.

### axi_crossbar_stub.sv
**Status**: Unused
**Reason**: 2x2 AXI crossbar stub. Was previously used in `voxel_axil_shell.sv` but removed when we split sim/FPGA paths. The new `voxel_sim_harness.sv` does inline muxing instead. For FPGA, LiteX provides proper crossbar infrastructure.
**Potential Use**: Could be useful for simple 2-master, 2-slave AXI interconnects in other projects. However, for production use, LiteX's `AXIInterconnect` is recommended.

### hdmi_scanout_stub.sv
**Status**: Incomplete/Unused
**Reason**: Framebuffer scanout engine for reading from SDRAM and generating AXI-Stream video. Not currently used in `voxel_sim_harness`. May be useful for Phase 5 (HDMI scanout architecture) but needs integration work.
**Potential Use**: Could be integrated into `voxel_sim_harness` to test DRAM-based scanout in simulation. Would need to be wired to `axi_sdram_stub` debug port.

### surface_extractor.sv
**Status**: RESTORED TO ACTIVE (moved back to rtl/)
**Reason for previous deprecation**: ERROR - This module was incorrectly deprecated. It is actually part of the active feature set added in PR #3.
**Actual Status**: Active stub with:
  - Register map entries in BAR0 (SURF_BASE/SURF_LEN/SURF_STATS, REGION0_*)
  - libhydra API functions (hydra_surface_extract_stub, hydra_region0_extract_stub)
  - Test coverage in cocotb
  - Documented in docs/hydra_spec.md as planned feature
**Note**: Module was restored to rtl/ immediately upon discovering the error.

### trilinear_interpolator.sv
**Status**: Stub only
**Reason**: Placeholder for trilinear interpolation of voxel data. Currently no-op. Never integrated.
**Potential Use**: Could be implemented for future smooth voxel rendering (no visible voxel edges). Would need:
  - Sample 8 corner voxels
  - Compute interpolation weights
  - Blend colors/densities
  - Integration into raycaster (significant performance cost)

## Removal Timeline

These modules may be permanently removed in a future release if:
1. No use cases are identified
2. No community interest
3. Equivalent functionality exists elsewhere

For now, they are kept for reference and potential future revival.

## Restoration

To restore a deprecated module to active use:
1. Move the file back to `rtl/`
2. Add to relevant build scripts (`sim/tests/run_rtl_tests.sh`, `sim/tests/cocotb_hydra/Makefile`)
3. Instantiate in appropriate parent module
4. Update documentation

## See Also

- `docs/ip_integration_cleanup.md` - Architecture cleanup documentation
- `docs/architecture_cleanup_summary.md` - Summary of changes that deprecated these modules
