# Crossbar & Interconnect TODOs

Focuses on refining the Hydra AXI crossbar/interconnect fabric, arbitration, QoS, and integration points (PCIe, DMA, video, debug) so data flows stay coordinated as more features land.

## P1 - Stage 1 Crossbar Hardening
- **TODO [P1]:** Document the current crossbar fabric topology, arbitration rules, and QoS policy in `docs/crossbar_architecture.md`, aligning with `todo_dma_pcie.md`/`todo_dram_axi.md`.
- **TODO [P1]:** Add configurable arbitration weights (PCIe DMA, video, debug) and tie them into `scripts/ai_health_dashboard.py` so the dashboard can highlight when arbitration shifts yield throughput changes.
- **TODO [P1]:** Implement crossbar health counters (port busy, outstanding transactions) exposed via CSRs and hook them into `script/ai_session_report.py` logs.
- **TODO [P1]:** Add crossbar regression tests that saturate each master port (DMA, HDMI, debug) and verify starvation protection; record failures in `out/crossbar_stress.json`.

## P2 - Interconnect Enhancements
- **TODO [P2]:** Provide dynamic QoS knobs (env/env flag) so experimentation can elevate/deprioritize certain AXI masters from automation scripts.
- **TODO [P2]:** Create simulation automation that pumps mixed traffic (DMA + HDMI + debug) and verifies latencies stay within budgets stored for `todo_performance.md`.
- **TODO [P2]:** Document crossbar reconfiguration hooks for future clustering/scale-out work (`docs/todo/todo_clustering.md`), ensuring multiple boards merge their interconnect needs.
- **TODO [P2]:** Add failing-scenario logging that pushes crossbar anomalies into `docs/todo/todo_debugging_tools.md` and the AI dashboard so maintainers can trace interface issues quickly.

## P3 - Future Fabric Scope
- **TODO [P3]:** Research integrating other interconnect fabrics (AMBA, TileLink) as optional crossbar backends for future products, listing findings in this tracker so extenders can plan porting tasks.
- **TODO [P3]:** Outline how crossbar extensions (more DMA ports, streaming sensors) should register with the unified extension interface (`docs/todo/todo_extension_interface.md`) and record automation hooks for new master/target IDs.
