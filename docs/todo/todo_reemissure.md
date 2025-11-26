# Reemissure TODOs

Focuses on the emissive sideband: semantics, validation, HUD/log coverage, and debugging helpers.

- **TODO [P2]:** Document pixel_word bitfields (depth/color/reemissure) and semantics (units, normalization) in spec plus HUD notes.
- **TODO [P2]:** Build regression to toggle emissive voxels and ensure pixel_word2/sideband reflects changes; add cocotb monitor verifying transitions.
- **TODO [P2]:** Gate reemissure writes to valid hits and add assertions ensuring zero when emissive flag off, nonzero when on.
- **TODO [P2]:** Add cocotb bench verifying reemissure correctness for a known scene with expected sideband values.
- **TODO [P2]:** Provide HUD/readout overlays for reemissure histogram, heatmap, and debug mode showing intensity across frame.
- **TODO [P2]:** Add reemissure scaling knob (env/HUD) to tune emissive vs base color, plus LUTs for quick style swaps.
- **TODO [P2]:** Ensure diagonal slice flag maintains expected changes in reemissure outputs; add assertions/coverage for diag_slice impact.
- **TODO [P2]:** Export pixel_word2 via `FRAME_DUMP` optional plane for easier analysis (multi-plane PNG). 
- **TODO [P2]:** Add CLI/env to dump pixel_word raw values to CSV for offline emissive debugging; mention in docs.
- **TODO [P2]:** Create per-pixel checksum/log to validate pixel_word stability across frames, and add fixture monitoring first/last pixel data.
- **TODO [P2]:** Track pixel_word fields resetting to defaults on soft reset and ensure no X/Z/uninit states in non-emissive flows.
- **TODO [P2]:** Add AI health dashboard hooks that surface experiments when reemissure stats shift (log sideband counts to `out/ai_health_dashboard.txt` via `scripts/ai_dashboard_briefing.py`).
- **TODO [P2]:** Create a surrogate “reemissure regression monitor” that compares current histogram to stored golden histogram (JSON) and flags diffs for `scripts/automation_watchdog.sh`.
- **TODO [P3]:** Add reemissure overlay heatmap and value traces tied to selection to evaluate emissive balance quickly.
- **TODO [P3]:** Provide a debug overlay showing per-voxel emissive intensity or allow toggling emissive-only view.
- **TODO [P3]:** Build a “reemissure spectrum” viewer (heat map + histogram) toggled from the HUD and exportable to PPM/logs.
- **TODO [P3]:** Add a script that parses frame dumps and alerts when emissive values exceed defined thresholds (structured log mention).
