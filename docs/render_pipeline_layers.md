# Render Pipeline Layers & Optimization Targets

This document maps the shader-like stack from the HDK world generator through the Verilator raycaster into the SDL viewer and HUD, and it outlines small-to-medium optimization/fastpath ideas that keep the pipeline responsive.

## Layered View of the Render Stack

1. **Scene Seed / Memory Layer (`rtl/voxel_world_gen.sv:10-199`, `rtl/voxel_framebuffer_top.sv:169-201`)**  
   - `voxel_world_gen` clears the 64³ `voxel_memory_64`, writes the floor/ceiling slabs with procedural gradients/noise, and paints two spheres. The world seed still feeds the floor noise (see `seed_noise` XOR, lines 42-60), so the static data arriving at the raycaster already contains the desired colors/lighting.
   - A debug-write mux in `voxel_framebuffer_top.sv:184-191` lets host edits override the generator before RAM sees them, ensuring the ray layer only ever sees the latest voxel data and enabling `selection` edits to take effect immediately.

2. **Raycast Compute Layer (`rtl/voxel_framebuffer_top.sv:206-260`, `rtl/voxel_raycaster_core_pipelined.sv:203-380`)**  
   - Camera vectors, config flags (`cfg_smooth_surfaces`, `cfg_extra_light`, `cfg_diag_slice`), cursor state, and the sampled voxel data feed the pipelined raycaster. The core computes lighting (Lambert + curvature boost), coordinate-based color bias, shadows (with smooth falloff), selection highlights, and packs results into `pixel_word0/1/2` + sidecar data (reemissure, normals, stats). Cursor hits and ray statistics stream back via debug outputs for the HUD.

3. **Framebuffer Output / Viewer Layer (`sim/live_sdl_main.cpp:1189-1495`)**  
   - The simulator loop runs 2k Verilog ticks per chunk, listens to `pixel_write_en`, converts packed words via `pixel96_to_argb`, and stores RGBA pixels into the SDL buffer. Per-frame counters (`record_color`, lines 26-49/1212-1247) track the min/max RGB range so the HUD can show spectrum coverage.
   - HUD drawing (`sim/live_sdl_main.cpp:1350-1495`) shades the bottom band per theme, prints camera/stats lines, draws help overlays, and reports the latest RGB range. Input handlers (lines 820-1140) toggle raster modes, `ray_jitter`, spectrum mode, and selection editing, providing runtime control over the pipeline.

## Optimization & Fastpath Targets

### World Generator
1. **Memoize floor noise gradient.**  
   - The floor pass recomputes `texture_noise`, `xz_xor`, and clamped RGBs for every `y` slice (lines 111-165). Introduce a tiny LUT keyed by `(x,z)` (3+3 bits each) to avoid recalculating XOR/clamp per `y`, reducing the total combinational work in the generator.
2. **Skip sphere writes when untouched.**  
   - Sphere loops (lines 179-260) currently scan the entire grid. Add a CSR/flag that lets the host skip rewriting a sphere if a debug write already tinted that voxel range, turning a full rebuild into a fast path when only a few voxels change.

### Raycast Core
3. **Guard `apply_advanced_lighting` and bias mixing.**  
   - When `cfg_extra_light` and `cfg_curvature` are zero, the call at `voxel_raycaster_core_pipelined.sv:263` can be skipped and the extra multipliers turned off. Expose a simple register that bypasses the curvature-based increments and the later coordinate bias mix (`grad_coord_*`, mix) when no special lighting is required.
4. **Replace `*3` mixes with shift-add or table.**  
   - The coordinate bias (`mix_r = (out_r * 3) + grad_coord_r`, lines 308-316) uses runtime multiplication. A tiny `<<1` plus `+out_r` or a 256-entry LUT per channel would eliminate the multiplier while keeping the same ramp, shaving a few cycles in the ALU path.
5. **Fast path for diag-slice off.**  
   - `diag_slice_mode` currently toggles best-hit tracking and `sel_active` behavior but still executes the full `compute_pixel_data` path. When the flag is clear, a fast path can avoid the extra `best_hit` counter/state tracking (lines 380-430) and skip unnecessary vector math to reduce per-pixel work.
6. **Shadow falloff clamp precomputation.**  
   - `shadow_blend` computation (lines 289-310) performs division and clamp every pixel. Precompute a small table describing the scale based on `sh_delta` buckets so the hot path only indexes a ROM, converting the smooth falloff into a deterministic fast path.

### Viewer / SDL Layer
7. **Batch `record_color` updates per row.**  
   - The HUD uses `record_color` (lines 435-445) inside the pixel loop, doing six min/max comparisons per pixel. Track the current row’s min/max and only update the global range once per row (or when values change) to cut that hot inner-loop work by ~75%.
8. **Cache HUD strings/skip redraw.**  
   - Drawing 10+ HUD lines every frame (lines 1370-1465) regenerates strings even when stats haven’t changed. Cache the last rendered string hash and skip redrawing unchanged lines or move non-critical stats to a slower toggle to reduce CPU usage.
9. **Simplify framebuffer clearing.**  
   - The `std::fill(framebuffer, ...)` call (line 1485) runs after every frame or when `pixels_written_this_frame < NPIX`. Replace it with selective zeroing (only the top/bottom rows that were untouched) or keep a dirty rectangle tracker so most frames simply overwrite previous pixels without a full `O(N)` clear.

### Tooling Fastpaths
10. **Structured HUD stats ingestion.**  
   - Feed the new per-frame RGB ranges/ray histograms into `scripts/todo_inspect.py` so tests can quickly detect when a change collapses the spectrum. Exporting stats as JSON allows nightly fast paths (like `scripts/todo_rebalance.py`) to raise flags before manually inspecting renders.

## Supplemental Render Stack TODOs

- **TODO [P2]:** Trace the per-voxel `voxel_light` and `voxel_emissive` sources inside `voxel_world_gen.sv` and export a small CSV/log that directors can use to verify the gradient + sphere lighting ratios remain constant between revisions.
- **TODO [P2]:** Introduce a per-frame “ray jitter” bandwidth budget: track when `ray_steps_max` exceeds the previous frame and throttle the viewer to keep real-time budgets in-cheek (HUD warning + optional `safeguard` flag).  
- **TODO [P2]:** Audit `pixel95_to_argb` to ensure there’s no redundant computation (e.g., repeated shifts/masks) when `g_pixel_view_mode==Color`; reduce the viewer path to a single ALU chain to free CPU cycles for HUD draws.  
- **TODO [P3]:** Add a `HYDRA_RENDER_FASTPATH` env override that disables the slow `cursor` stats writes and `doc` logging while keeping `pixel_word` outputs intact, providing a quick bench mode for throughput regression testing.
- **TODO [P2]:** Surface a “load factor” indicator that compares `pixels_written_this_frame` vs. `NPIX` and logs frames where the raycaster fails to cover the screen; tie that into `scripts/todo_inspect.py` for nightly fastpath detection.

Each entry above is intended as a bite-sized engineering task (1-3 days) that improves a specific layer’s throughput or exposes a fast path under common-case usage. Let me know if you’d like estimates or want to tackle one of these next.  
