**Simulator Instrumentation**

- **Frame dumps:** `sim/build/frame_*.ppm` — produced when `FRAME_DUMP` env var is set. Used by `scripts/check_frame.py` to compare frames against the golden.
- **Instrumentation CSVs / configs:** `sim/out/` — contains CSV and config files produced when `HYDRA_RENDER_INSTRUMENT=1` is set. Example files:
  - `sim/out/render_pipeline_baseline.csv` — per-frame timing metrics (fps, ray loop ms, HUD render, framebuffer copy, total frame ms).
  - `sim/out/render_pipeline_baseline.cfg` — instrumentation config snapshot.

How to generate an instrumented frame (local):

```bash
cd sim
# deterministic seed and single-frame dump
HYDRA_RENDER_INSTRUMENT=1 HYDRA_RENDER_INSTRUMENT_DIR=sim/out HYDRA_WORLD_SEED=0 FRAME_DUMP=build/frame_test.ppm AUTO_EXIT=1 ./sim_voxel
```

Notes:
- The `sim/out/` directory is intentionally ignored by `.gitignore` because it contains runtime artifacts.
- Use `scripts/check_frame.py` to compare `sim/build/frame_test.ppm` with `sim/tests/golden_frame.ppm`.
- If instrumentation files are missing, confirm `HYDRA_RENDER_INSTRUMENT` and `HYDRA_RENDER_INSTRUMENT_DIR` are set and writable.

If you want this placed elsewhere or more details (CSV schema, column descriptions), tell me and I'll expand the doc.
