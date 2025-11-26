# Testing & CI Infrastructure TODO Tracker

**Last Updated:** 2025-11-25 (Expanded)
**Owner:** QA/Testing Team
**Related Trackers:** `todo_build_tooling.md`, `todo_hardware_validation.md`, `todo_security.md`, `todo_mesa_drivers.md`

---

## Overview

Tracks testing infrastructure expansion, CI pipeline hardening, regression test suites, and quality assurance processes. Focus areas: RTL testbenches, driver kselftests, visual regression, protocol compliance, CI coverage.

**Priority Distribution:**
- **P0:** 11 items (~18 days) - Critical testing gaps blocking 0.0.7
- **P1:** 24 items (~40 days) - High-value test coverage
- **P2:** 28 items (~45 days) - Extended test coverage
- **P3:** 17 items (~25 days) - Future test infrastructure

**Total:** 80 items, ~128 engineer-days

---

## P0 - Critical Testing Gaps (Blocks 0.0.7 Release)

### RTL Testbenches (Critical)
- **TODO [P0]:** Refresh `golden_frame.ppm` for current visuals (Phase 1 complete)
  - **Effort:** 0.5 days
  - **Priority:** P0 - Frame regression currently failing
  - **Dependencies:** Phase 1 visual changes merged
  - **Validation:** `make test_frame` passes with current output
  - **Deliverable:** Updated `sim/tests/golden_frame.ppm`
  - **Notes:** Capture with known camera position/seed

- **TODO [P0]:** Add AXI-Lite protocol lint in CI (verilator --lint-only with SVAs)
  - **Effort:** 2 days
  - **Priority:** P0 - Protocol compliance critical
  - **Dependencies:** SVAs in voxel_axil_csr.sv
  - **Validation:** CI fails on assertion violations
  - **Deliverable:** CI job `rtl-lint-axi`
  - **Status:** DONE - Extend to all AXI interfaces

- **TODO [P0]:** Validate all CSR reset defaults match spec in RTL testbench
  - **Effort:** 2 days
  - **Priority:** P0 - Spec compliance for hardware
  - **Dependencies:** Spec updated with defaults
  - **Validation:** Testbench checks every CSR reset value
  - **Deliverable:** Extended test_voxel_axil_csr_simple.sv
  - **Status:** Partially done - add all CSRs 0x00-0xFF

- **TODO [P0]:** Add frame_done pulse validation testbench (timing, pixel count)
  - **Effort:** 2 days
  - **Priority:** P0 - Frame completion correctness
  - **Dependencies:** None
  - **Validation:** Frame_done pulses after exactly TOTAL_PIXELS
  - **Deliverable:** RTL testbench or SVA
  - **Notes:** Check frame_done only pulses once per frame

### Driver Testing (Critical)
- **TODO [P0]:** Add kselftest-style DMA IOCTL script (good/bad offsets)
  - **Effort:** 2 days
  - **Priority:** P0 - Driver input validation gate
  - **Dependencies:** Driver DMA ioctl implemented
  - **Validation:** Script detects -EINVAL on bad offsets
  - **Deliverable:** `scripts/kselftests/hydra_dma_test.sh`
  - **Notes:** Test src+len wrap, dst+len wrap, alignment

- **TODO [P0]:** Add userspace smoke test for all basic ioctls (INFO, RD32, WR32)
  - **Effort:** 2 days
  - **Priority:** P0 - Driver functionality gate
  - **Dependencies:** libhydra stable
  - **Validation:** Smoke test passes on Linux and FreeBSD
  - **Deliverable:** `scripts/hydra_smoke.sh`
  - **Notes:** Should run in CI on every PR

### CI Infrastructure (Critical)
- **TODO [P0]:** Add CI job to run RTL testbenches (iverilog/vvp)
  - **Effort:** 2 days
  - **Priority:** P0 - RTL regression protection
  - **Dependencies:** run_rtl_tests.sh stable
  - **Validation:** CI runs all RTL tests, fails on error
  - **Deliverable:** CI job `test-rtl-benches`
  - **Notes:** Best-effort if iverilog missing

