# Hydra Sector Work Overview (Automation-Ready)

**Last Updated:** 2025-11-25
**Purpose:** Organize work into logical sectors for automated tracking, prioritization, and resource allocation.

---

## Sector System Architecture

This document defines **work sectors** - high-level organizational units that group related trackers and work streams. Sectors enable:
- **Automated prioritization** - Scripts can aggregate P0/P1 counts per sector
- **Resource allocation** - Assign teams/owners to sectors
- **Dependency tracking** - Sectors have inter-sector dependencies
- **Progress monitoring** - Track completion % per sector
- **Sprint planning** - Allocate sprints to specific sectors

**Machine-Readable Format:** Each sector includes YAML-like metadata for automation.

---

## Sector Definitions

### SECTOR-01: RTL Core & Ray Engine
**ID:** `RTL_CORE`
**Owner:** RTL Team
**Priority:** P0 (Critical for 0.0.7)
**Status:** Active (45% complete - P0 work done, P1 in progress)

**Scope:**
- Ray marching pipeline (`voxel_raycaster_core_pipelined.sv`)
- Voxel memory and world generation
- Frame generation and pixel output
- Diagnostic modes and selection logic

**Trackers:**
- `todo_ray_engine.md` (P1: 8, P2: 12, P3: 19)
- `todo_ray_mechanics.md` (P1: 3, P2: 6, P3: 5)
- `todo_depth_buffer.md` (P2: 13, P3: 4)
- `todo_depth_reemissure.md` (mixed)

**Dependencies:** → SECTOR-03 (AXI/DRAM), SECTOR-06 (Testing)

**Automation Hooks:**
- `make test_rtl_ray` - Run ray engine unit tests
- `scripts/ray_coverage.sh` (TBD) - Coverage analysis

---

### SECTOR-02: AXI/PCIe/DMA Infrastructure
**ID:** `AXI_PCIE_DMA`
**Owner:** Integration Team
**Priority:** P0 (Critical - blocks FPGA deployment)
**Status:** Active (60% complete - P0 SVAs done, P1 burst work pending)

**Scope:**
- AXI-Lite CSR interface
- AXI Full for DRAM/DMA
- PCIe BAR mapping and MSI/MSI-X
- DMA engine and descriptors

**Trackers:**
- `todo_dram_axi.md` (P0: 3 DONE, P1: 11, P2: 35, P3: 8)
- `todo_dma_pcie.md` (P0: 9 DONE, P1: 11, P2: 29, P3: 6)
- `todo_axi_lite_coverage.md` (P0: 1, P1: 2, P2: 2)
- `todo_axi_mem.md` (P1: 3, P2: 4, P3: 1)
- `todo_dma_hang_policy.md`, `todo_dma_hotplug.md`, `todo_dma_structured_logging.md`, `todo_dma_trace_artifacts.md`

**Dependencies:** → SECTOR-01 (RTL Core), → SECTOR-04 (IP Integration), → SECTOR-07 (Drivers)

**Critical Path Items:**
- P1: AXI burst support
- P1: DMA kselftests
- P1: IOMMU/VT-d support

**Automation Hooks:**
- `make test_axi` - AXI protocol tests
- `scripts/dma_health_check.sh` (TBD) - DMA validation

---

### SECTOR-03: Video Output & Display
**ID:** `VIDEO_HDMI`
**Owner:** Video Team
**Priority:** P1 (High - needed for hardware bring-up)
**Status:** Active (35% complete - P0 docs done, P1 validation pending)

**Scope:**
- HDMI/AXI-Stream video output
- Frame CRC generation and validation
- Display timing and blanking
- Video format conversion

**Trackers:**
- `todo_hdmi.md` (P0: 2 DONE, P1: 8, P2: 24, P3: 6)
- `todo_hdmi_display.md` (P0: 2, P1: 2, P2: 2, P3: 2)
- `todo_hdmi_stream.md` (P1: 2, P2: 2, P3: 2)

**Dependencies:** → SECTOR-01 (pixel data), → SECTOR-04 (LiteVideo IP)

**Automation Hooks:**
- `make test_hdmi_crc` - CRC validation tests
- `scripts/hdmi_bench.sh` (TBD) - HDMI protocol tests

