# Hydra TODO System - Master Index

**Complete reference of all TODO trackers in the Hydra project**

**Last Updated:** 2025-11-25 (Extended Session)
**Total Trackers:** 40 files (8 new critical trackers added)
**Total Items:** ~1,350+ TODO items
**Total Documentation:** ~15,000+ lines

---

## Quick Navigation

- **Start Here:** [`TODO_README.md`](./TODO_README.md) - Quick start guide
- **Strategic Planning:** [`todo_prioritization.md`](./todo_prioritization.md) - 8-week sprint plan
- **This Session:** [`todo_system_summary_2025_11_25.md`](./todo_system_summary_2025_11_25.md) - Summary of today's work

---

## Complete Tracker List (Alphabetical)

### Meta Documents (6 files)

| File | Purpose | Lines |
|------|---------|-------|
| `TODO_README.md` | Quick start, navigation, system overview | ~320 |
| `TODO_MASTER_INDEX.md` | This file - complete tracker reference | ~300 |
| `todo_prioritization.md` | Strategic roadmap, 8-week sprint plan | ~765 |
| `todo_system_summary_2025_11_25.md` | Session summary, metrics, recommendations | ~350 |
| Additional meta docs may exist | | |

### Domain-Specific Trackers (25+ files)

#### RTL / Hardware (Core) - 16 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 1 | `todo_axi_lite_coverage.md` | ~8 | P1/P2 | AXI-Lite protocol assertions |
| 2 | `todo_board_level.md` | ~6 | P1/P2 | Board-level integration |
| 3 | `todo_ddr_sdram.md` | ~12 | P2 | DDR SDRAM integration |
| 4 | `todo_dma_pcie.md` | ~47 | P0/P1 | **DMA/PCIe validation** |
| 5 | `todo_dma_structured_logging.md` | ~7 | P1/P2 | Structured DMA logs + tooling |
| 6 | `todo_dma_trace_artifacts.md` | ~7 | P1/P2 | DMA trace capture/reporting |
| 7 | `todo_dma_hotplug.md` | ~8 | P1 | PCIe hotplug cleanup & recovery |
| 8 | `todo_dma_hang_policy.md` | ~6 | P1 | DMA hang handling + watchdog |
| 9 | `todo_dram_axi.md` | ~58 | P0/P1 | **DRAM/AXI, SVAs** |
| 10 | `todo_axi_mem.md` | ~4 | P1/P2 | AXI memory instrumentation |
| 11 | `todo_dram_stub.md` | ~5 | P2 | DRAM stub enhancements |
| 12 | `todo_fpga.md` | ~8 | P1/P2 | FPGA synthesis |
| 13 | `todo_hdmi_display.md` | ~12 | P0/P1 | HDMI timing/CRC |
| 14 | `todo_hdmi_stream.md` | ~8 | P1/P2 | HDMI stream/backpressure |
| 15 | `todo_hdmi.md` | ~2 | P2 | HDMI overview (index) |
| 16 | `todo_synthesis.md` | ~7 | P2 | Synthesis optimization |

**Total:** ~216 items

#### Rendering & Visual Quality - 9 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 10 | `todo_depth_buffer.md` | ~12 | P2 | Depth range, fog diagnostics |
| 11 | `todo_reemissure.md` | ~12 | P2 | Emissive sideband coverage |
| 12 | `todo_ray_engine.md` | ~43 | P2/P3 | Ray marching optimizations |
| 13 | `todo_rendering.md` | ~5 | P1/P2 | Rendering overview (index) |
| 14 | `todo_rendering_presets.md` | ~9 | P1/P2 | Presets & LUTs |
| 15 | `todo_rendering_effects.md` | ~10 | P1/P2 | Fog/AO/Bloom effects |
| 16 | `todo_rendering_camera.md` | ~8 | P1/P2 | Camera & capture tools |
| 17 | `todo_rendering_debug.md` | ~8 | P2/P3 | HUD/overlay helpers |
| 18 | `todo_rendering_pipeline.md` | ~27 | P2/P3 | Pipeline/shader profiling |
| 19 | `todo_rendering_trace.md` | ~4 | P3 | Ray tracing visualization |

**Total:** ~233 items

#### Platform, Drivers & Testing - 3 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 15 | `todo_multiplatform_builds.md` | ~8 | P2 | Cross-platform builds |
| 16 | `todo_platform_backends.md` | ~68 | P1 | **SDL/GL/Vulkan backends** |
| 17 | `todo_testing_ci.md` | ~80+ | P0/P1 | **Testing & CI infrastructure** |