- **TODO [P0]:** Add CI artifact upload for frame_diff.log and failing frames
  - **Effort:** 1 day
  - **Priority:** P0 - Faster triage
  - **Dependencies:** CI artifact storage
  - **Validation:** Failed test_frame uploads diff log and PPM
  - **Deliverable:** Artifact upload in CI workflow
  - **Status:** Mentioned in build_tooling - implement here

- **TODO [P0]:** Ensure CI fails fast on critical test failures (RTL lint, frame regression)
  - **Effort:** 1 day
  - **Priority:** P0 - CI reliability
  - **Dependencies:** None
  - **Validation:** Critical test failure stops workflow immediately
  - **Deliverable:** CI job dependencies configured

### Visual Regression
- **TODO [P0]:** Update frame regression to handle Phase 2 visual changes (fog+AO)
  - **Effort:** 1 day
  - **Priority:** P0 - Will break when Phase 2 merges
  - **Dependencies:** Phase 2 rendering complete
  - **Validation:** Golden frame updated with Phase 2 output
  - **Deliverable:** New golden_frame.ppm

- **TODO [P0]:** Add deterministic test mode (fixed seed, camera, flags) for frame regression
  - **Effort:** 2 days
  - **Priority:** P0 - Reproducible visual tests
  - **Dependencies:** World seed override, camera env vars
  - **Validation:** Frame output identical across runs
  - **Deliverable:** Deterministic test mode in sim
  - **Status:** Env vars exist - document test mode

---

## P1 - High Priority Test Coverage (Recommended for 0.0.7)

### RTL Protocol Compliance
- **TODO [P1]:** Add cocotb AXI-Lite protocol checker (axi-lite-bfm)
  - **Effort:** 4 days
  - **Priority:** P1 - Protocol compliance
  - **Dependencies:** Cocotb setup
  - **Validation:** Protocol violations detected
  - **Deliverable:** AXI-Lite BFM in cocotb tests

- **TODO [P1]:** Expand cocotb smoke to cover all CSRs (BAR0 0x00-0xFF)
  - **Effort:** 3 days
  - **Priority:** P1 - CSR coverage
  - **Dependencies:** Cocotb basic test working
  - **Validation:** All CSRs read/write tested
  - **Deliverable:** Extended cocotb CSR test
  - **Status:** Basic test exists - expand coverage

- **TODO [P1]:** Add cocotb test for DMA_DONE/INT_MASK gating
  - **Effort:** 2 days
  - **Priority:** P1 - Interrupt logic validation
  - **Dependencies:** DMA stub or IP integrated
  - **Validation:** INT_MASK correctly gates IRQ signals
  - **Deliverable:** Cocotb interrupt test

- **TODO [P1]:** Add AXI transaction trace (JSON/CSV) for debugging
  - **Effort:** 3 days
  - **Priority:** P1 - Debug capability
  - **Dependencies:** Cocotb AXI monitor
  - **Validation:** Trace captures all AXI transactions
  - **Deliverable:** AXI trace output in cocotb

### RTL Stress Testing
- **TODO [P1]:** Add DMA backpressure testbench (inject awready/wready stalls)
  - **Effort:** 3 days
  - **Priority:** P1 - DMA robustness
  - **Dependencies:** DMA backpressure handling implemented
  - **Validation:** DMA handles backpressure without data loss
  - **Deliverable:** RTL DMA stress test

- **TODO [P1]:** Add DRAM waitstate stress bench (vary arready/rvalid timing)
  - **Effort:** 3 days
  - **Priority:** P1 - Memory interface robustness
  - **Dependencies:** DRAM stub or controller
  - **Validation:** Core handles DRAM stalls correctly
  - **Deliverable:** RTL DRAM stress test

