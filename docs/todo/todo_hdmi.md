# Hydra HDMI / Video Output TODOs (0.0.7 Cycle)

**Focus:** Protocol validation, CRC correctness, backpressure handling.
See `docs/TODO_MASTER_INDEX.md` for complete tracker reference. Priority tags: `[P0]` critical, `[P1]` high, `[P2]` medium, `[P3]` low/future.

## P0 - Critical (Blocks 0.0.7 Release)

- DONE [P0]: Document expected HDMI pixel packing/order (RGB888) alongside CRC derivation for firmware reviewers (see `docs/hdmi_scanout_architecture.md`).
- DONE [P0]: Add SVAs to ensure HDMI CRC counters reset on soft_reset and increment only when valid (HDMI counter/CRC stability SVAs in `voxel_axi_core`).

## P1 - High Priority (Hardware Bring-Up Essentials)

- TODO [P1]: Write a quick HDMI bring-up guide (clocking, expected CRC values, sink requirements) for FPGA/hw testing.
- TODO [P1]: Document HDMI signal mapping (tdata/tuser/tlast) and CRC calculation in the spec.
- TODO [P1]: Add a bench that injects backpressure on m_axis_tready to verify stall handling and beat counts.
- TODO [P1]: Expose HDMI frame/CRC counters via CSRs and verify readback in cocotb/RTL tests.
- TODO [P1]: Extend HDMI benches to cover different resolutions (32x24, 64x48, 480x360) with golden CRCs.
- TODO [P1]: Add coverage that hdmi_beat_count matches expected TOTAL_PIXELS per frame (with tolerance for stalls).
- TODO [P1]: Add assertions that hdmi_crc_last is stable between frames and only updates on frame_done.
- TODO [P1]: Document HDMI CSR semantics (HDMI_CRC, HDMI_FR, HDMI_LINE, HDMI_PIX) in the spec and README.

## P2 - Medium Priority (Testing & Debug Tools)

- TODO [P2]: Add a CI artifact to upload failing HDMI CRC logs and frame dumps for quick triage.
- TODO [P2]: Provide an HDMI timing debug dump (line/pixel counters) in cocotb and RTL benches.
- TODO [P2]: Add a headless/HDMI sink stub option to capture frames without SDL for CI comparisons.
- TODO [P2]: Provide an HDMI "test pattern" mode to validate sink alignment and CRC in sim.
- TODO [P2]: Add coverage that HDMI CRC mirrors the sink data (no X/Z) across reset and start_frame cycles.
- TODO [P2]: Implement an optional HDMI blanking interval check to ensure tuser/tlast timing matches resolution.
- TODO [P2]: Add a cocotb monitor to record first/last pixel per line and compare to expected counts.
- TODO [P2]: Add a bench that randomizes tready stalls to validate robustness under jittery sinks.
- TODO [P2]: Provide CI to run HDMI CRC benches with latency injection (SDRAM waitstates) and capture logs.
- TODO [P2]: Expose HDMI counters to debugfs (frame_count, crc_last) for hardware bring-up parity.
- TODO [P2]: Add coverage for HDMI pixel format conversion (RGB888) and document expectations.
- TODO [P2]: Implement an optional HDMI "frame hash" logging (CRC or checksum) per frame for CI diffs.
- TODO [P2]: Add a bench to check that INT_STATUS frame_done only asserts after the final pixel of a frame.
- TODO [P2]: Add coverage that HDMI FR/line/pixel counters reset on soft_reset and start_frame.
- TODO [P2]: Add a cocotb assertion that HDMI tdata/tuser/tlast never go X/Z during active frames.
- TODO [P2]: Add coverage that hdmi_line_count/pixel_in_line match configured SCREEN_WIDTH/HEIGHT in RTL benches.
- TODO [P2]: Implement a bench that intentionally misconfigures resolution to verify error handling/logs.
- TODO [P2]: Add CI to run HDMI CRC benches with HEADLESS backend and capture frame dumps for artifacts.
- TODO [P2]: Add coverage that HDMI status CSRs mirror internal counters (frame_count, CRC) without lag.
- TODO [P2]: Provide an HDMI "reset storm" bench to pulse soft_reset and ensure counters/CRC recover cleanly.
- TODO [P2]: Implement an HDMI-only smoke target in Makefile to run CRC benches quickly.
- TODO [P2]: Add a golden log check in CI to detect shifts in HDMI counters without CRC mismatch.
- TODO [P2]: Provide a Makefile shortcut to run only HDMI CRC benches and dump artifacts to `sim/build/hdmi/`.
- TODO [P2]: Add debugfs/sysfs hook to read last HDMI CRC/frame count from hardware for parity with sim.

## P3 - Low Priority (Advanced Features & Tools)

- TODO [P3]: Add an HDMI "quiet mode" that suppresses verbose logs unless CRC mismatches occur (env/hotkey).
- TODO [P3]: Add a tool to compare two HDMI CRC logs and highlight the first mismatch with context.
- TODO [P3]: Provide a HUD overlay option to display HDMI frame count/CRC/beat_count for runtime debugging.
- TODO [P3]: Add a high-res HDMI bench (e.g., 128x96) with golden CRC to stress timing.
- TODO [P3]: Provide a tool/script to parse HDMI CRC logs and highlight mismatches vs. golden.
- TODO [P3]: Provide a "HDMI debug dump" script to extract frame dumps from benches and compare visually (PPM).
