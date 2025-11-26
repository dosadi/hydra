# FPGA TODOs

Hydra-on-FPGA bring-up and integration tasks (Vivado/Quartus-friendly).

- TODO [P0]: Build FPGA top wrapper that replaces stubs (DDR PHY, HDMI out, PCIe or BAR1 BRAM) and aligns pinouts/constraints per target board.
- TODO [P0]: Draft a timing/IO constraints template per board (clocks, diff pairs, voltage banks) and a README for applying them.
- TODO [P1]: Add a minimal on-chip logic analyzer (ILA/SignalTap) signal list for DMA/INT_STATUS/HDMI to speed lab bring-up.
- TODO [P1]: Provide a memory map config for BAR1 replacement (BRAM/URAM window) and document host driver expectations.
- TODO [P1]: Add a scripted bitstream build (`make fpga-vivado`/`fpga-quartus`) with cached IP/user files and a “no IP regeneration” fast path.
- TODO [P2]: Add board-level loopback tests (HDMI test pattern, DMA BRAM copy) runnable via JTAG/UART without PCIe host attached.
- TODO [P2]: Document how to bypass HDMI when unused (stub out sink, keep clocking) for PCIe-only demos.
- TODO [P2]: Provide instructions for flashing and recovering boards (JTAG, QSPI, SD) and storing bitstreams with version tags.
- TODO [P2]: Create FPGA verification checklist (power ramps, configuration retries, monitor ILA asserts) that links to `docs/hardware_validation.md`.
- TODO [P2]: Add coverage for board bring-up firmware (BMC/PMC) to set clocks, power rails, and PCIe PERST sequencing before releasing the FPGA shell.
- TODO [P3]: Explore using LiteX BIOS/monitor for early bring-up so we can debug DDR training in a more friendly command-line environment.
- TODO [P3]: Add a gating regression that runs `scripts/ai_health_dashboard.py` after a bitstream change to ensure the AI dashboard sees latest tracker counts for FPGA/TODO coverage.
