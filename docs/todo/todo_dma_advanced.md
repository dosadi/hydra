# Advanced DMA TODOs

Focuses on specialized DMA features and instrumentation beyond the core DMA/PCIe tracker, covering descriptor tooling, QoS, multi-master fairness, hypervisor integration, and advanced analytics.

## P1 - Descriptor, QoS & Instrumentation
- **TODO [P1]:** Build a descriptor validation tool (`scripts/dma_descriptor_lint.py`) that scans descriptor lists from `libhydra` tests and flags aligned/overlap violations before hardware runs.
- **TODO [P1]:** Add QoS knobs (priority, weight) to DMA channels and provide CSRs/debugfs controls plus automation logging (`out/dma_qos.json`) so the AI dashboard observes throughput shifts.
- **TODO [P1]:** Extend DMA trace logs to include timestamped descriptor IDs, enabling debug scripts to correlate time vs descriptor usage.
- **TODO [P1]:** Provide per-stream health counters (bytes in-flight, timeout counts) and expose them to automation (AI dashboard + `todo_system_fps.md`) so multiple DMA workloads can be compared.

## P2 - Systems & Ecosystem Integration
- **TODO [P2]:** Document DMA virtualization requirements (pass-through, IOMMU domains) and add TODO entries when virtualization features are broken or absent.
- **TODO [P2]:** Integrate DMA instrumentation into `scripts/ai_session_report.py` so each AI session logs descriptors handled/latency encountered.
- **TODO [P2]:** Add a DMA stress harness that drives overlapping descriptor sets across multiple contexts and reports completion order + fairness via `out/dma_stress.json`.
- **TODO [P2]:** Provide an automated staging plan for driver/libhydra/firmware updates that touch DMA, linking these updates to `docs/todo/todo_dependency_map.md`.

## P3 - Future DMA Innovations
- **TODO [P3]:** Explore programmable DMA shaders (defining data transforms) and note how they would integrate with `todo_content_creation.md` for asset streaming.
- **TODO [P3]:** Maintain a DMA research log capturing third-party IP ideas (e.g., compression, zero-copy) so future releases can track what unresolved DMA tasks remain.