---

### SECTOR-04: IP Integration (LitePCIe/LiteDRAM/LiteVideo)
**ID:** `IP_INTEGRATION`
**Owner:** FPGA Team
**Priority:** P0 (Critical - blocks FPGA builds)
**Status:** Planning (10% complete - stubs in place, IP integration pending)

**Scope:**
- LitePCIe endpoint integration
- LiteDRAM controller hookup
- LiteVideo HDMI encoder
- Clock domain crossing
- IP configuration and parameterization

**Trackers:**
- `todo_ip_integration.md` (P0: 11, P1: 21, P2: 17, P3: 5)

**Dependencies:** → SECTOR-02 (AXI), → SECTOR-03 (Video), → SECTOR-05 (FPGA)

**Critical Path Items:**
- P0: LitePCIe BAR0/BAR1 mapping
- P0: LiteDRAM integration
- P0: Clock/reset domain documentation

**Automation Hooks:**
- `make ip-fetch` - Fetch third-party IP
- `scripts/fetch_ip.sh` - IP dependency management

---

### SECTOR-05: FPGA Synthesis & Board Design
**ID:** `FPGA_BOARD`
**Owner:** Hardware Team
**Priority:** P1 (High - preparation for silicon)
**Status:** Planning (5% complete - board selection pending)

**Scope:**
- FPGA board selection and procurement
- Synthesis flows and constraints
- Pin mapping and I/O planning
- Timing closure and optimization
- Board-level schematic and layout

**Trackers:**
- `todo_board_fpga.md` (P0: 6, P1: 10, P2: 7, P3: 3)
- `todo_board_hardware_design.md` (P0: 12, P1: 19, P2: 19, P3: 13)
- `todo_board_level.md` (P0: 2, P1: 3, P2: 3, P3: 4)
- `todo_fpga.md` (P0: 2, P1: 3, P2: 3)
- `todo_synthesis.md` (P0: 2, P1: 5, P2: 9, P3: 4)
- `todo_xschem.md` (P0: 1, P1: 7, P2: 13, P3: 14)

**Dependencies:** → SECTOR-04 (IP), → SECTOR-08 (Validation)

**Critical Path Items:**
- P0: Resource estimates
- P0: Board selection
- P0: Synthesis setup

**Automation Hooks:**
- `scripts/board_simulate.sh` - Board-level simulation
- `make synth` (TBD) - Synthesis flow

---

### SECTOR-06: Simulation & Testing Infrastructure
**ID:** `SIM_TEST`
**Owner:** Verification Team
**Priority:** P0 (Critical - gates releases)
**Status:** Active (50% complete - frame regression works, coverage gaps remain)

**Scope:**
- Verilator simulation harness
- Cocotb test framework
- RTL unit tests (iverilog/vvp)
- Frame regression testing
- Coverage collection and analysis

**Trackers:**
- `todo_testing_ci.md` (P0: 11, P1: 22, P2: 25, P3: 16)
- `todo_simulation_viewer.md` (P1: 10, P2: 22, P3: 14)
- `todo_debugging_tools.md` (P1: 5, P2: 16, P3: 22)

**Dependencies:** → SECTOR-01 (RTL), → SECTOR-10 (Build)

**Critical Path Items:**
- P0: 1000-frame regression
- P0: Cocotb suite expansion
- P1: Coverage reporting

**Automation Hooks:**
- `make test` - Run all tests
- `make test_frame` - Frame regression
- `scripts/todo_sweep.py` - TODO metrics

---

### SECTOR-07: Drivers & Userspace SDK
**ID:** `DRIVERS_SDK`
**Owner:** Driver Team
**Priority:** P1 (High - needed for software integration)
**Status:** Active (40% complete - Linux basic driver works, features pending)

**Scope:**
- Linux PCIe driver (kernel module)
- FreeBSD/Windows/macOS drivers
- libhydra userspace library
- Driver testing tools (kselftests)
- UAPI stability and versioning

**Trackers:**
- `todo_mesa_drivers.md` (P1: 8, P2: 18, P3: 12)
- `todo_master.md` (Drivers section - 23 TODOs)