- **TODO [P1]:** Add AXI-Stream backpressure stress (sustained tready=0)
  - **Effort:** 2 days
  - **Priority:** P1 - Pixel stream robustness
  - **Dependencies:** Backpressure handling in voxel_axi_core
  - **Validation:** No pixel loss, no deadlock
  - **Deliverable:** Backpressure stress test
  - **Notes:** Test skid buffer overflow path

### Driver Kselftests
- **TODO [P1]:** Add kselftest for interrupt masking (toggle INT_MASK, count IRQs)
  - **Effort:** 2 days
  - **Priority:** P1 - IRQ validation
  - **Dependencies:** Driver IRQ handler working
  - **Validation:** INT_MASK correctly gates interrupts
  - **Deliverable:** Kselftest for interrupts

- **TODO [P1]:** Add kselftest for BAR0 mmap and access
  - **Effort:** 2 days
  - **Priority:** P1 - Memory mapping validation
  - **Dependencies:** Driver mmap implemented
  - **Validation:** BAR0 mmap succeeds, reads return correct values
  - **Deliverable:** Kselftest for mmap

- **TODO [P1]:** Add kselftest for camera/flags/selection writes via ioctls
  - **Effort:** 2 days
  - **Priority:** P1 - Control interface validation
  - **Dependencies:** Control ioctls implemented
  - **Validation:** CSR writes reflected in BAR0 reads
  - **Deliverable:** Kselftest for control ioctls

- **TODO [P1]:** Add negative kselftest (invalid ioctls, bad pointers, overflow)
  - **Effort:** 3 days
  - **Priority:** P1 - Security validation
  - **Dependencies:** Driver input validation complete
  - **Validation:** All negative cases return expected errors
  - **Deliverable:** Negative kselftest suite
- **Notes:** Include TOCTOU, race conditions
- **TODO [P1]:** Feed test failure metadata (failed suites, runtime, logs) into `scripts/ai_health_dashboard.py` so the automation dashboard highlights flaky suites when tests regress.
- **TODO [P1]:** Create a “test health” ledger inside this tracker that notes when automation reruns (frame regression, RTL tests, CI) touched the tracker so future contributors know which suites recently bit them.

### Visual and HDMI Testing
- **TODO [P1]:** Add HDMI timing validator bench (hsync/vsync/pixel counts)
  - **Effort:** 3 days
  - **Priority:** P1 - Video output correctness
  - **Dependencies:** HDMI stub or IP
  - **Validation:** HDMI timing meets spec
  - **Deliverable:** HDMI timing testbench

- **TODO [P1]:** Add HDMI CRC stability test (consistent CRC over N frames)
  - **Effort:** 2 days
  - **Priority:** P1 - Video determinism
  - **Dependencies:** HDMI CRC implemented
  - **Validation:** CRC stable across multiple frames
  - **Deliverable:** HDMI CRC stability test
  - **Notes:** Detect intermittent pixel corruption

- **TODO [P1]:** Add multi-frame visual regression (not just single frame)
  - **Effort:** 3 days
  - **Priority:** P1 - Animation/sequence testing
  - **Dependencies:** Frame capture infrastructure
  - **Validation:** Sequence of frames matches golden
  - **Deliverable:** Multi-frame regression test

### CI Pipeline Improvements
- **TODO [P1]:** Add CI job for cocotb smoke tests (nightly, non-blocking)
  - **Effort:** 2 days
  - **Priority:** P1 - Extended coverage
  - **Dependencies:** Cocotb tests stable
  - **Validation:** Cocotb runs nightly, results visible
  - **Deliverable:** CI job `test-cocotb-nightly`

- **TODO [P1]:** Add backend smoke matrix (SDL/X11/Wayland/dummy) in CI
  - **Effort:** 3 days
  - **Priority:** P1 - Backend regression prevention
  - **Dependencies:** Backend implementations
  - **Validation:** All backends tested in CI
  - **Deliverable:** CI matrix for backends
  - **Notes:** Best-effort, skip if deps missing

