# Hydra Debugging & Visualization Tools TODOs (0.0.7+ Cycle)

**Focus:** Debug tools, visualization aids, profiling, introspection, development utilities.
Improves developer productivity and debugging efficiency.

**Status:** Mix of P1/P2/P3; some tools needed for 0.0.7 development, others are polish.

---

## P1: High Priority Debug Tools (0.0.7 Release)

### RTL Debugging

- TODO [P1]: Add waveform dump controls
  - **Coverage:**
    - Environment variable to enable VCD dump: `DUMP_WAVES=1`
    - Configurable depth (all signals vs. top-level only)
    - Automatic GTKWave opening after sim exit
  - **Effort:** Small (4 hours)
  - **Dependencies:** Verilator VCD support
  - **Validation:** VCD dumps correctly, GTKWave opens
  - **Deliverable:** Waveform dump in `sim/live_sdl_main.cpp`

- TODO [P1]: Add signal probe infrastructure
  - **Coverage:**
    - Export key signals to text file during sim
    - Signals: camera coords, ray hit count, pixel_valid, frame_done
    - CSV format for easy plotting
  - **Effort:** Small (4 hours)
  - **Dependencies:** None
  - **Validation:** Probes log correctly
  - **Deliverable:** Signal probe in sim harness

### Driver Debugging

- TODO [P1]: Enhance driver debug logging
  - **Coverage:**
    - Add debug levels: ERROR, WARN, INFO, DEBUG, TRACE
    - Control via module param: `debug_level=3`
    - Log CSR reads/writes at DEBUG level
    - Log DMA operations at INFO level
  - **Effort:** Medium (1 day)
  - **Dependencies:** None
  - **Validation:** Logs help debug driver issues
  - **Deliverable:** Enhanced logging in driver

- TODO [P1]: Add debugfs interface for driver state
  - **Coverage:**
    - Expose CSR state: `/sys/kernel/debug/hydra/csr_dump`
    - Expose DMA state: `/sys/kernel/debug/hydra/dma_status`
    - Expose interrupt state: `/sys/kernel/debug/hydra/irq_count`
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** debugfs support
  - **Validation:** Debugfs files show correct state
  - **Deliverable:** debugfs entries in driver

---

## P2: Medium Priority Debug Tools (Nice-to-Have)

### Visualization Tools

- TODO [P2]: Create ray visualization overlay
  - **Coverage:**
    - Draw ray paths on screen
    - Show ray hits, misses, step counts
    - Toggle with hotkey (R key)
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Ray data extraction from RTL
  - **Validation:** Rays visualized correctly
  - **Deliverable:** Ray viz in viewer

- TODO [P2]: Add voxel grid overlay
  - **Coverage:**
    - Draw voxel boundaries as wireframe
    - Highlight selected voxel
    - Toggle with hotkey (G key)
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** None
  - **Validation:** Grid aligns with voxels
  - **Deliverable:** Grid overlay in viewer

- TODO [P2]: Implement heat map visualization
  - **Coverage:**
    - Color voxels by ray hit count
    - Identify hot spots in ray marching
    - Export as image for analysis
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Ray hit tracking
  - **Validation:** Heat map shows hotspots
  - **Deliverable:** Heat map mode in viewer

- TODO [P2]: Add frame diff viewer
  - **Coverage:**
    - Compare two frames side-by-side
    - Highlight differences
    - Useful for regression testing
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Frame capture
  - **Validation:** Diffs are accurate
  - **Deliverable:** Diff viewer tool

### Profiling Tools

- TODO [P2]: Add frame time breakdown HUD
  - **Coverage:**
    - Show time spent in: ray gen, voxel fetch, shading, output
    - Real-time bar chart
    - Identify bottlenecks
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Instrumentation in RTL or sim
  - **Validation:** Breakdown is accurate
  - **Deliverable:** Profiling HUD in viewer

- TODO [P2]: Create performance profiler tool
  - **Coverage:**
    - Sample sim at intervals
    - Identify hot functions (gprof integration)
    - Generate flame graph
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** gprof or perf
  - **Validation:** Profiler finds hotspots
  - **Deliverable:** `scripts/profile_sim.sh`

- TODO [P2]: Add memory profiler for sim
  - **Coverage:**
    - Track heap allocations
    - Identify memory leaks
    - Valgrind integration
  - **Effort:** Small (1 day)
  - **Dependencies:** Valgrind
  - **Validation:** Leaks detected
  - **Deliverable:** `scripts/check_memory.sh`

### Introspection Tools

- TODO [P2]: Create CSR inspector GUI
  - **Coverage:**
    - Live view of all CSR values
    - Editable fields (write to device)
    - History of CSR writes
  - **Effort:** Large (5-7 days)
  - **Dependencies:** GUI library (Dear ImGui)
  - **Validation:** GUI updates in real-time
  - **Deliverable:** `tools/csr_inspector/`

