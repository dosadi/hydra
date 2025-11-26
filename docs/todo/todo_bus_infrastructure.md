# Bus Infrastructure TODOs

Focuses on the internal bus/multiplexer fabric (crossbar, AXI gating, LiteDMA handoff) so that the system can scale beyond the current stubbed shell.

- TODO [P0]: Replace the inline gating in `rtl/voxel_shell_legacy.sv` with a parameterized AXI interconnect that can accept additional masters and share QoS knobs; use `docs/rtl_bus_phase_plan.md` as the reference blueprint.
- TODO [P1]: Define a reusable bus controller module (`todo_dma_controller.md` can host its own checklist) that exposes arbitration, error reporting, and tracing hooks while still allowing closed-source IP insertion.
- TODO [P1]: Document how LiteDMA/LiteVideo traffic should traverse the crossbar so `todo_platform_backends.md` and RTL bringing branches share the same assumptions.
- TODO [P2]: Add CI regression coverage that exercises multiple masters (external AXI vs DMA vs framebuffer debugger) through the new interconnect and fails fast when lockups occur; log results to `out/bus_infra_regress`.
- TODO [P3]: Keep the crossbar metadata (topology, priority settings, channel labels) in sync with `docs/todo/todo_dependency_map.md` so automation can rebalance the bus sector when new masters arrive.
