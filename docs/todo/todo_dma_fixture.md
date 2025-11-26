# DMA Fixture TODOs

Supporting work for the DMA regression fixture described in `todo_dma_controller.md`. Once implemented, this fixture will validate AXI bursts, check `dma_status`, and produce `out/dma_controller_trace.json`.

- **TODO [P0]:** Define the fixture interface (list of write/read operations, expected `dma_status` transitions) and capture the PASS criteria so downstream regression harnesses can verify AXI responses against the DMA controller.
- **TODO [P1]:** Build the fixture itself—either a dedicated Verilog testbench or cocotb scenario—that drives `voxel_shell_legacy` (or `voxel_csr` + DMA generator) through typical burst patterns, checking `axi4` handshake signals and scattering the results into a JSON trace; see `scripts/dma_fixture_trace.py` for a starter stub that emits the trace placeholder.
- **TODO [P1]:** Wire the fixture into the existing regression script (`sim/tests/run_rtl_tests.sh`), output the trace to `out/dma_controller_trace.json`, and assert that CROSSBAR ownership toggles correctly when `use_dma` flips in `voxel_shell_legacy`.
- **TODO [P2]:** Expose the trace/fixture results to automation by feeding the JSON into `scripts/ai_health_dashboard.py`/`scripts/ai_dashboard_briefing.py` so meta tooling can highlight bus-health regressions.
- **TODO [P2]:** Document how to rerun the fixture, where to find the trace, and what to watch for (timestamp ordering, outstanding beats) inside `docs/todo/todo_dma_controller.md` and the new reference file so engineers can repeat the checks manually.
- **TODO [P2]:** Publish a short AI dashboard nugget (`out/ai_dma_health.txt`) whenever the fixture runs so `todo_meta_todo_plan.md` can cite DMA regression health in the meta summary.