- **TODO [P1]:** Add CI note/skip for GL/Vulkan when drivers missing
  - **Effort:** 1 day
  - **Priority:** P1 - CI clarity
  - **Dependencies:** None
  - **Validation:** CI logs show backend availability
  - **Deliverable:** Backend detection in CI

- **TODO [P1]:** Add driver build test on multiple kernel versions (5.10, 5.15, 6.1)
  - **Effort:** 2 days
  - **Priority:** P1 - Kernel API compatibility
  - **Dependencies:** Multi-kernel CI setup
  - **Validation:** Driver builds on all target kernels
  - **Deliverable:** CI matrix for kernel versions

### QEMU/Emulation Testing
- **TODO [P1]:** Enhance QEMU PCI stub to emulate DMA and IRQ paths
  - **Effort:** 5 days
  - **Priority:** P1 - Pre-hardware driver testing
  - **Dependencies:** QEMU stub functional
  - **Validation:** Driver works in QEMU without hardware
  - **Deliverable:** Enhanced QEMU device model
  - **Notes:** Best-effort CI job

- **TODO [P1]:** Add QEMU test script for driver load/unload cycles
  - **Effort:** 2 days
  - **Priority:** P1 - Driver stability
  - **Dependencies:** QEMU stub enhanced
  - **Validation:** Driver survives load/unload without leaks
  - **Deliverable:** QEMU test script

### Test Documentation
- **TODO [P1]:** Document all test modes (headless, frame dump, deterministic)
  - **Effort:** 1 day
  - **Priority:** P1 - Test usability
  - **Dependencies:** Test modes implemented
  - **Validation:** Developers can run tests from docs
  - **Deliverable:** Section in testing_overview.md

- **TODO [P1]:** Create test troubleshooting guide (common failures, fixes)
  - **Effort:** 2 days
  - **Priority:** P1 - Developer experience
  - **Dependencies:** Test suite mature
  - **Validation:** Common test failures have documented solutions
  - **Deliverable:** docs/test_troubleshooting.md

---

## P2 - Medium Priority Extended Coverage (Nice-to-Have)

### Advanced RTL Testing
- **TODO [P2]:** Add formal verification for FSMs (raycaster, CSR arbiter)
  - **Effort:** 7 days
  - **Priority:** P2 - Formal correctness
  - **Dependencies:** Formal tools (SymbiYosys, JasperGold)
  - **Validation:** FSMs proven correct
  - **Deliverable:** Formal properties and proofs

- **TODO [P2]:** Add RTL coverage metrics (line, toggle, FSM)
  - **Effort:** 4 days
  - **Priority:** P2 - Test quality metrics
  - **Dependencies:** Coverage tools (Verilator, commercial)
  - **Validation:** Coverage reports generated
  - **Deliverable:** Coverage infrastructure

- **TODO [P2]:** Add constrained random testing for CSR writes
  - **Effort:** 5 days
  - **Priority:** P2 - Corner case discovery
  - **Dependencies:** UVM or cocotb randomization
  - **Validation:** Random tests find bugs
  - **Deliverable:** Constrained random testbench

- **TODO [P2]:** Add power-on reset (POR) sequence validation
  - **Effort:** 2 days
  - **Priority:** P2 - Boot robustness
  - **Dependencies:** Reset logic defined
  - **Validation:** All reset sequences tested
  - **Deliverable:** POR testbench

- **TODO [P2]:** Add clock domain crossing (CDC) validation
  - **Effort:** 3 days
  - **Priority:** P2 - Multi-clock safety
  - **Dependencies:** CDC checkers (Spyglass, Meridian)
  - **Validation:** No CDC violations
  - **Deliverable:** CDC check report
  - **Notes:** Currently single-clock, for future

