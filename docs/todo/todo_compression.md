# Hardware Compression TODOs (RLE, LZ, Palette, etc.)

Focuses on exploring compression schemes for voxel data, framebuffer output, and asset storage to save bandwidth and storage while maintaining hardware-friendly performance. Covers run-length encoding (RLE), palette compression, block-level encoding, and future schemes.

**Related Trackers:** `todo_data_formats.md`, `todo_performance.md`, `todo_dma_pcie.md`, `todo_rendering.md`

---

## P1 - Core Compression Infrastructure

- TODO [P1]: Define compression format strategy (per-row RLE, per-block palette, hybrid) and document in `docs/compression_architecture.md` with trade-offs for BRAM usage, decompression latency, and rendering throughput.
- TODO [P1]: Add compression format version field to voxel data headers to support future format changes and tool compatibility.
- TODO [P1]: Build baseline compressor/decompressor prototype (Python/C++) that consumes Hydra voxel dumps and produces compressed blobs with metadata; output stats to `out/compression_stats.json`.
- TODO [P1]: Integrate compression stats into `scripts/ai_health_dashboard.py` for automated tracking of compression ratios, decompression latency, and bandwidth savings.
- TODO [P1]: Add CSR controls to enable/disable hardware decompression at runtime for A/B testing compressed vs. uncompressed paths.

## P2 - RLE Compression

- TODO [P2]: Evaluate hardware-friendly RLE schemes (per-row/per-block/per-slice) that can be implemented in RTL or simulator, documenting trade-offs between throughput, BRAM usage, and rendering velocity.
- TODO [P2]: Implement RLE compressor for solid/hollow voxel regions and capture before/after stats on existing scenes (floor, ceiling, spheres).
- TODO [P2]: Add RLE decompressor RTL module (or DMA filter) that expands RLE packets on the fly before writing to framebuffer or BRAM.
- TODO [P2]: Expose "hollow mode" CSR flag or viewer control so artists can mark empty regions and rely on compression to fill them efficiently.
- TODO [P2]: Add RLE compression ratio metrics to HUD (optional toggle) and log to `out/rle_profiles.json` for dashboard analysis.
- TODO [P2]: Add negative test: feed malformed RLE data to decompressor and verify graceful failure/error reporting.

## P2 - Palette Compression

- TODO [P2]: Implement palette-based compression for voxel colors (8-bit indices into 256-color palette) to reduce BRAM footprint for scenes with limited color variety.
- TODO [P2]: Add palette upload/download IOCTLs (BAR0 CSRs or DMA path) to allow dynamic palette changes from driver/SDK.
- TODO [P2]: Build palette extraction tool (Python) that analyzes scene voxel colors and generates optimal 256-color palettes with dithering support.
- TODO [P2]: Add palette compression mode to world generator (`voxel_world_gen.sv`) with CSR toggle for testing.
- TODO [P2]: Document palette format (RGBA32 entries) and indexing scheme in `docs/compression_architecture.md`.
- TODO [P2]: Add viewer toggle to display palette entries and show which voxels use each color (debug mode).

## P2 - Block-Level Compression

- TODO [P2]: Explore block-level encoding (4×4×4 or 8×8×8 voxel blocks) with per-block metadata (solid/empty/mixed) to skip decompression of homogeneous regions.
- TODO [P2]: Implement block occupancy bitmask format (1 bit per block = solid/empty) as lightweight compression for large empty volumes.
- TODO [P2]: Add block-level skip logic to raycaster (`voxel_raycaster_core_pipelined.sv`) to bypass ray marching through empty blocks.
- TODO [P2]: Build block compression analyzer tool that reports block occupancy statistics (solid%, empty%, mixed%) per scene.
- TODO [P2]: Add CSR controls for block size selection (4³/8³/16³) and log performance impact to `out/block_compression_perf.json`.

## P2 - Framebuffer Compression

- TODO [P2]: Evaluate framebuffer compression schemes (tile-based, delta encoding) to reduce BAR1/DMA bandwidth for PCIe transfers.
- TODO [P2]: Implement simple delta encoding compressor for framebuffer updates (only send changed pixels frame-to-frame).
- TODO [P2]: Add CSR to enable delta compression mode and expose compression ratio stats via debugfs/sysctl.
- TODO [P2]: Build framebuffer compression benchmark that measures bandwidth savings vs. decompression overhead on host CPU.
- TODO [P2]: Document framebuffer compression format and driver integration in `docs/dma_architecture.md`.

## P3 - Advanced Compression Features

- TODO [P3]: Explore LZ77/LZSS-style compression for voxel data with hardware-friendly window sizes (e.g., 256-byte sliding window).
- TODO [P3]: Implement sparse voxel octree (SVO) compression with pointers to child nodes for hierarchical scene representation.
- TODO [P3]: Add compression format negotiation between driver and hardware (capability bits in BAR0 CSRs).
- TODO [P3]: Build compression format converter tool that migrates old formats to new formats with backwards compatibility checks.
- TODO [P3]: Add viewer controls to visualize compression artifacts (e.g., palette dithering, RLE boundaries) for debugging.
- TODO [P3]: Document art workflow for generating hollow vs solid objects with compression-friendly layouts in `docs/design_gaming_integration.md`.
- TODO [P3]: Add compression quality presets (fast/balanced/best) with CSR selection and performance profiling.
- TODO [P3]: Explore GPU-accelerated decompression paths for host-side framebuffer processing (OpenCL/Compute shader).

## P3 - Compression Testing & Validation

- TODO [P3]: Add compression format fuzzer that generates random compressed data and verifies decompressor error handling.
- TODO [P3]: Build compression corpus (test scenes) covering worst-case/best-case compression scenarios.
- TODO [P3]: Add CI job that runs compression benchmarks on golden scenes and flags regressions in compression ratio or speed.
- TODO [P3]: Add cocotb test that exercises hardware decompressor with various RLE/palette patterns.
- TODO [P3]: Document expected compression ratios for common scene types (solid walls, organic shapes, text/UI) in `docs/performance.md`.

---

## Priority Summary

- **P1:** 5 items - Core infrastructure, format strategy, baseline tools, dashboard integration
- **P2:** 18 items - RLE, palette, block-level, framebuffer compression with testing
- **P3:** 13 items - Advanced schemes (LZ, SVO), quality presets, GPU acceleration, fuzzing

**Next Steps:** Define compression architecture document and build baseline compression prototype with stats collection.