**Total:** ~156 items

#### Simulation & Viewer - 2 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 18 | `todo_simulation_viewer.md` | ~44 | P1/P2/P3 | **Viewer features, world editing** |
| 19 | `todo_xschem.md` | ~5 | P3 | Xschem schematic integration |

**Total:** ~49 items

#### Infrastructure & Operations - 7 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 20 | `todo_build_ci.md` | ~12 | P0/P1 | CI reliability |
| 21 | `todo_build_devtools.md` | ~9 | P1/P2 | Dev tools & build system refactor |
| 22 | `todo_build_tooling.md` | ~10 | P3 | Build tools overview (advanced items) |
| 23 | `todo_deployment_operations.md` | 41 | P1/P2/P3 | **Packaging, installation** |
| 24 | `todo_documentation.md` | 34 | P0/P1 | **Spec updates, guides** ✅ NEW |
| 25 | `todo_hardware_validation.md` | 46 | P0/P1 | **Pre-silicon, FPGA bring-up** ✅ NEW |
| 26 | `todo_performance.md` | 47 | P2/P3 | Performance optimization ✅ NEW |
| 27 | `todo_security.md` | 32 | P1/P2 | **Input validation, hardening** ✅ NEW |
| 28 | `todo_site_wiki.md` | ~6 | P3 | Project website |

**Total:** ~255 items

#### Specialized Topics - 8 trackers

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 27 | `todo_board_fpga.md` | 26 | P0/P1 | **Board selection, constraints** ✅ NEW |
| 28 | `todo_community_contributors.md` | 31 | P2/P3 | Community, governance |
| 29 | `todo_data_formats.md` | 30 | P2/P3 | Voxel formats, import/export |
| 30 | `todo_debugging_tools.md` | 38 | P1/P2/P3 | **Debug tools, profilers** |
| 31 | `todo_examples_demos.md` | 21 | P1/P2/P3 | **Examples, benchmarks** |
| 32 | `todo_ip_integration.md` | 50 | P0 (hardware) | **LiteX IP (separate track)** ✅ NEW |
| 33 | `todo_mesa_drivers.md` | 40 | P1/P2 | **Mesa, Windows/macOS drivers** ✅ NEW |
| 34 | `todo_research_experimental.md` | 44 | P3 | Research, experimental features |

**Total:** ~280 items

#### Master Tracker - 1 file

| # | File | Items | Priority | Focus Area |
|---|------|-------|----------|------------|
| 35 | `todo_master.md` | ~180 | Mixed | **Cross-cutting items, main tracker** |

**Total:** ~180 items

---

## Priority Distribution Summary

### P0 (Critical - Blocks 0.0.7 Release or Hardware)
- **Count:** ~55 items
- **Effort:** ~90-130 engineer-days
- **Key Areas:**
  - **Software Release (0.0.7):** RTL assertions, testing, docs, build (25 items, ~30 days)
  - **Hardware Track (Parallel):** IP integration, board selection, pre-silicon validation (30 items, ~60-100 days)
- **Software Trackers:** `todo_dma_pcie`, `todo_dma_hotplug`, `todo_dma_hang_policy`, `todo_dma_structured_logging`, `todo_dma_trace_artifacts`, `todo_dram_axi`, `todo_hdmi`, `todo_testing_ci`, `todo_documentation`, `todo_build_tooling`
- **Hardware Trackers:** `todo_ip_integration`, `todo_board_fpga`, `todo_hardware_validation`

### P1 (High Priority - Strongly Recommended for 0.0.7)
- **Count:** ~110 items
- **Effort:** ~130-180 engineer-days
- **Key Areas:**
  - Visual quality (Phase 2 fog+AO, reemissure wiring)
  - Driver hardening (FreeBSD, security, input validation)
  - CI improvements (formatting, linting, coverage)
  - FPGA bring-up (synthesis, debugging, testing)
  - Documentation (guides, architecture diagrams)
  - Debugging tools (waveform dump, profilers)
- **Trackers:** `todo_rendering`, `todo_mesa_drivers`, `todo_testing_ci`, `todo_security`, `todo_board_fpga`, `todo_debugging_tools`, `todo_hardware_validation`, `todo_documentation`, `todo_build_tooling`, `todo_dma_structured_logging`, `todo_dma_trace_artifacts`, `todo_dma_hotplug`, `todo_dma_hang_policy`

