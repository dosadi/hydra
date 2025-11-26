# Rendering Pipeline Trace TODOs (Debug/Profiling)

- TODO: Add a pipeline trace overlay in the HUD showing MAX_RAY_STEPS, STEP_SIZE, AA/fog/tonemap flags (for quick verification).
- TODO: Add a JSON/CSV “pipeline dump” from the sim for regression diffs (captures key shader params).
- TODO: Add an option to log ray step counts and early-exit metrics per frame for profiling (HUD + file).
- TODO: Add a toggle to dump per-frame shader settings and env knobs to stderr (for reproducibility).
- TODO: Provide a unit scene with expected ray/normal outputs and golden hashes for regression of shading changes.