- TODO [P2]: Add DMA trace viewer
  - **Coverage:**
    - Visualize DMA transfers over time
    - Timeline view: start, progress, completion
    - Identify stalls, errors
  - **Effort:** Large (5-7 days)
  - **Dependencies:** DMA logging
  - **Validation:** Trace is accurate
  - **Deliverable:** `tools/dma_trace_viewer/`

- TODO [P3]: Implement bus transaction analyzer
  - **Coverage:**
    - Capture AXI-Lite, AXI-Stream transactions
    - Protocol checker
    - Latency analysis
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** RTL instrumentation
  - **Validation:** Analyzer catches issues
  - **Deliverable:** `tools/bus_analyzer/`

### Assertion and Checking

- TODO [P2]: Add runtime assertion framework
  - **Coverage:**
    - Assertions in sim code (C++ asserts)
    - Assertions in RTL (SystemVerilog assertions)
    - Log file on assertion failure
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** None
  - **Validation:** Assertions catch bugs
  - **Deliverable:** Assertion infrastructure

- TODO [P2]: Create invariant checker
  - **Coverage:**
    - Check invariants periodically (e.g., frame_done eventually asserts)
    - Configurable checks
    - Fail loudly on violation
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** None
  - **Validation:** Checker finds violations
  - **Deliverable:** Invariant checker in sim

- TODO [P3]: Add sanitizer builds (ASAN, UBSAN, TSAN)
  - **Coverage:**
    - Already mentioned in `todo_security.md` P2
    - Cross-reference here for completeness
  - **Effort:** Small (4 hours)
  - **Dependencies:** GCC/Clang sanitizers
  - **Validation:** Sanitizers catch bugs
  - **Deliverable:** Sanitizer build targets

---

## P3: Low Priority Debug Tools (Future)
- **TODO [P2]:** Build a synthetic failure corpus (frame dumps + logs) that CI can feed into `scripts/todo_inspect.py` to verify debug tools (waveform dumps, heatmaps) still capture the expected data.
- **TODO [P3]:** Add a “debug API” RFC (docs/todo/todo_debugging_tools.md) describing how to instrument new modules (what sysfs entries, logs, HUD overlays to extend).
- **TODO [P3]:** Create a “debug log aggregator” script that tails sim logs, driver logs, and board-sim outputs and collates them by timestamp for easier triage.
- **TODO [P2]:** Integrate with `scripts/todo_rebalance.py` to warn when major trackers lose debug coverage (e.g., fewer TODOs referencing debug tools) by automatically matching keywords.
- **TODO [P3]:** Add remote debugging support (socket-based capture) so HDL logs can stream over the network to remote viewers, enabling distributed debugging sessions.
- **TODO [P2]:** Crawl `scripts/todo_inspect.py` coverage to ensure every debug artifact (waveform, metric log) is referenced somewhere; flag gaps for TODO creation.
- **TODO [P1]:** Add an “assertion replay” tool that takes an RTL assertion failure log, replays the exact signal sequence in the simulator, and reruns the viewer to recreate the bug visually.
- **TODO [P2]:** Add a curated “debug toolkit” README linking `scripts/board_simulate.sh`, `scripts/automation_watchdog.sh`, `scripts/ci_todo_rebalance.sh`, and new debug utilities so engineers can find instrumentation quickly.

### Advanced Visualization

- TODO [P3]: Create 3D debug viewer (separate from main viewer)
  - **Coverage:**
    - Orbit camera around scene
    - Inspect voxels from any angle
    - Export 3D views for documentation
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** 3D rendering library
  - **Validation:** 3D view is useful
  - **Deliverable:** `tools/debug_3d_viewer/`

- TODO [P3]: Add time-travel debugging
  - **Coverage:**
    - Record sim state at each cycle
    - Step backward/forward in time
    - Inspect state at any point
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** State recording, large storage
  - **Validation:** Time travel works
  - **Deliverable:** Time-travel debug mode

- TODO [P3]: Implement shader debugger
  - **Coverage:**
    - Step through ray marching for single pixel
    - Inspect voxel fetches, lighting calcs
    - Useful for shader development
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** RTL instrumentation
  - **Validation:** Debugger is useful
  - **Deliverable:** `tools/shader_debugger/`

### Automated Testing Aids

- TODO [P3]: Create golden reference generator
  - **Coverage:**
    - Auto-generate golden frames for test scenes
    - Batch processing
    - Store in git for regression tests
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Test scene library
  - **Validation:** Golden frames generated correctly
  - **Deliverable:** `scripts/generate_golden_frames.sh`

- TODO [P3]: Add regression test harness
  - **Coverage:**
    - Run all test scenes
    - Compare against golden frames
    - Generate report of failures
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Golden frame library
  - **Validation:** Regressions detected
  - **Deliverable:** `scripts/run_regression_tests.sh`

- TODO [P3]: Implement bisect tool for regressions
  - **Coverage:**
    - Binary search git history to find regression
    - Automate `git bisect` with frame comparison
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Regression test harness
  - **Validation:** Bisect finds culprit commit
  - **Deliverable:** `scripts/bisect_regression.sh`