### P2 (Medium Priority - Nice-to-Have)
- **Count:** ~700 items
- **Effort:** ~800-1200 engineer-days
- **Key Areas:**
  - Performance optimization (Verilator, RTL, memory bandwidth)
  - Platform expansion (Windows/Mesa drivers, multiple boards)
  - Documentation expansion (tutorials, API docs, compliance)
  - Advanced IP features (scatter-gather DMA, multi-resolution HDMI)
  - Packaging and deployment (packages, containers, monitoring)
  - Data formats and import/export
  - Extended testing (fuzzing, stress tests, compliance)
- **All Trackers:** Most have P2 items

### P3 (Low Priority - Future Work)
- **Count:** ~485 items
- **Effort:** ~700-1200 engineer-days
- **Key Areas:**
  - Advanced rendering (hierarchical ray marching, PBR, neural rendering)
  - macOS drivers and advanced Windows features (WDDM)
  - ASIC preparation and multi-platform hardware
  - Research and experimental features
  - Community governance and events
  - Advanced security (CFI, secure boot, certification)
- **Trackers:** `todo_research_experimental`, `todo_community_contributors`, `todo_performance`, `todo_mesa_drivers`, plus P3 items in most other trackers

**Grand Total:** ~1,350+ items, ~1,720-2,710 engineer-days estimated

**Note:** Hardware track (IP integration, FPGA bring-up) runs **in parallel** with software 0.0.7 release and has its own timeline (3-6 months).

---

## Tracker Organization by Coverage Area

### Complete Coverage Matrix

| Area | Tracker(s) | Status |
|------|-----------|--------|
| **RTL Core** | DMA/PCIe, DRAM/AXI, HDMI, AXI-Lite | ✅ Complete |
| **Rendering** | Rendering, Ray Engine, Pipeline, Depth | ✅ Complete |
| **Platform** | Backends, Multiplatform | ✅ Complete |
| **Drivers** | Mesa Drivers, Testing/CI | ✅ Complete |
| **Testing** | Testing/CI, Hardware Validation | ✅ Complete |
| **Performance** | Performance | ✅ Complete |
| **Documentation** | Documentation | ✅ Complete |
| **Build/Tools** | Build Tooling | ✅ Complete |
| **Security** | Security | ✅ Complete |
| **Hardware** | Board FPGA, IP Integration, Hardware Validation | ✅ Complete |
| **Simulation** | Simulation Viewer | ✅ Complete |
| **Examples** | Examples Demos | ✅ Complete |
| **Community** | Community Contributors | ✅ Complete |
| **Deployment** | Deployment Operations | ✅ Complete |
| **Data Formats** | Data Formats | ✅ Complete |
| **Debugging** | Debugging Tools | ✅ Complete |
| **Research** | Research Experimental | ✅ Complete |

**Coverage:** ✅ **100% - All major areas tracked**

---

## How to Use This Index

### For Developers
1. Find your area of work in the coverage matrix above
2. Navigate to the relevant tracker file(s)
3. Search for `[P0]` or `[P1]` tags for priority items
4. Mark items `IN-PROGRESS` when starting work

### For Project Leads
1. Review priority distribution for sprint planning
2. Use this index to assign areas to team members
3. Track progress by monitoring `IN-PROGRESS` and `DONE` counts

### For Contributors
1. Look for `[P2]` or `[P3]` items in areas of interest
2. Examples and debugging tools are good starting points
3. Check Community tracker for contribution guidelines

---

## File Organization Conventions

### Naming
- `todo_<area>.md` - Domain-specific tracker
- `TODO_<NAME>.md` - Meta/navigation document (capitals)

### Status Tags
- `TODO` - Not started
- `TODO [PX]` - Not started with priority (X = 0-3)
- `IN-PROGRESS` - Actively being worked (with owner/notes)
- `DONE` - Completed (with commit/release reference)
- `WONTFIX-X.X.X` - Explicitly deferred

### Priority Tags
- `[P0]` - Critical, blocks release or hardware
- `[P1]` - High priority, should complete before 0.0.7
- `[P2]` - Medium priority, nice-to-have
- `[P3]` - Low priority, future work

---

## Maintenance Schedule

### Weekly
- Update `IN-PROGRESS` statuses
- Mark `DONE` items with commit hashes
- Add new items from code TODOs

### Sprint Reviews (Every 2 Weeks)
- Re-prioritize based on progress
- Update effort estimates
- Cross-reference completed work

### Releases
- Archive `DONE` items
- Promote valuable P2→P1 items
- Update `todo_prioritization.md`

---

## Metrics and Health

### Current Health: ✅ Excellent (Extended Coverage)

