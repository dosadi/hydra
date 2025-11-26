# DMA Hang/Retry Policy TODOs

Focuses on documenting driver/PCIe hang detection, retry/reset behavior, and automated resume workflows so bring-up engineers know what to do when DMA stalls.

- **TODO [P1]:** Write a precise hang detection specification (timeouts, watchdog thresholds, err bits/pulses) and store it under `docs/dma_hang_policy.md`.
  - Effort: 1 day
  - Deliverable: YAML spec with thresholds for MSI vs. INTx
  - Validation: Document reviewed by driver/core team

- **TODO [P2]:** Add driver logic that tracks DMA start timestamps and triggers `soft_reset`/`dma_ctrl` toggles after 500ms without progress, logging the action.
  - Effort: 2 days
  - Deliverable: driver patch and logged example

- **TODO [P2]:** Add a libhydra helper (`hydra_dma_watchdog()`) that users can call to poll DMA status and trigger resets, plus a CLI tool that uses it.
  - Effort: 1.5 days
  - Deliverable: CLI `scripts/hydra_dma_watchdog.c`

- **TODO [P3]:** Document how the sim/stub handles hang detection (DMA status bits + watchdog) so cocotb/RTL tests can reproduce the scenario.
  - Effort: 1 day
  - Deliverable: Section in `docs/todo/todo_dma_pcie.md` referencing this file
- **TODO [P2]:** Pull hang-event log entries into debug tools (with `scripts/todo_inspect.py`) to keep the policy fresh and visible.
- **TODO [P3]:** Add a lab-ready checklist (LED indicators, watchdog thresholds to observe) for DMA hang recovery, link to `docs/todo/todo_build_devtools.md`.

- **TODO [P1]:** Record hang/retry events in structured logs so `scripts/todo_inspect.py` can chart hang frequencies and surface flaky DMA resets on the HUD.
  - Effort: 1 day
  - Deliverable: Logging doc + sample HUD output
- **TODO [P2]:** Add a nightly regression script (`scripts/dma_hang_sim.sh`) that races the viewer/DMA path under stress (forced wait states) and tracks whether the watchdog recovers without manual reset.
  - Effort: 2 days
  - Deliverable: Script + log of tracked resets
