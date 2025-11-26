# Depth Buffer TODOs

Focuses on depth range/format, fog/slice visualizations, debug exports, and depth-based effects.

- **TODO [P2]:** Define depth range convention (0..far, linear vs non-linear) and align RTL/HUD dumps; document in spec.
- **TODO [P2]:** Add tool parsing `FRAME_DUMP` depth plane and printing stats (min/max/histogram); store example outputs.
- **TODO [P2]:** Add regression toggling fog on/off to ensure depth buffer stays stable (no reuse artifacts).
- **TODO [P2]:** Create depth sanity bench (flat plane) that asserts uniform depth values.
- **TODO [P2]:** Define depth format/export path (debug buffer, PNG/PPM) and make depth histogram HUD/readout for tuning.
- **TODO [P2]:** Add “depth debug” hotkey to slice through depth and compare to selection/pixel list.
- **TODO [P2]:** Enable optional depth-aware SSAO/SSR using exported depth/normals.
- **TODO [P2]:** Add per-pixel depth clamp to avoid NaNs/infinity and flag invalids in logs.
- **TODO [P2]:** Add HUD overlay for depth contours/isolines and depth peeking display near cursor.
- **TODO [P2]:** Implement per-material depth bias control to reduce acne and validate monotonic depth increments in cocotb bench.
- **TODO [P2]:** Add regression that compares depth slices to expected geometry for a simple scene.
- **TODO [P2]:** Import a “depth sanity” bench into CI that renders flat planes and checks histogram variance on every commit.
- **TODO [P3]:** Publish depth range/gamma calibration guidance for driver/renderer teams (include test pattern and recommended viewer settings).
- **TODO [P3]:** Add depth buffer export metadata (resolution, format, min/max) to the `FRAME_DUMP` header so downstream tools can parse raw planes automatically.
- **TODO [P2]:** Add coverage that depth planes reset/zero on soft reset/start frame; verify pixel_word depth bits stable when `pixel_write_en` is low.
- **TODO [P3]:** Provide per-axis depth histogram overlays and HDR depth logging, along with a “depth peeking” log command.
- **TODO [P3]:** Add profiling assertions that depth increasing along rays matches expectations, and include depth data in `scripts/check_frame.py`.