**Strengths:**
- ✅ Comprehensive coverage (100% of areas)
- ✅ Clear priority system (P0/P1/P2/P3 with effort estimates)
- ✅ **40 tracker files** covering all project areas (8 new critical infrastructure trackers added)
- ✅ **~1,350+ TODO items** tracked with priorities
- ✅ **~15,000+ lines** of detailed planning documentation
- ✅ Cross-references between related trackers
- ✅ Separate hardware and software tracks clearly delineated

**New Additions (2025-11-25):**
- ✅ `todo_build_tooling.md` - 49 items for CI, formatting, build automation
- ✅ `todo_documentation.md` - 34 items for spec updates, guides, tutorials
- ✅ `todo_hardware_validation.md` - 46 items for pre-silicon and FPGA bring-up
- ✅ `todo_performance.md` - 47 items for RTL and simulation optimization
- ✅ `todo_security.md` - 32 items for driver hardening and security
- ✅ `todo_board_fpga.md` - 26 items for board selection and synthesis
- ✅ `todo_ip_integration.md` - 50 items for LiteX/LitePCIe/LiteDRAM integration
- ✅ `todo_mesa_drivers.md` - 40 items for cross-platform driver support

**Recommended Metrics to Track:**
- P0 software completion rate (target: 100% before 0.0.7 release)
- P1 completion rate (target: 80% before 0.0.7 release)
- Hardware track P0 completion (separate timeline, 3-6 months)
- Average item age for IN-PROGRESS (alert if >30 days)
- New item rate vs. completion rate
- Cross-tracker dependency resolution

---

## Integration Points

### With Git
- Inline code TODOs should reference tracker: `// TODO: See todo_dma_pcie.md item #4`
- Commit messages can reference TODOs: "Implements todo_rendering.md P1 fog pass"

### With CI
- Could add check: "Are all code TODOs tracked in docs/?"
- Could generate TODO summary on PR

### With Issue Tracking
- GitHub Issues can reference TODO trackers
- TODO items could become tracked issues for community

---

## Special Tracks

### Hardware Track (Separate from Software 0.0.7)
- `todo_ip_integration.md` - 11 P0 items, 55-80 days
- `todo_board_fpga.md` - Board selection, constraints
- `todo_hardware_validation.md` - FPGA bring-up, testing

These run in parallel with software development and have their own timeline.

### Research Track (Post-1.0)
- `todo_research_experimental.md` - 44 P3 items, 1000-1800 days
- Speculative and exploratory
- 10-20% of team time allocated

---

## Quick Reference: Most Important Trackers

### For 0.0.7 Software Release (Primary Track)

1. **`todo_prioritization.md`** - Strategic roadmap and sprint plan
2. **`todo_build_tooling.md`** ✅ NEW - Build system, CI, formatting (P0/P1)
3. **`todo_documentation.md`** ✅ NEW - Spec updates, guides, tutorials (P0/P1)
4. **`todo_testing_ci.md`** - Testing infrastructure, kselftests (P0/P1)
5. **`todo_dma_pcie.md`** - DMA/PCIe validation in sim (P0 items)
6. **`todo_dram_axi.md`** - DRAM/AXI SVAs and stubs (P0 items)
7. **`todo_hdmi.md`** - HDMI/video stub validation (P0 items)
8. **`todo_rendering.md`** - Visual quality Phase 2+3 (P1)
9. **`todo_security.md`** ✅ NEW - Driver hardening, input validation (P1)

### For Hardware Bring-Up (Parallel Track)

1. **`todo_board_fpga.md`** ✅ NEW - Board selection, synthesis flow (P0/P1)
2. **`todo_ip_integration.md`** ✅ NEW - LitePCIe/LiteDRAM/LiteVideo (P0)
3. **`todo_hardware_validation.md`** ✅ NEW - Pre-silicon, FPGA testing (P0/P1)
4. **`todo_mesa_drivers.md`** ✅ NEW - FreeBSD, Windows, macOS drivers (P1/P2)

### For Post-0.0.7 Optimization

1. **`todo_performance.md`** ✅ NEW - RTL/sim/build optimization (P2/P3)

---

## Additional Resources

- **Quick Start:** [`TODO_README.md`](./TODO_README.md)
- **Sprint Plan:** [`todo_prioritization.md`](./todo_prioritization.md)
- **Session Summary:** [`todo_system_summary_2025_11_25.md`](./todo_system_summary_2025_11_25.md)
- **Master Tracker:** [`todo_master.md`](./todo_master.md)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Maintained By:** Project Lead
**Review Cycle:** Update when new trackers added or major reorganization
**Next Review:** After 0.0.7 Sprint 1 (week 2)
