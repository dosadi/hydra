# Hydra Clustering & Multi-Board TODOs

**Focus:** Multi-die/multi-board topologies, PCIe fanout, mezzanine stacking, and coordination tooling so Hydra can scale beyond single cards.

## Overview

Targets:
- **Multi-die per board:** split Hydra core across FPGA dies (chiplet, multi-die or multi-FPGA) for higher throughput.
- **Multi-board per mezzanine:** stack Hydra cards on mezzanine carriers or in multi-slot enclosures while keeping PCIe interlock and sync.
- **Clustering orchestration:** maintain firmware/driver support, automated deployment, and monitoring for clustered boards.

## P0 - Scaling Foundations

- **TODO [P0]:** Define the multi-die interface (AXI4 interconnect or custom ribbon) and document timing/clock sharing requirements so board-level routing knows what to carry.
- **TODO [P0]:** Create PCIe switch/bifurcation plans for multi-board enclosures (x16 → x4/x4/x4/x4 or fanout) and map Hydra endpoints to lanes.
- **TODO [P0]:** Design power/thermal budgets for clustered boards (per-die power + shared rails) and capture them in `docs/todo/todo_board_hardware_design.md`.

## P1 - Mezzanine & Multi-Board Infrastructure

- **TODO [P1]:** Draft mezzanine standard (connector pinout, power, management) for stacking Hydra cards, referencing FMC/FMC+ if possible.
- **TODO [P1]:** Add firmware support (BMC/PMIC) that can sequence multiple Hydra boards, expose status via sysfs, and trigger resets per board via scripts.
- **TODO [P1]:** Create a deployment playbook for multi-board clusters (cabling, power sequencing, PCIe enumeration) that ties into the AI dashboard so cluster issues appear in the health summary.
- **TODO [P1]:** Build a clustering benchmark harness that orchestrates multiple Hydra devices via libhydra, synchronizes frame start, and aggregates metrics.

## P2 - Coordination & Tooling

- **TODO [P2]:** Add automation that walks the cluster manifest (`docs/todo/todo_clustering.md` entries) to ensure firmware versions match across boards, failing CI if mismatched.
- **TODO [P2]:** Document the inter-board DMA/stream paths so multi-board frame sync uses correct offsets and avoids PCIe contention.
- **TODO [P2]:** Provide a tool to visualize cluster topology (board/die relationships) that pulls data from `docs/todo/todo_dependency_map.md` and `docs/todo/todo_ai_dashboard.md`.
- **TODO [P2]:** Capture telemetry from each board (temperature, DMA counters) and merge into the Hydra monitoring stub (`scripts/monitor_hydra.sh`) for cluster-wide health.

## P3 - Future Expansion

- **TODO [P3]:** Prototype alternate interconnects (Ethernet/IP-over-PCIe) to tie Hydra boards across racks for distributed inference.
- **TODO [P3]:** Explore host orchestration (Kubernetes jobs, containerized workloads) that can target Hydra clusters through libhydra+container runtimes.
- **TODO [P3]:** Maintain a cluster-release dashboard that surfaces pending firmware/driver updates, PCIe firmware, and TODO statuses for cluster operators.
