# xschem TODOs

Schematic capture hygiene and symbol/library work to keep RTL ↔ board flow aligned.

- TODO [P0]: Standardize pin naming/order on hydra blocks (AXI-lite/AXI/DDR/HDMI) and regenerate symbols to match RTL port order.
- TODO [P1]: Add ERC/DRC rule deck specific to Hydra (missing power flags, unconnected buses, mixed analog/digital warnings) and store it under `xschem/rules/`.
- TODO [P1]: Create a shared symbol library for stub IP (SDRAM, DMA, HDMI sink, PCIe edge) with parameter notes and revision tags.
- TODO [P1]: Script netlisting/lint (hier flatten + bus width checks) and make it a CI-able target (`make xschem-lint`).
- TODO [P2]: Add cross-probing notes between xschem net names and RTL signals for major interfaces (DDR address map, BAR0/1, HDMI).
- TODO [P2]: Document import/export flow to PCB tools (KiCad/Altium) and verify pin swaps/diff-pair constraints survive the translation.
- TODO [P3]: Capture a lightweight “xschem freshness” script that verifies each symbol references the latest RTL port order; run it before releasing new RTL.
- TODO [P3]: Publish a short “symbol change log” within the tracker so new design engineers can see which blocks were touched that week.
- TODO [P3]: Add a "schematic smoke test" summarize (screenshots + steps) to the tracker so reviewers can reproduce the latest electrical revisions.
- TODO [P3]: Outline a cross-team review process (EEs + RTL) to approve schematic updates and tie it to `docs/toodo/todo_board_hardware_design.md`.