**Dependencies:** → SECTOR-02 (DMA/PCIe), → SECTOR-09 (Security)

**Critical Path Items:**
- P1: DMA IOCTLs with kselftests
- P1: FreeBSD driver parity
- P1: libhydra API hardening

**Automation Hooks:**
- `make -C drivers/linux` - Build Linux driver
- `./scripts/setup_sdk.sh` - Build SDK tools
- `make kselftest` (TBD) - Driver tests

---

### SECTOR-08: Hardware Validation & Bring-Up
**ID:** `HW_VALIDATION`
**Owner:** Hardware Validation Team
**Priority:** P0 (Critical - pre-silicon validation)
**Status:** Active (30% complete - sim validation ongoing)

**Scope:**
- Pre-silicon validation (Verilator/cocotb)
- FPGA bring-up procedures
- Hardware test plans and checklists
- Bench setup and instrumentation
- Golden vectors and reference models

**Trackers:**
- `todo_hardware_validation.md` (P0: 10, P1: 15, P2: 14, P3: 7)

**Dependencies:** → SECTOR-05 (FPGA), → SECTOR-06 (Testing)

**Critical Path Items:**
- P0: 1000-frame regression
- P0: AXI-Lite SVAs
- P0: Cocotb suite completion

**Automation Hooks:**
- `sim/tests/run_rtl_tests.sh` - RTL benches
- `make test_cocotb` (TBD) - Cocotb tests

---

### SECTOR-09: Security & Robustness
**ID:** `SECURITY`
**Owner:** Security Team
**Priority:** P1 (High - must have for production)
**Status:** Planning (15% complete - basic checks in place)

**Scope:**
- Input validation (IOCTL, CSR writes)
- Bounds checking and overflow guards
- Privilege separation
- Fuzzing and stress testing
- Security documentation

**Trackers:**
- `todo_security.md` (P1: 8, P2: 15, P3: 8)

**Dependencies:** → SECTOR-07 (Drivers), → SECTOR-02 (DMA)

**Critical Path Items:**
- P1: IOCTL input validation
- P1: DMA bounds checking
- P1: Fuzzing infrastructure

**Automation Hooks:**
- `scripts/security_scan.sh` (TBD) - Security analysis
- `make fuzz` (TBD) - Fuzzing harness

---

### SECTOR-10: Build System & CI/CD
**ID:** `BUILD_CI`
**Owner:** DevOps Team
**Priority:** P0 (Critical - enables development)
**Status:** Active (70% complete - basics work, gaps in coverage)

**Scope:**
- Makefile and CMake build systems
- CI pipeline (GitHub Actions)
- Pre-commit hooks and formatting
- Dependency management
- Build reproducibility

**Trackers:**
- `todo_build_tooling.md` (P3: 10)
- `todo_build_devtools.md` (P2: 11, P3: 3)
- `todo_build_ci.md` (P0 items, see session continuation)

**Dependencies:** → SECTOR-06 (Testing)

**Critical Path Items:**
- P0: CI reliability
- P0: Multi-distro matrix
- P1: Formatting/linting

**Automation Hooks:**
- `./scripts/hydra_dev_loop.sh` - Development loop
- `scripts/automation_watchdog.sh` - Automation bundle

---

### SECTOR-11: Documentation & Examples
**ID:** `DOCS_EXAMPLES`
**Owner:** Documentation Team
**Priority:** P1 (High - user onboarding)
**Status:** Active (55% complete - specs done, tutorials pending)

**Scope:**
- Technical specifications
- User guides and tutorials
- API documentation
- Example code and demos
- Release notes

**Trackers:**
- `todo_documentation.md` (P0: 6, P1: 10, P2: 12, P3: 6)
- `todo_examples_demos.md` (P1: 3, P2: 11, P3: 8)
- `todo_site_wiki.md` (P1: 3, P2: 4, P3: 5)

**Dependencies:** → All sectors (documentation follows implementation)

**Critical Path Items:**
- P0: Spec updates for 0.0.7
- P1: Driver integration guide
- P1: Example applications

**Automation Hooks:**
- `scripts/docs_lint.py` - Documentation linter
- `make docs` (TBD) - Generate documentation