### Driver Testing Advanced
- **TODO [P2]:** Add stress test for rapid ioctl calls (DoS prevention)
  - **Effort:** 2 days
  - **Priority:** P2 - Robustness
  - **Dependencies:** Rate limiting implemented
  - **Validation:** Rapid ioctls don't hang kernel
  - **Deliverable:** Ioctl stress test

- **TODO [P2]:** Add multi-process driver test (concurrent mmap/ioctl)
  - **Effort:** 3 days
  - **Priority:** P2 - Concurrency safety
  - **Dependencies:** Driver locking correct
  - **Validation:** Multi-process access safe
  - **Deliverable:** Multi-process test script

- **TODO [P2]:** Add driver load/unload cycle test (check for leaks)
  - **Effort:** 2 days
  - **Priority:** P2 - Resource leak detection
  - **Dependencies:** kmemleak enabled
  - **Validation:** No leaks after cycles
  - **Deliverable:** Load/unload test with leak check

- **TODO [P2]:** Add driver suspend/resume test (power management)
  - **Effort:** 3 days
  - **Priority:** P2 - PM validation
  - **Dependencies:** PM implemented in driver
  - **Validation:** Suspend/resume works
  - **Deliverable:** PM test script

### Fuzzing and Security Testing
- **TODO [P2]:** Add AFL/libFuzzer for userspace tools
  - **Effort:** 4 days
  - **Priority:** P2 - Security hardening
  - **Dependencies:** Fuzz infrastructure
  - **Validation:** 24hr fuzz finds no crashes
  - **Deliverable:** Fuzz harnesses

- **TODO [P2]:** Add syzkaller for driver fuzzing
  - **Effort:** 5 days
  - **Priority:** P2 - Kernel security
  - **Dependencies:** Syzkaller setup, syscall descriptions
  - **Validation:** Syzkaller finds no crashes
  - **Deliverable:** Syzkaller config and descriptions

- **TODO [P2]:** Add KASAN/UBSAN CI job for driver
  - **Effort:** 2 days
  - **Priority:** P2 - Memory safety
  - **Dependencies:** KASAN kernel in CI
  - **Validation:** No KASAN warnings
  - **Deliverable:** CI job `test-driver-kasan`
  - **Status:** Mentioned in security tracker

### Performance Testing
- **TODO [P2]:** Add frame rate benchmark suite (various camera angles/scenes)
  - **Effort:** 3 days
  - **Priority:** P2 - Performance baseline
  - **Dependencies:** None
  - **Validation:** Benchmark produces consistent results
  - **Deliverable:** Frame rate benchmark scripts

- **TODO [P2]:** Add memory bandwidth benchmark (DRAM read/write)
  - **Effort:** 2 days
  - **Priority:** P2 - Memory performance
  - **Dependencies:** DRAM controller
  - **Validation:** Bandwidth measured accurately
  - **Deliverable:** Bandwidth benchmark

- **TODO [P2]:** Add latency profiling (frame start to frame_done)
  - **Effort:** 2 days
  - **Priority:** P2 - Latency metrics
  - **Dependencies:** Timestamp infrastructure
  - **Validation:** Latency measured per frame
  - **Deliverable:** Latency profiler

- **TODO [P2]:** Track performance regression in CI (alert on >10% slowdown)
  - **Effort:** 3 days
  - **Priority:** P2 - Performance protection
  - **Dependencies:** Benchmark suite
  - **Validation:** CI alerts on regression
  - **Deliverable:** CI perf tracking
  - **Status:** Mentioned in performance tracker

### Integration and System Testing
- **TODO [P2]:** Add end-to-end test (boot, driver load, render, capture, verify)
  - **Effort:** 4 days
  - **Priority:** P2 - System validation
  - **Dependencies:** All components stable
  - **Validation:** Full stack test passes
  - **Deliverable:** E2E test script

- **TODO [P2]:** Add multi-board test (if multiple devices supported)
  - **Effort:** 3 days
  - **Priority:** P2 - Multi-device support
  - **Dependencies:** Multi-device driver support
  - **Validation:** Multiple devices work simultaneously
  - **Deliverable:** Multi-board test

