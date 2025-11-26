# IC Packaging & Fabrication TODOs

Tracks chip/interposer packaging, fabrication readiness, and integration with commercial EDA/automation tooling (build systems, manufacturable outputs).

## P1 - Packaging Readiness
- **TODO [P1]:** Define chip/package pin mappings, thermal constraints, and signal integrity margins for the Hydra die/interposer so packaging partners can layout DIMMs or mezzanines.
- **TODO [P1]:** Document fabrication requirements (mask sets, reticle plan, foundry node, timing budgets) and link them to `docs/todo/todo_board_hardware_design.md` and `docs/todo/todo_crossbar.md`.
- **TODO [P1]:** Specify test-target/burn-in board requirements for each package and expose the plan/fixture scripts to `docs/todo/todo_physical_testing.md`.
- **TODO [P1]:** Capture packaging automation (Gerber exports, compression of netlists) within `docs/todo/todo_build_tooling.md` so the build system integrates with commercial fab flows.

## P2 - Fabrication & Commercial Tool Integration
- **TODO [P2]:** Integrate commercial EDA flows (Vivado, Quartus, Synopsys) with the build system so `make fpga`/`cmake` can produce fab-ready outputs and tie automation to `scripts/automation_watchdog.sh`.
- **TODO [P2]:** Automate DRC/LVS/export reporting for each fab run and surface results via `out/fab_verification.json` so the AI dashboard knows the latest yield/regression metrics.
- **TODO [P2]:** Provide scripts that convert the Hydra RTL/build outputs into commercial packaging inputs (XDC, constraint sheets, BOM) and document how to run them (e.g., `scripts/publish_fab_bundle.sh`).
- **TODO [P2]:** Tie the fabrication automation into `docs/todo/todo_dependency_map.md` so downstream trackers (drivers, packaging, QA) inherit the fab status automatically.

## P3 - Commercial Tooling & Lifecycle
- **TODO [P3]:** Add notes about integrating Hydra into commercial flow controllers (Jenkins, Siemens Opcenter) and record the automation steps in this tracker for vendor teams.
- **TODO [P3]:** Maintain an EDA licensing matrix per tool (Vivado, Quartus, Synopsys) with expiration/renewal info and link it to `docs/todo/todo_support_and_licensing.md`.
- **TODO [P3]:** Provide a packaging QA checklist (visual inspection, tomography) and tie it to AI/automation reports for manufacturing release readiness.
