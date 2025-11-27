**TODO Actions & Triage**

Scan date: 2025-11-27
Source: repo grep for TODO | FIXME | XXX

Goal: convert passive TODO comments into prioritized, actionable tasks with recommended branches and minimal first steps.

Priority key
- P0: correctness / high-impact (fix before release or CI acceptance)
- P1: medium impact (simulation, CI, tests, integration)
- P2: low impact (features, stubs, docs)

P0 - High priority (action required)
- `rtl/voxel_framebuffer_top.sv` (lines ~492-498)
  - Problem: "TODO: Implement priority arbitration logic for debug writes vs. world_gen"
  - Risk: write-ordering conflicts can cause incorrect frame pixels under contention.
  - Action: design+implement deterministic arbitration; add SVA assertions verifying exclusive write to a pixel address when both sources assert valid; add a small cocotb or Verilator unit test that toggles both sources under contention and checks pixel results.
  - Suggested branch: `fix/voxel-arb-priority`
  - Minimal steps (quick PR):
    - Add local temporary arbiter with priority bit (configurable param) and a small SVA that checks that no two writers assert write_enable for the same address in same cycle.
    - Run `make -C sim test_frame` and add a unit test (or frame test) to catch regressions.

- `rtl/axi_sdram_stub.sv` (lines ~1 and ~613)
  - Problem: stub lacks burst types / QoS / region handling
  - Risk: If testbench or driver expects AXI burst semantics, memory transactions may be dropped or mis-ordered.
  - Action: implement at least AXI4 single/burst(WRAP/INCR) behavior for common burst lengths and add assertions for proper AW/AWLEN/AWSIZE/AWBURST handling. Add test vectors that drive burst transfers and check memory contents.
  - Suggested branch: `fix/axi-sdram-bursts`
  - Minimal steps:
    - Implement INCR bursts for AXI write/read and treat AWLEN/NBURST accordingly in stub.
    - Add SVA or a small testbench target to exercise bursts.

P1 - Medium priority (improve tests/CI / integration)
- `rtl/axi_stream_sink_stub.sv` (lines ~72-78)
  - Problem: `tuser` / `tlast` handling for HDMI/TMDS not implemented.
  - Action: implement basic SOF/EOF detection using `tuser` and `tlast` and document expected semantics. Add a unit test that uses known HDMI frame streams.
  - Branch: `fix/axi-stream-tuser`

- Integration placeholders (scripts/ and .github/workflows placeholders)
  - Problem: placeholders are in-tree; replace with official integration package when provided.
  - Action: swap in real package on receipt and re-run `./scripts/sd.sh`; test workflows locally with `act` or in CI.
  - Branch: `chore/integration-replace`

- CI smoke job (recommended)
  - Problem: repo lacks a lightweight headless CI job to protect rendering changes.
  - Action: add `/.github/workflows/sim-smoke.yml` that runs on PRs and invokes `scripts/auto_iterate.sh --dry-run` with `HYDRA_BACKEND=AALIB`. Pin Verilator major version or run `scripts/verilator_check.sh` first.
  - Branch: `ci/add-sim-smoke`

P2 - Low priority (features / docs / stubs)
- `rtl/voxel_raycaster_core_pipelined.sv`: material_id integration — feature work, backlog as issue.
- `rtl/voxel_memory_64.sv`: random/pattern initialization — useful for fuzz tests; add as optional param.
- `rtl/surface_extractor.sv`: real normals/curvature — feature work, add to milestone.
- `drivers/mesa/*`: stub TODOs — only required for driver build completeness; low priority unless running Mesa tests.

Immediate next steps (I can execute now)
1. Create this `docs/TODO_ACTIONS.md` (done).
2. Create small, focused branches for P0 items and implement minimal SVA/assertions:
   - `fix/voxel-arb-priority` (add arbiter + SVA + unit test)
   - `fix/axi-sdram-bursts` (basic INCR bursts behavior + test)

3. Add CI smoke job draft: `/.github/workflows/sim-smoke.yml` that runs the auto-iterate dry-run on PRs.

Quick commands to start a P0 fix locally (example for arbitration):
```bash
# from repo root
git checkout -b fix/voxel-arb-priority
# edit rtl/voxel_framebuffer_top.sv to add arbiter and SVA
# run sim smoke locally
make -C sim test_frame
# run full sim if needed
make -C sim
# add/commit/push and open PR
git add rtl/voxel_framebuffer_top.sv
git commit -m "Fix: add priority arbiter for debug/world_gen writes + SVA"
git push -u origin fix/voxel-arb-priority
gh pr create --base main --head fix/voxel-arb-priority --title "Fix: arbiter for framebuffer writers" --body "Add priority arbiter and assertion to prevent concurrent writes."
```

If you want, I can begin implementing the P0 `voxel_framebuffer_top.sv` arbitration fix now and open a draft PR. That will involve small RTL edits and an SVA; I will run `make -C sim test_frame` to verify no regressions before pushing.

Would you like me to start on `fix/voxel-arb-priority` now, or should I begin with the AXI stub burst support instead?