- **TODO [P2]:** Add long-duration soak test (24hr+ rendering)
  - **Effort:** 2 days setup
  - **Priority:** P2 - Stability validation
  - **Dependencies:** Stable build
  - **Validation:** No crashes/leaks over 24hr
  - **Deliverable:** Soak test script

### CI Infrastructure Advanced
- **TODO [P2]:** Add CI job for cross-compilation (aarch64, riscv64)
  - **Effort:** 3 days
  - **Priority:** P2 - Platform support
  - **Dependencies:** Cross-compile toolchains
  - **Validation:** Builds succeed for all targets
  - **Deliverable:** CI cross-compile matrix
  - **Status:** Mentioned in build_tooling

- **TODO [P2]:** Add pre-commit hooks to run quick tests locally
  - **Effort:** 2 days
  - **Priority:** P2 - Developer velocity
  - **Dependencies:** .pre-commit-config.yaml
  - **Validation:** Pre-commit runs tests
  - **Deliverable:** Test hooks in pre-commit config

- **TODO [P2]:** Add test result dashboard (pass/fail rates, trends)
  - **Effort:** 5 days
  - **Priority:** P2 - Visibility
  - **Dependencies:** CI test results, dashboard framework
  - **Validation:** Dashboard shows test health
  - **Deliverable:** Test dashboard (web UI)

- **TODO [P2]:** Add automated bisect on test failures (find breaking commit)
  - **Effort:** 4 days
  - **Priority:** P2 - Debug efficiency
  - **Dependencies:** Bisect infrastructure
  - **Validation:** Bisect finds breaking commit
  - **Deliverable:** Automated bisect script

### Test Data and Fixtures
- **TODO [P2]:** Create test voxel scenes (checkerboard, gradients, stress patterns)
  - **Effort:** 2 days
  - **Priority:** P2 - Test coverage
  - **Dependencies:** Voxel data format
  - **Validation:** Test scenes exercise all features
  - **Deliverable:** Test scene library

- **TODO [P2]:** Add camera path recorder/playback for deterministic tests
  - **Effort:** 3 days
  - **Priority:** P2 - Reproducible tests
  - **Dependencies:** Input recording infrastructure
  - **Validation:** Playback produces identical output
  - **Deliverable:** Camera path recorder

---

## P3 - Low Priority Future Test Infrastructure (Future Work)

### Advanced Formal Verification
- **TODO [P3]:** Add formal equivalence checking (RTL vs. model)
  - **Effort:** 7 days
  - **Priority:** P3 - Correctness proof
  - **Dependencies:** Reference model, formal tools
  - **Validation:** RTL proven equivalent to model
  - **Deliverable:** Equivalence proof

- **TODO [P3]:** Add assertion-based verification (ABV) methodology
  - **Effort:** 10 days
  - **Priority:** P3 - Systematic verification
  - **Dependencies:** ABV training, tools
  - **Validation:** Comprehensive assertions
  - **Deliverable:** ABV suite

### Hardware-in-the-Loop (HIL) Testing
- **TODO [P3]:** Create HIL test framework (automated FPGA testing)
  - **Effort:** 10 days
  - **Priority:** P3 - Automated hardware validation
  - **Dependencies:** FPGA boards, automation infrastructure
  - **Validation:** HIL tests run nightly on hardware
  - **Deliverable:** HIL test framework

- **TODO [P3]:** Add HIL regression suite (run full test suite on FPGA)
  - **Effort:** 5 days
  - **Priority:** P3 - Hardware coverage
  - **Dependencies:** HIL framework
  - **Validation:** Regression passes on hardware
  - **Deliverable:** HIL regression suite

