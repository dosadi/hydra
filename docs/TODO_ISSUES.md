TODO Issues & Action Plan

Created: 2025-11-27
Repo: hydra
Branch: update/golden-frame-20251127T105702Z

Purpose
- Translate inline TODO/FIXME comments into small, reviewable branches and tasks.
- Provide step-by-step minimal work items so we can make incremental, low-risk progress.

Priority guide
- P0: correctness / blocking for tests or CI
- P1: integration / test infra / coverage
- P2: features / stubs / docs

Immediate actionable items

1) P0 - Add AXI WRAP unit test
- Files: `rtl/axi_sdram_stub.sv`, `sim/tests/axi_wrap_test.cpp` (new)
- Branch: `test/axi-wrap`
- Steps:
  - Add a small Verilator test (`sim/tests/axi_wrap_test.cpp`) that drives an AXI burst with WRAP type against the memory stub, then reads back memory using the debug port to verify wrap-around writes.
  - Add a Make target `make -C sim test_axi_wrap` that builds and runs the test.
  - Verify locally: `make -C sim test_axi_wrap`.

2) P0 - Add small cocotb or Verilator test for framebuffer arbitration
- Files: `rtl/voxel_framebuffer_top.sv`, `sim/tests/frame_arb_test.cpp` (new) or cocotb under `sim/tests/cocotb/`
- Branch: `test/frame-arb`
- Steps:
  - Drive concurrent debug write and world_gen writes to same address and check memory contains debug write (arbiter preference).
  - Keep test self-contained (use `dbg_we`/debug ports) to avoid running whole viewer.

3) P1 - Replace placeholders with official integration package (when available)
- Files: `scripts/*`, `.github/workflows/*` placeholders
- Branch: `chore/integration-replace`
- Steps:
  - When provided, unpack official package into `scripts/` and replace placeholder files.
  - Re-run `./scripts/sd.sh`, then run `./sim/test_frame` and CI smoke job locally.

4) P1 - Add more formal SVA coverage for `voxel_memory_64.sv`
- Files: `rtl/voxel_memory_64.sv`
- Branch: `fix/memory-svas`
- Steps:
  - Add assertions for init behavior, single-cycle write/read exclusivity, and `mem_valid` semantics.
  - Run formal tools (outside this session) or Verilator lint to ensure syntax.

5) P1 - Create CI job for AXI unit tests (after test exists)
- Files: `.github/workflows/sim-smoke.yml` (extend) or separate `ci/axi-tests.yml`
- Steps:
  - Run the AXI wrap test under `HYDRA_BACKEND=AALIB` in GitHub Actions; fail PR on regression.

6) P2 - Run repo docs spellcheck and apply high-confidence fixes
- Files: `docs/*`, `README.md`
- Branch: `chore/docs-spellfix`
- Steps:
  - Run `codespell` across `docs/` and apply only unambiguous fixes.
  - Commit and open a small PR with only docs changes.

7) P2 - Driver Mesa stubs improvements
- Files: `drivers/mesa/*.c`
- Branch: `chore/mesa-stubs`
- Steps:
  - Flesh out minimal caps/format query stubs so that Mesa builds if/when tested.
  - Add a comment explaining intended behavior and what to replace when upstream driver is added.

How I can proceed now (pick one or let me choose the highest-priority):
- Implement item (1) AXI WRAP unit test (P0). This provides deterministic coverage for the recent WRAP implementation and is a small self-contained test.
- Implement item (2) framebuffer arbitration test (P0). This uses the new arbiter and will give confidence.
- Run `codespell` on `docs/` and propose fixes (low risk).

I will wait for your choice. If you want me to pick, I'll implement the AXI WRAP unit test first (P0) and push a branch `test/axi-wrap` with the test and CI target.