# RTL Bus Infrastructure Status & Expansion Plan

Documenting the current state of the RTL bus controllers and a proposed roadmap so future contributors know what is missing (open-source vs. closed-source implications included).

## Current Observations

- `rtl/voxel_axi_core.sv` intentionally leaves address decoding, arbitration, and CDC to the LiteX host, so the core cannot stand alone as a self-sufficient bus controller (`voxel_axi_core` comments, TODOs for DMA wiring). There are no internal crossbars or stubs for PCIe/BAR decoding.
- The DMA path is a stub (range validation, busy/error tracking, no real transfers) and the HDMI counters remain tied off, so diagnostics and real DMA/blitter usage aren’t available yet.
- `rtl/voxel_shell_legacy.sv` uses a fixed 2×2 crossbar stub for the external AXI master/DMA/voxel window, which doesn’t scale to more masters or complex maps; the `rtl/deprecated/axi_crossbar_stub.sv` hints at a future replacement but the current logic is simple mask/gating.

## Expansion Plan

1. Replace the hardcoded gating stub with a parameterized AXI interconnect (open-source-friendly, e.g., derived from the deprecated `axi_crossbar` stub) that supports additional masters/targets, priority settings, and BAR decoding. This opens the door for integrating PCIe, DMA, and other masters without rewriting the shell.
2. Turn the DMA stub in `voxel_axi_core.sv` into a real controller capable of burst transfers, status reporting, error handling, and optional tracing; wire the `blit_mem_*` ports so a blitter engine can attach, and connect the controller to the LiteDMA frontend. Doing so addresses the TODO comments and unlocks autonomous framebuffer copies.
3. Introduce modular bus adapters for different host interfaces (PCIe BARs, AXI4 and AXI-Stream consumers) with documented hooks for clocks/resets. Keep the integration layer stable enough to swap in closed-source or vendor IP where needed without altering the rest of the RTL, and capture this strategy in `docs/todo/todo_ip_integration.md`.

## Open-source vs Closed-source Implications

- Keeping the interconnect and DMA logic open lets community contributors understand and extend the system, and ensures automation scripts (e.g., `scripts/automation_watchdog.sh`) can validate every path.
- For closed-source or vendor-specific boards, the same top-level ports can be bound to proprietary crossbar/DMA blocks while the module interfaces remain identical; document this dual-path strategy so integrators know how to plug in their IP without touching the open RTL.

## Next Steps

- Turn the plan above into concrete TODOs (e.g., `docs/todo/todo_dma_pcie.md`, `docs/todo/todo_crossbar.md`, `docs/todo/todo_ip_integration.md`).
- Connect these TODOs to the dependency map (`docs/todo/todo_dependency_map.md`) and automation dashboards so gaps are visible.
