# Hardware RLE Compression TODOs

Focuses on exploring run-length encoding (RLE) compression for solid/hollow voxel art so hardware-generated content can save bandwidth and storage while still exposing hollow/solid control to authors.

## P2 - Compression Exploration
- **TODO [P2]:** Evaluate hardware-friendly RLE schemes (per-row/per-block) that can be implemented either in the RTL path or in the simulator, documenting trade-offs between throughput, BRAM usage, and rendering velocity.
- **TODO [P2]:** Build a compressor/decompressor prototype (Python/C++) that consumes Hydra voxel dumps and produces RLE blobs plus metadata; log results to `out/rle_profiles.json` for dashboard analysis.
- **TODO [P2]:** Determine how to expose “hollow modes” via CSR or viewer controls so artists can request empty regions and rely on compression to fill them efficiently.
- **TODO [P2]:** Run the RLE prototype on existing scenes and capture before/after stats, surfacing them via `scripts/ai_health_dashboard.py` so automation knows when compression yields a benefit.

## P3 - Hardware Integration & Controls
- **TODO [P3]:** Design RTL extensions (or DMA filters) that decompress RLE packets on the fly before sending them to framebuffers, documenting timing budgets and fallback behavior when the compressor is unavailable.
- **TODO [P3]:** Add viewer/SDK controls that visualize compression ratio and allow toggling between compressed/regular modes while the AI dashboard records the selected mode for automation coverage.
- **TODO [P3]:** Document the art workflow for generating hollow vs solid objects plus RLE metadata in `docs/design_gaming_integration.md` so content creators know how to prepare assets for compressed pathways.
