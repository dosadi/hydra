TODO Summary (auto-generated)

Scan date: 2025-11-27
Scanned pattern: TODO | FIXME | XXX

Priority guide:
- P0: High risk / correctness (affects RTL behavior, arbitration, memory correctness)
- P1: Medium risk (simulation, CI, or test infra)
- P2: Low risk (stubs, docs, cosmetic)

Findings (file : excerpt -> recommended action / priority)

- `rtl/voxel_raycaster_core_pipelined.sv`: "TODO: Integrate material_id into shading pipeline for future features"
  - Action: Track as feature work; no immediate correctness impact. (P2)

- `rtl/axi_sdram_stub.sv`: "TODO: Add support for advanced AXI features..." (multiple occurrences)
  - Action: If target flow uses real memory, prioritize implementing burst/QoS/region handling; otherwise keep as stub with clear test harness coverage. (P0/P1 depending on test coverage)

- `rtl/voxel_framebuffer_top.sv`: "TODO: Implement priority arbitration logic for debug writes vs. world_gen"
  - Action: This affects potential write ordering and correctness under contention — schedule review and add assertion coverage around arbitration. (P0)

- `rtl/voxel_memory_64.sv`: "TODO: Add support for pattern or random initialization"
  - Action: Helpful for fuzz/seeded tests; low priority. (P2)

- `rtl/surface_extractor.sv`: two TODOs about normal/curvature/surface extraction logic
  - Action: Feature work; add unit tests / cocotb test vectors when implemented. (P2)

- `rtl/axi_stream_sink_stub.sv`: TODOs about `tuser`/`tlast` handling
  - Action: If HDMI/TMDS or stream consumer tests exist, implement these; else keep as stub but mark for integration testing. (P1)

- `drivers/mesa/*.c`: several TODO stubs (caps/format query, blit/resource ops)
  - Action: Stubs for driver integration; prioritize if running Mesa-based tests. (P2)

- `Makefile`: duplicated/help lines and a small formatting typo (e.g., `cam-flags-demo- Sample:`)
  - Action: Fix duplication/typos (low risk). (P2)

Recommendations / Next steps
- Short term (now):
  - Create `docs/TODO_SUMMARY.md` (this file) and open small PRs for low-risk fixes (Makefile help typos, docs fixes). (this PR)
  - Open PR for `update/golden-frame-...` (already pushed) for review/CI. (P1)

- Medium term:
  - Triage RTL P0 items: arbitration in `voxel_framebuffer_top.sv`, AXI memory semantics in `axi_sdram_stub.sv`. Add assertions and small unit tests. (P0)
  - Add CI smoke job using `HYDRA_BACKEND=AALIB` and `scripts/auto_iterate.sh` in dry-run mode to guard against regressions. (P1)

- Long term:
  - Replace placeholder integration files with official package when provided. (P1/P0 depending on contents)
  - Expand cocotb/ formal SBY flows for critical modules.

If you'd like, I can now apply the low-risk Makefile fix and open the draft PR for `update/golden-frame-20251127T105702Z`.
