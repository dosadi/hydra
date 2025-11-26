# DMA Controller TODOs

Tracks the controller state machine, blitter integration, status bits, and runtime observability needs for the DMA path inside the RTL shell.

**Next action [P0]:** Document the DMA fixture handshake/BAR decode assumptions in `todo_dma_fixture.md` (pulling constraints from `todo_bus_infrastructure.md`) so the controller implementation has a concrete target before coding starts.

- TODO [P0]: Wire the DMA stub inside `rtl/voxel_axi_core.sv` to a real controller that can burst to DRAM, prefetch blitter operations, and expose `dma_status`/`dma_err` bits to the CSR interface.
- TODO [P0]: Create a lightweight regression fixture that drives the controller through `voxel_shell_legacy.sv` (or a purpose-built harness) to issue DMA bursts, log AXI4 handshakes, and feed `out/dma_controller_trace.json` so we can validate the crossbar arbitration before the bus refactor lands.
- TODO [P1]: Provide `blit_mem_*` hooks so a 3D blitter or copy engine can issue requests via DMA rather than through the main framebuffer path (see `todo_3d_blitter.md`).
- TODO [P1]: Add counters/tracing to the controller so `todo_dma_trace_artifacts.md` and `todo_dma_structured_logging.md` can capture transfers with latency/bandwidth markers.
- TODO [P2]: Sync the DMA controller state machine timing with `todo_system_fps.md` instrumentation so the viewer can flag lockups or underruns in real time.
- TODO [P2]: Document how to fail over to a vendor DMA IP block (closed-source path) by replacing only the controller module while keeping the same CSR interface; describe the gating steps and regression coverage in this tracker.