### Compliance and Certification Testing
- **TODO [P3]:** Add PCIe compliance test suite
  - **Effort:** 7 days
  - **Priority:** P3 - Standards compliance
  - **Dependencies:** PCIe compliance tools
  - **Validation:** Passes PCIe compliance
  - **Deliverable:** Compliance test reports

- **TODO [P3]:** Add AXI protocol compliance test suite
  - **Effort:** 5 days
  - **Priority:** P3 - IP compatibility
  - **Dependencies:** AXI compliance checker
  - **Validation:** Passes AXI compliance
  - **Deliverable:** AXI compliance reports

### Advanced CI Features
- **TODO [P3]:** Add automatic test generation from spec
  - **Effort:** 10 days
  - **Priority:** P3 - Automation
  - **Dependencies:** Spec parser, test generator
  - **Validation:** Generated tests cover spec
  - **Deliverable:** Test generator

- **TODO [P3]:** Add mutation testing (inject bugs, verify tests catch them)
  - **Effort:** 7 days
  - **Priority:** P3 - Test quality
  - **Dependencies:** Mutation framework
  - **Validation:** Tests catch >90% of mutations
  - **Deliverable:** Mutation testing infrastructure

- **TODO [P3]:** Add AI-assisted test generation
  - **Effort:** 15 days
  - **Priority:** P3 - Advanced automation
  - **Dependencies:** AI/ML infrastructure
  - **Validation:** AI generates valid tests
  - **Deliverable:** AI test generator

### Chaos Engineering
- **TODO [P3]:** Add chaos testing (random failures, delays, bit flips)
  - **Effort:** 7 days
  - **Priority:** P3 - Robustness
  - **Dependencies:** Chaos framework
  - **Validation:** System handles chaos gracefully
  - **Deliverable:** Chaos test suite

- **TODO [P3]:** Add fault injection (memory errors, I/O errors, network)
  - **Effort:** 5 days
  - **Priority:** P3 - Error handling
  - **Dependencies:** Fault injection framework
  - **Validation:** Error handling tested
  - **Deliverable:** Fault injection tests

### Test Automation and Reporting
- **TODO [P3]:** Add test result analytics (failure patterns, flaky tests)
  - **Effort:** 5 days
  - **Priority:** P3 - Test maintenance
  - **Dependencies:** Test history database
  - **Validation:** Analytics identify flaky tests
  - **Deliverable:** Analytics dashboard

- **TODO [P3]:** Add automated test maintenance (update goldens, fix bitrot)
  - **Effort:** 7 days
  - **Priority:** P3 - Test sustainability
  - **Dependencies:** AI/automation
  - **Validation:** Tests self-maintain
  - **Deliverable:** Auto-maintenance framework

### Performance and Stress Testing Advanced
- **TODO [P3]:** Add power consumption testing (measure watts during rendering)
  - **Effort:** 5 days
  - **Priority:** P3 - Power optimization
  - **Dependencies:** Power measurement hardware
  - **Validation:** Power measured accurately
  - **Deliverable:** Power test suite

- **TODO [P3]:** Add thermal testing (measure temperature under load)
  - **Effort:** 4 days
  - **Priority:** P3 - Thermal validation
  - **Dependencies:** Thermal sensors/cameras
  - **Validation:** Thermal limits not exceeded
  - **Deliverable:** Thermal test suite

- **TODO [P3]:** Add EMI/EMC pre-compliance testing
  - **Effort:** 7 days
  - **Priority:** P3 - Regulatory prep
  - **Dependencies:** EMI measurement equipment
  - **Validation:** Pre-compliance pass
  - **Deliverable:** EMI test reports

---

## Test Coverage Matrix

