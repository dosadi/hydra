# Chiplet Integration TODOs

Tracks splitting Hydra into chiplets/dielets or multi-chip modules, coordinating PCIe, DDR, HDMI and driver connectivity across chip boundaries.

## P1 - Partitioning & Interfaces
- **TODO [P1]:** Define Hydra chiplet partitioning (which functions live on each die: ray engine, crossbar, DMA) and document required high-speed links (AXI, PCIe, SerDes) in `docs/chiplet_partition.md`.
- **TODO [P1]:** Add interface standards for chiplet links (protocol, width, DDR timings) and tie them to `todo_crossbar.md` and `todo_dram_axi.md` so automation knows the dependency graph.
- **TODO [P1]:** Provide simulation/emulation harness (multi-chip in Verilator or FPGA) that verifies inter-die transfers and exposes per-chip stats for dashboard gating.
- **TODO [P1]:** Document how chiplets present to drivers (multiple BARs, aggregated interrupts) and add TODOs for driver detection/NUMA handling.

## P2 - Manufacturing & Testing
- **TODO [P2]:** Create a chiplet test plan that covers interposer bonding, DDR PHY stacking, and PCIe splitting; log fixture results in `out/chiplet_validation.json`.
- **TODO [P2]:** Automate packaging documentation (routing templates, thermal interface) so chiplets integrate into existing board design tracker.
- **TODO [P2]:** Add a chiplet readiness checklist used by `scripts/automation_watchdog.sh` to gate multi-chip builds/releases.

## P3 - Ecosystem and Extensions
- **TODO [P3]:** Outline future chiplet extensions (more memory, GPU offload, analog sensors) and note the required automation hooks for inventory/tracking.
