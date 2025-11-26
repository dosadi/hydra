# Multicore Architecture TODOs

Tracks efforts to split Hydra workloads across multiple CPU/FPGA cores, including scheduling, cache coherence, data partitioning, and automation hooks.

## P1 - Core Scheduling & Data Partitioning
- **TODO [P1]:** Document Hydra’s multicore scheduling strategy (CPU + ray core + DMA) and publish APIs for assigning frame segments or DMA queues to cores, referencing `docs/design_gaming_integration.md`.
- **TODO [P1]:** Add automation metrics that log per-core utilization (CPU, PCIe DMA, HDMI, ray units) to `out/multicore_metrics.json`, feeding `scripts/ai_health_dashboard.py`.
- **TODO [P1]:** Implement per-core frame queuing (frame queues per core) and ensure coordination via `scripts/automation_watchdog.sh` so automation warns when a core lags behind.

## P2 - Coherence & Synchronization
- **TODO [P2]:** Extend trackers to cover cache/backpressure coherence (AXI interlocks, mutexes) when multiple cores access shared framebuffer/CSRs.
- **TODO [P2]:** Add a multicore regression harness that runs multi-core workload combos and logs cross-core locks/timing to the AI dashboard.
- **TODO [P2]:** Document how multicore scheduling impacts support/drivers (`todo_support_and_licensing.md`) so field teams understand multi-core diagnostics.

## P3 - Future Multicore Expansion
- **TODO [P3]:** Research general multicore APIs (task graphs, RTOS) to allow heterogeneous Hydra deployments (C++/Python scheduling vs firmware).
