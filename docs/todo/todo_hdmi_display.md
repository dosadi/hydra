# HDMI Display & Timing TODOs

Focuses on HDMI output timing/clk, CRC/counters, connectors, and platform integration (links/backpressure) to ensure sync and compliance.

- **TODO [P0]:** Define HDMI timing parameters (V/ H total, sync widths) in the Xiilin spec doc and validate them against the RTL values.
- **TODO [P0]:** Instrument HDMI counters (frame/line/pixel) and expose them via CSRs for driver validation.
- **TODO [P1]:** Add CRC generation/validation reference (link doc) that matches sim/hardware registers plus expected golden CSV values.
- **TODO [P1]:** Document connector assignment/format (DP/HDMI) for upcoming board builds and note which outputs map to which signals.
- **TODO [P1]:** Add HDMI hotplug detection handling notes (interrupt path, debouncing, fallback) to `todo_dma_pcie.md` so driver/board bring-up handles cable events.
- **TODO [P1]:** Create HDMI timing verification script that compares actual counts against spec and updates `out/hdmi_timing_report.txt` for CI dashboards.
- **TODO [P2]:** Add platform-specific adjustments (e.g., picom compatibility, headless CRC bypass) to docs for embedding in Linux/macOS/Windows builds.
- **TODO [P2]:** Track plan for HDMI callbacks when switching display modes (link train, mode filter, fallback to headless).
- **TODO [P2]:** Automate HDMI CRC capture by wiring `scripts/ci_collect_logs.sh` to pull CRC counters from sim logs and attach them to the ever-running AI health dashboard artifact.
- **TODO [P3]:** List known HDMI regression steps (CRC mismatch, resolution changes) and tie them to regression tooling (capture CRC logs, frame dumps).
- **TODO [P3]:** Add a short site note describing HDMI capability matrix (resolutions, CRC options, connectors) for integrators and link to the tracker.
- **TODO [P3]:** Build an HDMI compliance checklist (timing, voltage swings, ESD) and surface it whenever `docs/todo/todo_hdmi.md` is updated so compliance stays coupled to the tracker.
