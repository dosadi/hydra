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
- TODO [P3]: Outline a cross-team review process (EEs + RTL) to approve schematic updates and tie it to `docs/todo/todo_board_hardware_design.md`.
- TODO [P2]: Establish a CI-friendly “xschem render” command that produces the current schematic view as a PNG/PDF diff so GUI changes become part of nightly regression checks.
- TODO [P2]: Capture a mapping from critical nets to timing budgets via `xschem/constraints.yaml` and sync it with the ASIC timing TODOs so layout/RTL timing converge.
- TODO [P3]: Add a checklist ensuring every schematic change increments a “version” identifier stored in the repo, and document how to propagate that into board-release notes.
- TODO [P3]: Provide instructions for exporting schematics + BOM to hardware labs (including preferred PDF templates, sheet sizes, layer stacks) so release engineers can print consistent documentation.
- TODO [P1]: Version-control the library with curated commits (tag versions when symbol sets change) and document how to sync `xschem/lib` with the system repo so new branches share the same baseline.
- TODO [P1]: Add regression comparisons for netlist outputs (hash + size) whenever symbols change so `scripts/todo_sweep.py` can flag a library bump before the release.
- TODO [P2]: Automate the symbol/footprint packager that builds `.schlib`/`.pcblib` bundles for downstream vendors.
- TODO [P2]: Track pin-level timing constraints (PI/PO delays, diff-pair lengths) within xschem and link them back to the board-level TODOs so layout captures the same expectations.
- TODO [P3]: Document how to re-run the board-level xschem harness inside `tools/` (spacing, GND-grid) to help hardware folks repro the capture for QA.
- TODO [P3]: Archive a minimal set of `xschem` project files for each release (with README describing versions of symbols/libraries) so reproduction doesn’t depend on live repos.
- TODO [P2]: Integrate xschem lint results with `scripts/todo_inspect.py` so failing rule checks automatically add a TODO entry for the flagged nets/symbols.
- TODO [P3]: Add training notes or short onboarding doc (perhaps in `docs/todo/todo_ai_development.md`) outlining how to open/edit the xschem workspace so newcomers can update schematics safely.
- TODO [P1]: Evaluate migrating critical xschem automations (render, netlist diffing) into a simple Python CLI under `scripts/` so they can be scripted in CI and cross-platform without requiring the GUI.
- TODO [P2]: Build an `xschem` regression harness that loads the same library on Linux/macOS (if possible) and verifies that the generated netlists match expected hashes, guarding against accidental symbol swaps.
- TODO [P2]: Provide a checklist or template for electrical reviewers to mark `xschem` notes (power, clocks, differential pairs) before releases, linking it to `docs/todo/todo_board_hardware_design.md`.
- TODO [P3]: Add a visual diff workflow that captures per-page screenshots and overlays the previous release so mechanical/design reviewers can spot symbol shifts without opening the schematic GUI.
- TODO [P3]: Capture a small script that extracts pin counts/addresses from the xschem library for documentation tables (per-block listing) so downstream docs stay in sync automatically.
- TODO [P1]: Add FPGA-specific schematic variants in `xschem/fpga/` with macros for debug headers, enabling quick board drafts for FPGA prototypes tied to `docs/todo/todo_board_fpga.md`.
- TODO [P2]: Document how to export xschem libraries for third-party reviewers (ZIP package + README) and store metadata (hash, date) to prove the release matches the recorded schematic state.
- TODO [P2]: Integrate the schematic symbol set with `scripts/check_todo_unique.py` so any change to symbol names automatically raises a TODO until reviewed.
- TODO [P3]: Track how schematic power rails map to CAD-specific net names (e.g., `VDDA`, `VDDR`) and record translations in the tracker so firmware/hardware teams can align unexpectedly renamed nets.
- TODO [P2]: Build a script that diff-checks the xschem netlist hierarchy before/after RTL changes and adds informative TODO entries when block boundaries or connections change.
- TODO [P2]: Add automation to ensure every schematic symbol includes descriptive annotations (function, voltage, doc link) and surface missing annotations as TODOs in a validation report.
- TODO [P3]: Document how to stage schematic updates for a release branch, including checklist items for audits, test PCB steps, and release tagging, in `docs/todo/todo_release_notes_0_0_8.md` when ready.
- TODO [P3]: Capture a short “FAQ for schematic reviewers” section describing common pitfalls (wrong pin order, missing power flags, misaligned labels) and add it to this tracker for quick reference.
