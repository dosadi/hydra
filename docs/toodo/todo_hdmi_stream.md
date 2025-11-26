# HDMI Stream & Backpressure TODOs

Focuses on the raw pixel stream, tile/frame buffering, CRC registers, and fault/integration coverage needed for simulation/driver agreement.

- **TODO [P1]:** Document the pixel format (RGB888) packing in `m_axis_tdata` and add simulation asserts ensuring no other bits leak into CRC.
- **TODO [P1]:** Add a stream backpressure stress test (inject wait-states) to the DMA pipeline to ensure the HDMI path tolerates stalls.
- **TODO [P2]:** Capture CRC compare logs in `sim/tests` and provide a script that highlights frame drops or mismatched CRCs.
- **TODO [P2]:** Add a driver verification test that toggles SDL backends while capturing CRCs for subsequent diff.
- **TODO [P3]:** Provide a README section on HDMI drift (line/field jitter) for integrators, referencing required counters/thresholds.
- **TODO [P3]:** Document the HDMI stress-test checklist (injecting wait-states, CRC mismatch, forced backpressure) with expected log outputs.
