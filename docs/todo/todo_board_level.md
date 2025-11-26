# Board-Level TODOs (0.0.7)

Focus on bring-up checklists, schematics/PCB hygiene, and lab workflows. Tags: `[P0]` critical for first spin, `[P1]` high, `[P2]` nice-to-have.

- TODO [P0]: Capture a board bring-up checklist (power rails, reset sequence, JTAG/UART headers, oscilloscope checkpoints) and store under `docs/board_bringup.md`.
- TODO [P0]: Validate pin/power budgets for HDMI + DDR + PCIe simultaneously; document rail margin and decap placement guidance.
- TODO [P1]: Add a net-tie/strap table (boot mode pins, PLL selects, debug straps) with expected resistor values and locations.
- TODO [P1]: Generate a PCB review guide (ERC/DRC rules, length-match targets, diff-pair impedance, return paths) tied to Hydra-specific interfaces.
- TODO [P1]: Add board-level testpoints map (power rails, key clocks, reset, refclk) with photos/coordinates for lab probing.
- TODO [P2]: Create a minimal boundary-scan/JTAG script template (SVF/XSVF) to exercise GPIOs/LEDs before loading bitstreams.
- TODO [P2]: Document thermal/mechanical notes (heatsink/fan spec, airflow assumptions) and a quick IR camera capture checklist.
- TODO [P2]: Add BOM sanity script (lint footprints, check alternates) and store outputs alongside schematics.
- TODO [P3]: Build a “lab log” template for recording board bring-up sessions, timestamp, operator, issue/resolution, and result so regression history is preserved.
- TODO [P3]: Document how to use the Hydra board with FPGA dev tools (Vivado tcl scripts, openocd config) and include quick links to recorded sessions.
- TODO [P3]: Create a hazard log for board-level ESD/power events and tie it to `docs/todo/todo_board_hardware_design.md` for reuse.
- TODO [P3]: Assemble a short “lab readiness” checklist describing the oscilloscope/logic analyzer setup for verifying PCIe lanes and dump it to the tracker.
