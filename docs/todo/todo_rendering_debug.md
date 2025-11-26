# Rendering Debug & Overlay TODOs

documents overlays, stats, heatmaps, comparison views, and visualization helpers.

- **TODO [P1]:** Show a HUD readout for average ray depth & occlusion hits.
- **TODO [P1]:** Add per-channel histogram overlay to monitor exposure/clipping.
- **TODO [P2]:** Add heat map for raystep count and heat map overlay for AXI activity.
- **TODO [P2]:** Add grid/axis overlay, wireframe overlay, and axis indicator toggles.
- **TODO [P2]:** Add split-screen/snapshot compare mode (original vs graded).
- **TODO [P2]:** Add viewport to display framebuffer max/min luminance and HDR histogram logging.
- **TODO [P2]:** Implement jitter/AA heatmap and crosshair customization.
- **TODO [P3]:** Provide debug overlays for material/emissive levels and highlight selected voxel outlines.
- **TODO [P3]:** Implement HUD layer toggles (inputs/memory/ray stats) to reduce overlay clutter.
- **TODO [P3]:** Log HUD overlay usage (which toggles/overlays were enabled) per run to help tune what should stay visible.
- **TODO [P3]:** Provide a quick “overlay snapshot” script that captures the HUD state as JSON so regressions can be replayed.

## View Frustum Awareness

- **TODO [P2]:** Add camera frustum visualization (lines/planes) to the HUD so artists can see what region is being ray marched.
- **TODO [P2]:** Log view frustum plane data via CSRs or HUD files so `scripts/ai_health_dashboard.py` can warn when scenes fall outside the active frustum.
- **TODO [P3]:** Implement frustum culling hints (color-coded distances) and capture frame metric differences when culling engages, surfacing them as TODOs when regressions occur.
