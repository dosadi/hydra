# HDMI Display & Timing TODOs

Focuses on HDMI output timing/clk, CRC/counters, connectors, and platform integration (links/backpressure) to ensure sync and compliance.

- **TODO [P0]:** Define HDMI timing parameters (V/ H total, sync widths) in the Xiilin spec doc and validate them against the RTL values.
- **TODO [P0]:** Instrument HDMI counters (frame/line/pixel) and expose them via CSRs for driver validation.
- **TODO [P1]:** Add CRC generation/validation reference (link doc) that matches sim/hardware registers plus expected golden CSV values.
- **TODO [P1]:** Document connector assignment/format (DP/HDMI) for upcoming board builds and note which outputs map to which signals.
- **TODO [P2]:** Add platform-specific adjustments (e.g., picom compatibility, headless CRC bypass) to docs for embedding in Linux/macOS/Windows builds.
- **TODO [P2]:** Track plan for HDMI callbacks when switching display modes (link train, mode filter, fallback to headless).
- **TODO [P3]:** List known HDMI regression steps (CRC mismatch, resolution changes) and tie them to regression tooling (capture CRC logs, frame dumps).
- **TODO [P3]:** Add a short site note describing HDMI capability matrix (resolutions, CRC options, connectors) for integrators and link to the tracker.