| Area | Unit Tests | Integration Tests | System Tests | Stress Tests | Coverage Target |
|------|-----------|-------------------|--------------|--------------|-----------------|
| **RTL Core** | ✅ CSR bench | 🟡 Cocotb basic | ❌ E2E | ❌ Backpressure | 80% |
| **AXI Interfaces** | 🟡 Basic SVAs | ❌ Protocol checker | ❌ Multi-master | ❌ Stress | 70% |
| **DMA** | ❌ Loopback | ❌ Backpressure | ❌ Integration | ❌ Stress | 60% |
| **HDMI** | 🟡 CRC golden | ❌ Timing | ❌ Integration | ❌ Long-run | 50% |
| **Driver (Linux)** | 🟡 Basic ioctls | ❌ Kselftests | 🟡 Smoke | ❌ Stress | 70% |
| **Driver (FreeBSD)** | ❌ Unit | ❌ Kselftests | ❌ Smoke | ❌ Stress | 30% |
| **Libhydra** | ❌ API tests | ❌ Integration | 🟡 Tools smoke | ❌ Stress | 40% |
| **Viewer** | ❌ Unit | ❌ Backend matrix | 🟡 Frame regression | ❌ Long-run | 50% |

**Legend:**
- ✅ Complete and running in CI
- 🟡 Partial or manual testing only
- ❌ Not yet implemented

**Current Overall Coverage:** ~40%
**Target for 0.0.7:** ~70% (P0+P1 items)
**Target for 1.0:** ~90% (P0+P1+P2 items)

---

## Test Pyramid Structure

```
         /\
        /  \  E2E Tests (P2)
       /____\
      /      \  Integration Tests (P1)
     /________\
    /          \  Unit Tests (P0/P1)
   /____________\
```

**Current Distribution:**
- Unit Tests: ~60% (good)
- Integration Tests: ~30% (needs improvement)
- E2E Tests: ~10% (needs expansion)

**Target Distribution:**
- Unit Tests: 70%
- Integration Tests: 20%
- E2E Tests: 10%

---

## Cross-References

**Related Work:**
- See `todo_build_tooling.md` for CI infrastructure and build automation
- See `todo_hardware_validation.md` for FPGA bring-up testing
- See `todo_security.md` for security testing (fuzzing, SAST)
- See `todo_performance.md` for performance benchmarking
- See `todo_mesa_drivers.md` for cross-platform driver testing

**Blocking Items:**
- P0 frame regression update blocks visual changes
- P0 RTL testbenches block hardware confidence
- P1 kselftests block driver quality gates

---

## Notes

- **Testing is critical for 0.0.7 quality** - P0 items are release gates
- **Coverage targets are guidelines** - quality over quantity
- **CI reliability is paramount** - flaky tests are technical debt
- **Test maintenance is ongoing** - budget 20% time for test upkeep

**Testing Philosophy:**
1. **Write tests first** (TDD where feasible)
2. **Test at the right level** (unit vs. integration vs. E2E)
3. **Keep tests fast** (< 10 min for unit tests)
4. **Make tests deterministic** (no flaky tests in CI)
5. **Test failures must be actionable** (clear error messages)

**Testing Philosophy:**
1. **Write tests first** (TDD where feasible)
2. **Test at the right level** (unit vs. integration vs. E2E)
3. **Keep tests fast** (< 10 min for unit tests)
4. **Make tests deterministic** (no flaky tests in CI)
5. **Test failures must be actionable** (clear error messages)

**Automation Feedback:**
- **TODO [P2]:** Record test failure metadata in `out/test_health.json` and have `scripts/ai_health_dashboard.py` highlight regressing suites.
- **TODO [P2]:** Maintain a `docs/todo/test_triage_log.md` that lists automation-detected flakes and the TODOs spawned to fix them, pointing AI agents at the right follow ups.
- **TODO [P3]:** Note when suites are “quick fix” vs “large expansion” inside this tracker so future contributors can document work scope without assumptions.

**Next Actions:**
1. Refresh golden_frame.ppm (P0)
2. Add DMA kselftest (P0)
3. Enable RTL lint in CI (P0)
4. Add userspace smoke test (P0)

---

**Document Version:** 2.0 (Expanded)
**Created:** 2025-11-25
**Status:** Active tracker for testing and CI infrastructure