---

### SECTOR-12: Rendering & Visual Quality
**ID:** `RENDERING`
**Owner:** Graphics Team
**Priority:** P2 (Medium - quality improvements)
**Status:** Active (40% complete - Phase 1 done)

**Scope:**
- Lighting models and shading
- Camera controls and effects
- Ray mechanics and optimizations
- Depth buffer and reemissure
- Visual presets and themes

**Trackers:**
- `todo_rendering.md` (P1: 2, P2: 3)
- `todo_rendering_camera.md` (P1: 2, P2: 4, P3: 3)
- `todo_rendering_debug.md` (P1: 2, P2: 5, P3: 4)
- `todo_rendering_effects.md` (P1: 3, P2: 6, P3: 4)
- `todo_rendering_pipeline.md` (P1: 1, P2: 6, P3: 2)
- `todo_rendering_presets.md` (P1: 2, P2: 5, P3: 2)
- `todo_rendering_trace.md` (items)
- `todo_reemissure.md` (P2: 11, P3: 4)

**Dependencies:** → SECTOR-01 (RTL Core), → SECTOR-13 (Viewer)

**Automation Hooks:**
- `make test_frame` - Visual regression

---

### SECTOR-13: Interactive Viewer & Platform Backends
**ID:** `VIEWER_PLATFORM`
**Owner:** Platform Team
**Priority:** P1 (High - user interface)
**Status:** Active (65% complete - SDL works, backends need testing)

**Scope:**
- SDL2 viewer application
- Platform backends (GL/Vulkan/Wayland/X11/headless)
- HUD and on-screen displays
- Input handling and controls
- Configuration and persistence

**Trackers:**
- `todo_platform_backends.md` (P0: 9 DONE, P1: 9, P2: 43, P3: 5)
- `todo_master.md` (Sim/Viewer section - 25 TODOs)

**Dependencies:** → SECTOR-01 (pixel data), → SECTOR-14 (Multi-platform)

**Critical Path Items:**
- P1: Backend unit tests
- P1: Headless mode for CI
- P1: Platform matrix documentation

**Automation Hooks:**
- `scripts/check_backends.sh` - Backend availability
- `HYDRA_BACKEND=headless ./sim_voxel` - Headless mode

---

### SECTOR-14: Multi-Platform Support
**ID:** `MULTIPLATFORM`
**Owner:** Platform Team
**Priority:** P2 (Medium - broader adoption)
**Status:** Active (30% complete - Linux works, others partial)

**Scope:**
- Cross-platform build systems (Linux/macOS/Windows)
- Platform-specific drivers
- Package creation (deb/rpm/pkg/MSI)
- Platform-specific documentation
- CI matrix for multiple platforms

**Trackers:**
- `todo_multiplatform_builds.md` (P0: 2, P1: 3, P2: 2)

**Dependencies:** → SECTOR-07 (Drivers), → SECTOR-10 (Build)

**Automation Hooks:**
- `cmake --preset linux-default` - Linux build
- `cmake --preset windows-msvc` - Windows build

---

### SECTOR-15: Performance & Optimization
**ID:** `PERFORMANCE`
**Owner:** Performance Team
**Priority:** P3 (Low - post-functionality)
**Status:** Planning (10% complete - instrumentation in place)

**Scope:**
- RTL timing optimization
- Ray marching performance
- Build time reduction
- Runtime profiling
- Benchmarking infrastructure

**Trackers:**
- `todo_performance.md` (P2: 25, P3: 21)
- `todo_system_fps.md` (P1: 3, P2: 6, P3: 2)

**Dependencies:** → SECTOR-01 (RTL), → SECTOR-06 (Testing)

**Automation Hooks:**
- `make bench` (TBD) - Performance benchmarks

---

### SECTOR-16: Data Formats & Interoperability
**ID:** `DATA_FORMATS`
**Owner:** Tools Team
**Priority:** P3 (Low - future extensibility)
**Status:** Planning (5% complete)

**Scope:**
- Voxel data import/export
- Frame format specifications
- Trace data formats
- Logging schemas
- API compatibility

**Trackers:**
- `todo_data_formats.md` (P2: 11, P3: 19)

