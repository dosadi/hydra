# TODO Priority Next Steps

This living summary pulls together the highest-priority (**P0**) items across the tracker landscape so we can “start working” by picking manageable bite-sized follow-ups with the right dependencies.

## P0 Snapshot (by sector)

- **RTL Core & Ray Engine (SECTOR-01)** – ensure the ray engine emits consistent depth/reemissure data and ties into the color pipeline automation (`todo_ray_engine.md`, `todo_depth_buffer.md`, `todo_reemissure.md`). Start with instrumentation gaps (depth resets, reemissure normalization) before adding new rendering effects so upstream viewer work doesn't break.
- **AXI/PCIe/DMA Infrastructure (SECTOR-02 & 22)** – finish wiring the DMA controller stub (`todo_dma_controller.md`) so it can burst through the new bus fabric (`todo_bus_infrastructure.md`). Prioritize the crossbar refactor and DMA-to-memory QoS knobs, then add automated coverage that exercises the multiple masters.
- **Memory Systems (SECTOR-23)** – begin integrating the memory hierarchy plan (`todo_memory_system.md`) with HBM prep (`todo_hbm_integration.md`) so teams know where each tier lives; highlight the open vs closed PHY path and capture memory-layout asserts for the new controller.
- **Meta Automation (SECTOR-19)** – keep `scripts/meta_refresh.py`/`scripts/validate_dependency_map.py` tuned (already hooked into `scripts/automation_watchdog.sh`), and use this doc plus `todo_meta_todo_plan.md` to log each refresh. Mention any blockers discovered while you work on the P0 tasks above.

## Next Actions

1. Pick one of the P0 bullets above and break it into a concrete deliverable (test bench, doc, automation hook). Record the next sub-task in the relevant tracker (`todo_dma_controller.md`, `todo_depth_buffer.md`, etc.) and note any dependencies in `todo_dependency_map.md`.
2. After implementing the deliverable, run the meta scripts (`scripts/meta_refresh.py`, `scripts/validate_dependency_map.py`) so automation dashboards reflect the new status and regression coverage for the affected tracker.
3. Repeat by cycling through the next P0-high tracker, keeping focus on one dependency path at a time to avoid context switching.

Use this file as the “mission statement” for the next sprint so reviewers instantly know which priority chain is in motion.
