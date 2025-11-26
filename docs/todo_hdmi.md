# Hydra HDMI / Video Output TODOs (0.0.7 Cycle)

**Focus:** Protocol validation, CRC correctness, backpressure handling.
See `docs/todo_prioritization.md` for sprint plan. Items marked with priority tags: `[P0]` critical, `[P1]` high, `[P2]` medium.

- TODO: Write a quick HDMI bring-up guide (clocking, expected CRC values, sink requirements) for FPGA/hw testing.
- TODO: Add an HDMI “quiet mode” that suppresses verbose logs unless CRC mismatches occur (env/hotkey).
- TODO: Provide a Makefile shortcut to run only HDMI CRC benches and dump artifacts to `sim/build/hdmi/`.
- TODO: Add a tool to compare two HDMI CRC logs and highlight the first mismatch with context.
- DONE [P0]: Document expected HDMI pixel packing/order (RGB888) alongside CRC derivation for firmware reviewers (see `docs/hdmi_scanout_architecture.md`).
- DONE [P0]: Add SVAs to ensure HDMI CRC counters reset on soft_reset and increment only when valid (HDMI counter/CRC stability SVAs in `voxel_axi_core`).
- TODO: Extend HDMI benches to cover different resolutions (32x24, 64x48, 480x360) with golden CRCs.
- TODO: Add coverage that hdmi_beat_count matches expected TOTAL_PIXELS per frame (with tolerance for stalls).
- TODO: Provide an HDMI timing debug dump (line/pixel counters) in cocotb and RTL benches.
- TODO: Add a headless/HDMI sink stub option to capture frames without SDL for CI comparisons.
- TODO: Document HDMI signal mapping (tdata/tuser/tlast) and CRC calculation in the spec.
- TODO: Add a bench that injects backpressure on m_axis_tready to verify stall handling and beat counts.
- TODO: Expose HDMI frame/CRC counters via CSRs and verify readback in cocotb/RTL tests.
- TODO: Add a CI artifact to upload failing HDMI CRC logs and frame dumps for quick triage.
- TODO: Provide an HDMI “test pattern” mode to validate sink alignment and CRC in sim.
- TODO: Add coverage that HDMI CRC mirrors the sink data (no X/Z) across reset and start_frame cycles.
- TODO: Implement an optional HDMI blanking interval check to ensure tuser/tlast timing matches resolution.
- TODO: Add a cocotb monitor to record first/last pixel per line and compare to expected counts.
- TODO: Provide a HUD overlay option to display HDMI frame count/CRC/beat_count for runtime debugging.
- TODO: Add a high-res HDMI bench (e.g., 128x96) with golden CRC to stress timing.
- TODO: Add a bench that randomizes tready stalls to validate robustness under jittery sinks.
- TODO: Provide CI to run HDMI CRC benches with latency injection (SDRAM waitstates) and capture logs.
- TODO: Add assertions that hdmi_crc_last is stable between frames and only updates on frame_done.
- TODO: Expose HDMI counters to debugfs (frame_count, crc_last) for hardware bring-up parity.
- TODO: Add coverage for HDMI pixel format conversion (RGB888) and document expectations.
- TODO: Implement an optional HDMI “frame hash” logging (CRC or checksum) per frame for CI diffs.
- TODO: Add a bench to check that INT_STATUS frame_done only asserts after the final pixel of a frame.
- TODO: Provide a tool/script to parse HDMI CRC logs and highlight mismatches vs. golden.
- TODO: Add coverage that HDMI FR/line/pixel counters reset on soft_reset and start_frame.
- TODO: Document HDMI CSR semantics (HDMI_CRC, HDMI_FR, HDMI_LINE, HDMI_PIX) in the spec and README.
- TODO: Add a cocotb assertion that HDMI tdata/tuser/tlast never go X/Z during active frames.
- TODO: Provide a “HDMI debug dump” script to extract frame dumps from benches and compare visually (PPM).
- TODO: Add coverage that hdmi_line_count/pixel_in_line match configured SCREEN_WIDTH/HEIGHT in RTL benches.
- TODO: Implement a bench that intentionally misconfigures resolution to verify error handling/logs.
- TODO: Add CI to run HDMI CRC benches with HEADLESS backend and capture frame dumps for artifacts.
- TODO: Add coverage that HDMI status CSRs mirror internal counters (frame_count, CRC) without lag.
- TODO: Provide an HDMI “reset storm” bench to pulse soft_reset and ensure counters/CRC recover cleanly.
- TODO: Add debugfs/sysfs hook to read last HDMI CRC/frame count from hardware for parity with sim.
- TODO: Implement an HDMI-only smoke target in Makefile to run CRC benches quickly.
- TODO: Add a golden log check in CI to detect shifts in HDMI counters without CRC mismatch.
