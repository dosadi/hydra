# Crossbar & Interconnect TODOs

Focuses on refining the Hydra AXI crossbar/interconnect fabric, arbitration, QoS, and integration points (PCIe, DMA, video, debug) so data flows stay coordinated as more features land.

## P1 - Stage 1 Crossbar Hardening
- **TODO [P1]:** Document the current crossbar fabric topology, arbitration rules, and QoS policy in `docs/crossbar_architecture.md`, aligning with `todo_dma_pcie.md`/`todo_dram_axi.md`.
- **TODO [P1]:** Add configurable arbitration weights (PCIe DMA, video, debug) and tie them into `scripts/ai_health_dashboard.py` so the dashboard can highlight when arbitration shifts yield throughput changes.
- **TODO [P1]:** Implement crossbar health counters (port busy, outstanding transactions) exposed via CSRs and hook them into `script/ai_session_report.py` logs.
- **TODO [P1]:** Add crossbar regression tests that saturate each master port (DMA, HDMI, debug) and verify starvation protection; record failures in `out/crossbar_stress.json`.
- **TODO [P1]:** Add clock domain crossing coverage (AXI ID, data widths) for crossbar-to-DMA/video connections so the scheduler knows when asynchronous paths might need extra buffering.
- **TODO [P1]:** Document crossbar configuration APIs (registers/CSRs) and add TODO entries to this tracker when new masters or targets are added so automation knows to rebaseline priorities.

## P2 - Interconnect Enhancements
- **TODO [P2]:** Provide dynamic QoS knobs (env/env flag) so experimentation can elevate/deprioritize certain AXI masters from automation scripts.
- **TODO [P2]:** Create simulation automation that pumps mixed traffic (DMA + HDMI + debug) and verifies latencies stay within budgets stored for `todo_performance.md`.
- **TODO [P2]:** Document crossbar reconfiguration hooks for future clustering/scale-out work (`docs/todo/todo_clustering.md`), ensuring multiple boards merge their interconnect needs.
- **TODO [P2]:** Add failing-scenario logging that pushes crossbar anomalies into `docs/todo/todo_debugging_tools.md` and the AI dashboard so maintainers can trace interface issues quickly.
- **TODO [P2]:** Integrate crossbar guardrails into `scripts/automation_watchdog.sh` so the watchdog fails when magistral ports starve or counters exceed thresholds from `out/crossbar_stress.json`.
- **TODO [P2]:** Add hardware monitoring of crossbar queue depth and expose via debugfs/sysfs so the viewer/debugger can show congestion levels.
- **TODO [P2]:** Automate QoS verification by comparing crossbar stats before and after enabling new workloads, logging diffs in `out/crossbar_qos_diff.json`.

## P3 - Future Fabric Scope
- **TODO [P3]:** Research integrating other interconnect fabrics (AMBA, TileLink) as optional crossbar backends for future products, listing findings in this tracker so extenders can plan porting tasks.
- **TODO [P3]:** Outline how crossbar extensions (more DMA ports, streaming sensors) should register with the unified extension interface (`docs/todo/todo_extension_interface.md`) and record automation hooks for new master/target IDs.
- **TODO [P3]:** Provide crossbar-centric power/perf metrics (bandwidth per lane, latency per master) and archive them under `out/crossbar_perf.json` so both automation and manufacturing can evaluate fabric changes.