### Hardware Debug Tools

- TODO [P3]: Create FPGA debug probe
  - **Coverage:**
    - Expose debug signals to ILA (Integrated Logic Analyzer)
    - Trigger on conditions (e.g., DMA error)
    - Capture waveforms on hardware
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** FPGA with ILA support
  - **Validation:** ILA captures signals
  - **Deliverable:** ILA constraints, debug module

- TODO [P3]: Add ChipScope integration (Xilinx)
  - **Coverage:**
    - Insert ChipScope cores in RTL
    - Live signal monitoring on FPGA
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Vivado license, FPGA
  - **Validation:** ChipScope works
  - **Deliverable:** ChipScope integration

- TODO [P3]: Implement SignalTap integration (Intel)
  - **Coverage:**
    - Insert SignalTap nodes
    - Monitor signals on Intel FPGAs
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Quartus, Intel FPGA
  - **Validation:** SignalTap works
  - **Deliverable:** SignalTap integration

### Documentation and Reports

- TODO [P2]: Create debug guide for developers
  - **Coverage:**
    - How to use debug tools
    - Common debugging scenarios
    - Tips and tricks
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Debug tools implemented
  - **Validation:** Guide is helpful
  - **Deliverable:** `docs/debugging_guide.md`

- TODO [P3]: Add crash report generator
  - **Coverage:**
    - Collect backtrace, logs, state dumps
    - Generate tarball for bug reports
    - Anonymize if needed
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Crash handler
  - **Validation:** Reports help debug issues
  - **Deliverable:** Crash report generator

- TODO [P3]: Create bug report template
  - **Coverage:**
    - Guided questions for reporters
    - Required info checklist
    - Auto-populate system info
  - **Effort:** Small (2 hours)
  - **Dependencies:** None
  - **Validation:** Bug reports are complete
  - **Deliverable:** `.github/ISSUE_TEMPLATE/bug_report.md`

---

## Interactive Debug Console

### Console Infrastructure

- TODO [P3]: Add interactive debug console
  - **Coverage:**
    - REPL for live debugging
    - Execute commands: dump state, set CSR, trigger frame
    - Lua or Python scripting
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** Scripting engine
  - **Validation:** Console is useful
  - **Deliverable:** Debug console in viewer

- TODO [P3]: Implement command history and completion
  - **Coverage:**
    - Arrow keys for history
    - Tab completion for commands
    - Persistent history file
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Console (#above)
  - **Validation:** History/completion works
  - **Deliverable:** Console enhancements

### Console Commands

- TODO [P3]: Add CSR read/write commands
  - **Coverage:**
    - `csr_read <offset>` - Read CSR
    - `csr_write <offset> <value>` - Write CSR
  - **Effort:** Small (1 day)
  - **Dependencies:** Console
  - **Validation:** Commands work
  - **Deliverable:** Console commands

- TODO [P3]: Add camera control commands
  - **Coverage:**
    - `cam_pos <x> <y> <z>` - Set camera position
    - `cam_look <x> <y> <z>` - Set look direction
  - **Effort:** Small (1 day)
  - **Dependencies:** Console
  - **Validation:** Commands work
  - **Deliverable:** Console commands

- TODO [P3]: Add voxel inspect commands
  - **Coverage:**
    - `voxel_get <x> <y> <z>` - Get voxel at coords
    - `voxel_set <x> <y> <z> <type> <color>` - Set voxel
  - **Effort:** Small (1 day)
  - **Dependencies:** Console
  - **Validation:** Commands work
  - **Deliverable:** Console commands

---

## Cross-References

- **RTL assertions:** `todo_testing_ci.md` P0 (SVAs)
- **Driver debugging:** `todo_mesa_drivers.md` (FreeBSD debug)
- **Profiling:** `todo_performance.md` P2 (profiling tools)
- **Sanitizers:** `todo_security.md` P2 (ASAN/UBSAN)
- **Regression testing:** `todo_testing_ci.md` (frame regression)

---

## Estimated Effort (Debugging & Visualization Tools)

| Priority | Items | Effort (days) |
|----------|-------|---------------|
| **P1**   | 4     | 3-6           |
| **P2**   | 14    | 35-60         |
| **P3**   | 20    | 120-200       |
| **Total**| **38**| **158-266**   |

**Note:** P1 items (waveform dump, driver logging) help with 0.0.7 development. P2 items (visualization, profiling) improve productivity in 0.0.8. P3 items (advanced tools, console) are long-term.

### Quick wins for smaller trackers
- TODO [P3]: Publish weekly TODO summaries (from `scripts/todo_sweep.py`) into the debugging tools tracker so the team can see when this area gets fresh attention.
**Recommendation:** Implement P1 debug tools in Sprint 1-2 (aid development). Add P2 visualization in 0.0.8 (after core stable). P3 advanced tools as needed.

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Target Release:** P1 in 0.0.7, P2 in 0.0.8+, P3 long-term
**Owner:** Tools team (TBD)