**Dependencies:** → SECTOR-07 (SDK)

---

### SECTOR-17: Community & Deployment
**ID:** `COMMUNITY`
**Owner:** Community Team
**Priority:** P3 (Low - post-release)
**Status:** Planning (5% complete)

**Scope:**
- Contributor onboarding
- Issue templates and triage
- Release workflows
- Package distribution
- User support channels

**Trackers:**
- `todo_community_contributors.md` (P2: 13, P3: 22)
- `todo_deployment_operations.md` (P1: 2, P2: 11, P3: 24)

**Dependencies:** → SECTOR-11 (Documentation)

---

### SECTOR-18: Research & Experimental
**ID:** `RESEARCH`
**Owner:** Research Team
**Priority:** P3 (Low - exploratory)
**Status:** Ongoing (continuous research)

**Scope:**
- Novel rendering techniques
- Advanced ray marching algorithms
- Experimental features
- Proof-of-concept implementations
- Academic collaborations

**Trackers:**
- `todo_research_experimental.md` (P3: 41)

**Dependencies:** None (independent research)

---

### SECTOR-19: Project Structure & Meta
**ID:** `PROJECT_META`
**Owner:** Project Lead
**Priority:** P2 (Medium - organizational health)
**Status:** Active (80% complete - TODO system in place)

**Scope:**
- Project organization and structure
- TODO tracking system maintenance
- Dependency mapping
- Rebalancing policies
- AI development workflows

**Trackers:**
- `todo_project_structure.md` (P1: 4, P2: 9, P3: 4)
- `todo_ai_development.md` (P0: 1, P1: 3, P2: 9, P3: 2)
- `todo_dependency_map.md`
- `todo_rebalance_policy.md`
- `todo_status_overview.md`

**Automation Hooks:**
- `scripts/todo_sweep.py` - TODO metrics
- `scripts/check_todo_unique.py` - Uniqueness check
- `scripts/automation_watchdog.sh` - Full suite

---

## Sector Metrics (Auto-Generated)

Run `scripts/sector_metrics.sh` to generate current metrics:

```
SECTOR-01 (RTL_CORE):        P0: 0  P1: 8  P2: 31  P3: 28  Unknown: 0
SECTOR-02 (AXI_PCIE_DMA):    P0: 0  P1: 14 P2: 68  P3: 14  Unknown: 0
SECTOR-03 (VIDEO_HDMI):      P0: 0  P1: 8  P2: 28  P3: 8   Unknown: 0
...
```

---

## Sprint Allocation Guide

**Sprint 1 (Weeks 1-2):** Focus on SECTOR-02, SECTOR-04, SECTOR-06 P0 items
**Sprint 2 (Weeks 3-4):** SECTOR-01, SECTOR-08, SECTOR-10 P1 items
**Sprint 3 (Weeks 5-6):** SECTOR-03, SECTOR-07, SECTOR-11 P1 items
**Sprint 4 (Weeks 7-8):** Polish, P2 items across sectors, release prep

---

## Automation Integration

### Sector Analysis Script

```bash
# Generate sector metrics
scripts/sector_metrics.sh

# Get critical path for sector
scripts/sector_critical_path.sh SECTOR-02

# Check sector dependencies
scripts/sector_deps.sh --check

# Allocate sprint to sector
scripts/sector_sprint.sh --sector SECTOR-06 --sprint 1
```

### CI/CD Integration

Sectors are tracked in CI pipeline. Each PR is tagged with affected sectors:
- Auto-label based on changed files
- Run sector-specific test suites
- Track sector completion % over time

### Emerging Sectors

- **SECTOR-20 (CLUSTERING):** Captures multi-board and mezzanine scaling work; link the cluster deployment playbook and automation artifacts to this overview so each clustered board build draws automation attention.
- **SECTOR-21 (AI_AUTOMATION):** Tracks metadata/dashboards/rebalance scripts; the sector metrics above should include its TODO counts, so contributors see when the automation stack needs new tasks or maintenance.

---

**Next Review:** After Sprint 1 (2 weeks)
**Maintainer:** Project lead
**Automation:** Integrated with `scripts/automation_watchdog.sh`
