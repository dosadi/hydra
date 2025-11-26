# Hydra TODO System - Quick Start

**Last Updated:** 2025-11-25 (0.0.7 cycle)
**Status:** Production-ready
**Total Items:** ~1,120+ tracked across 25 domain trackers + 6 meta docs

---

## TL;DR

- **Quick start:** Read [`todo_prioritization.md`](./todo_prioritization.md) for the 8-week sprint plan
- **Daily work:** Check [`todo_master.md`](./todo_master.md) for IN-PROGRESS items
- **Navigation:** Use [`todo_guide.md`](./todo_guide.md) to find work by area
- **What's new:** See [`todo_changelog_0_0_7.md`](./todo_changelog_0_0_7.md) for changes since 0.0.6

---

## File Index

### Meta Documents (Start Here)
1. **`todo_prioritization.md`** - Strategic roadmap with P0/P1/P2 priorities, 4-sprint plan
2. **`todo_guide.md`** - Navigation guide, quick start by area
3. **`todo_changelog_0_0_7.md`** - Changes from 0.0.6 → 0.0.7, migration guide
4. **`todo_session_summary_2025_11_25.md`** - Detailed session notes
5. **`TODO_README.md`** - This file
6. **`todo_rebalance_policy.md`** - Guidelines for keeping tracker volumes balanced

### Master Tracker
6. **`todo_master.md`** - Cross-cutting items (sim/viewer, drivers, build/CI, docs)

### Domain-Specific Trackers

**RTL/Hardware:**
7. **`todo_dma_pcie.md`** - DMA/PCIe path (P0: backpressure, assertions, validation)
8. **`todo_dma_structured_logging.md`** - DMA structured logging schema + drivers (P1/P2)
9. **`todo_dma_trace_artifacts.md`** - DMA trace artifact pipeline (P1/P2: VCD/log capture)
10. **`todo_dma_hotplug.md`** - PCIe hotplug cleanup + DMA recovery steps (P1)
11. **`todo_dma_hang_policy.md`** - DMA hang detection/retry policy (P1)
12. **`todo_dram_axi.md`** - DRAM/AXI integration (P0: SVAs, protocol compliance)
13. **`todo_hdmi_display.md`** - HDMI display/timing, CRC counters, connectors
14. **`todo_hdmi_stream.md`** - HDMI pixel stream/backpressure and CRC logging
15. **`todo_hdmi.md`** - HDMI overview/index (links to sub-trackers)
16. **`todo_ip_integration.md`** - LiteX IP integration (P0: replace AXI stubs) **NEW**
17. **`todo_axi_mem.md`** - AXI memory subsystem logging & instrumentation (new)

**Rendering:**
11. **`todo_rendering.md`** - Rendering quality overview (links to focused trackers)
12. **`todo_rendering_presets.md`** - Presets, LUTs, and color grading
13. **`todo_rendering_effects.md`** - Fog, AO, bloom, volumetrics
14. **`todo_rendering_camera.md`** - Camera/capture features
15. **`todo_rendering_debug.md`** - HUD overlays, histograms, heatmaps
16. **`todo_rendering_pipeline.md`** - Pipeline/shader profiling (mostly P2)
17. **`todo_depth_buffer.md`** - Depth buffer tracking (P2)
18. **`todo_reemissure.md`** - Emissive/sideband coverage (P2)
19. **`todo_ray_engine.md`** - Ray marching (P2/P3)

**Platform:**
15. **`todo_platform_backends.md`** - SDL/GL/Vulkan (P1: backend precedence test)

**Drivers/Testing:**
16. **`todo_mesa_drivers.md`** - Mesa/Windows/macOS drivers (P1: FreeBSD, P2: Mesa)
17. **`todo_testing_ci.md`** - Testing & CI expansion (P0: SVAs, P1: kselftests)
18. **`todo_hardware_validation.md`** - Hardware testing & FPGA bring-up (P0: pre-silicon, P1: FPGA) **NEW**

**Performance & Optimization:**
19. **`todo_performance.md`** - Performance optimization (P2: sim/RTL, P3: software) **NEW**

**Infrastructure:**
20. **`todo_documentation.md`** - Documentation updates (P0: spec, P1: keybindings, guides) **NEW**
21. **`todo_build_tooling.md`** - Build system & tooling (P1: formatting, CI jobs) **NEW**
22. **`todo_security.md`** - Security hardening (P1: input validation, driver hardening) **NEW**

**Hardware:**
23. **`todo_board_fpga.md`** - Board selection & FPGA synthesis (P0: board selection, P1: constraints) **NEW**

**Simulation:**
24. **`todo_simulation_viewer.md`** - Viewer features & world editing (P1: HUD, P2: editing tools) **NEW**

**Examples & Community:**
25. **`todo_examples_demos.md`** - Examples, demos, benchmarks (P1: basic examples, P2: benchmarks) **NEW**
26. **`todo_community_contributors.md`** - Community engagement & contributor onboarding (P2: docs, P3: events) **NEW**

**Deployment:**
27. **`todo_deployment_operations.md`** - Packaging, installation, operations (P1: requirements, P2: packaging) **NEW**

**Data & Tools:**
28. **`todo_data_formats.md`** - Voxel formats, import/export, file I/O (P2: native format, converters) **NEW**
29. **`todo_debugging_tools.md`** - Debug tools, visualization, profiling (P1: debug aids, P2: profilers) **NEW**

**Research:**
30. **`todo_research_experimental.md`** - Experimental features, research ideas (All P3: long-term R&D) **NEW**

---

## Priority Summary

### P0 (32 items) - **Critical, blocks 0.0.7 release or hardware bring-up**
- **RTL:** AXI backpressure, SVAs, DMA assertions (9 items)
- **IP Integration:** LitePCIe/LiteDRAM/LiteVideo (11 items)
- **Testing:** AXI-Lite testbench, golden frame update (6 items)
- **Docs:** Update spec to 0.0.7, CSR defaults, release checklist (6 items)

**Total P0 effort:** ~20 engineer-days

### P1 (51 items) - **High priority, strongly recommended for 0.0.7**
- **Rendering:** Phase 2 visual quality (fog+AO), reemissure wiring (5 items)
- **RTL:** Compile-time params, assertions (3 items)
- **Drivers:** FreeBSD parity, kselftests, formatting (17 items)
- **IP Integration:** Scatter-gather DMA, crossbar (9 items)
- **Testing:** Cocotb, CI jobs, smoke tests (15 items)
- **Docs:** Keybindings, architecture diagram, checklists (2 items)

**Total P1 effort:** ~36 engineer-days

### P2/P3 (560+ items) - **Nice-to-have or future work**
- Spread across all trackers
- Estimated 255-398 engineer-days (defer to 0.0.8+)

---

## Quick Commands

### Find all P0 items
```bash
grep -r "\[P0\]" docs/todo_*.md
```

### Find all IN-PROGRESS items
```bash
grep -r "IN-PROGRESS" docs/todo_*.md
```

### Count DONE items
```bash
grep -r "^- DONE:" docs/todo_*.md | wc -l
```

### Search for a keyword
```bash
grep -ri "backpressure" docs/todo_*.md
```

### Check a specific domain (e.g., HDMI)
```bash
cat docs/todo_hdmi.md | grep "TODO"
```

---

### Sweep docs TODOs
```bash
python3 scripts/todo_sweep.py
```
Lists per-tracker TODO counts and priority distribution so you can spot high-priority clusters before starting work.

## 0.0.7 Sprint Plan at a Glance

**Duration:** 8 weeks (~56 engineer-days effort)

| Sprint | Weeks | Focus | P0 Items | P1 Items |
|--------|-------|-------|----------|----------|
| **Sprint 1** | 1-2 | RTL hardening | 9 | 0 |
| **Sprint 2** | 3-4 | DMA/PCIe validation | 6 | 4 |
| **Sprint 3** | 5-6 | Visual quality + docs | 6 | 8 |
| **Sprint 4** | 7-8 | Polish + release | 0 | 10 |

**See [`todo_prioritization.md`](./todo_prioritization.md) for detailed task lists per sprint.**

---

## What Changed in 0.0.7

### Completed in 0.0.6 (Yesterday!)
- ✅ UAPI version ioctl (`HYDRA_IOCTL_VERSION`)
- ✅ BAR1 hexdump tool
- ✅ CLI backend override (`--backend`/`-b`)
- ✅ Enhanced HUD (backend/vsync info)
- ✅ Window resize handling
- ✅ Backend probe script and triage guide
- ✅ BAR layout documentation
- ✅ Expanded TODO trackers (rendering, DMA, HDMI, etc.)

### Focus Areas for 0.0.7
1. **RTL Hardening:** Backpressure, SVAs, protocol compliance
2. **Visual Quality:** Phase 2 (fog+AO), Phase 3 (reemissure wiring)
3. **Testing:** Expand coverage, harden CI
4. **Hardware Prep:** Document CSR defaults, update spec

### New Gaps Closed
- **IP Integration:** LiteX roadmap (55-80 days, separate track)
- **Mesa/Drivers:** Cross-platform driver plan (107-161 days, post-0.0.7)
- **Testing/CI:** Comprehensive test strategy (74-103 days, P0+P1 in 0.0.7)

---

## How to Use This System

### If you're new to the project:
1. Read [`todo_guide.md`](./todo_guide.md) - "Quick Start" section
2. Find your area (RTL, rendering, drivers, testing)
3. Check the relevant domain tracker
4. Pick a P0 or P1 item, mark it IN-PROGRESS
5. Update status as you work

### If you're planning sprints:
1. Review [`todo_prioritization.md`](./todo_prioritization.md)
2. Assign owners to Sprint 1 P0 items
3. Track progress in weekly standups
4. Update `IN-PROGRESS` and `DONE` tags

### If you're triaging new work:
1. Add item to relevant domain tracker
2. Assign priority tag (`[P0]`, `[P1]`, `[P2]`)
3. Add effort estimate (Small/Medium/Large)
4. Cross-reference if it affects sprint plan
5. Consider updating [`todo_prioritization.md`](./todo_prioritization.md) if it's P0/P1

### If you completed an item:
1. Mark it `DONE` in the tracker
2. Add commit reference or release note
3. Update [`todo_prioritization.md`](./todo_prioritization.md) if it was on the sprint plan
4. Remove from active sprint board

---

## Status Tags Reference

- **`TODO`** - Not started
- **`TODO [P0/P1/P2]`** - Not started, with priority
- **`IN-PROGRESS`** - Actively being worked (with owner/notes)
- **`DONE`** - Completed (with commit/release reference)
- **`WONTFIX-0.0.7`** - Explicitly deferred with rationale

---

## File Size Reference

| File | Lines | Items | Primary Priority |
|------|-------|-------|------------------|
| **Meta Documents** | | | |
| `todo_prioritization.md` | 692 | N/A | Meta (sprint plan) |
| `todo_guide.md` | 280 | N/A | Meta (navigation) |
| `todo_changelog_0_0_7.md` | 385 | N/A | Meta (changes) |
| `todo_session_summary...md` | ~500 | N/A | Meta (session notes) |
| `TODO_README.md` | ~280 | N/A | Meta (this file) |
| **Master Tracker** | | | |
| `todo_master.md` | ~265 | ~180 | Mixed P0/P1/P2 |
| **Domain Trackers** | | | |
| `todo_dma_pcie.md` | ~48 | ~47 | P0 heavy |
| `todo_dram_axi.md` | ~58 | ~58 | P0 heavy |
| `todo_hdmi.md` | ~43 | ~43 | P0 moderate |
| `todo_ip_integration.md` | ~450 | ~50 | P0 (hardware) |
| `todo_rendering.md` | ~79 | ~79 | P1/P2 |
| `todo_rendering_pipeline.md` | ~27 | ~27 | P2/P3 |
| `todo_depth_reemissure.md` | ~49 | ~49 | P2 |
| `todo_ray_engine.md` | ~43 | ~43 | P2/P3 |
| `todo_platform_backends.md` | ~68 | ~68 | P1 light |
| `todo_mesa_drivers.md` | ~380 | ~40 | P1/P2 |
| `todo_testing_ci.md` | ~450 | ~80 | P0/P1 |
| `todo_hardware_validation.md` | ~435 | ~46 | P0/P1 (hardware) |
| `todo_performance.md` | ~370 | ~47 | P2/P3 |
| `todo_documentation.md` | ~350 | ~34 | P0/P1 |
| `todo_build_tooling.md` | ~435 | ~49 | P0/P1 |
| `todo_security.md` | ~420 | ~32 | P1/P2 |
| `todo_board_fpga.md` | ~380 | ~26 | P0/P1 (hardware) |
| `todo_simulation_viewer.md` | ~445 | ~44 | P1/P2/P3 |
| `todo_examples_demos.md` | ~340 | ~21 | P1/P2/P3 |
| `todo_community_contributors.md` | ~415 | ~31 | P2/P3 |
| `todo_deployment_operations.md` | ~395 | ~41 | P1/P2/P3 |
| `todo_data_formats.md` | ~330 | ~30 | P2/P3 |
| `todo_debugging_tools.md` | ~380 | ~38 | P1/P2/P3 |
| `todo_research_experimental.md` | ~450 | ~44 | P3 (research) |
| **Total** | **~8,742** | **~1,120+** | |

---

## Common Questions

**Q: Which file should I read first?**
A: [`todo_prioritization.md`](./todo_prioritization.md) for strategic overview, or [`todo_guide.md`](./todo_guide.md) for navigation.

**Q: Where do I find work in my area?**
A: Use [`todo_guide.md`](./todo_guide.md) "Finding Work by Area" section to navigate to your domain tracker.

**Q: How do I know what's P0 vs. P1?**
A: Check [`todo_prioritization.md`](./todo_prioritization.md) for the authoritative list, or grep for `[P0]` tags in trackers.

**Q: What if I find a new TODO in the code?**
A: Add it to the relevant domain tracker with a priority tag, and consider updating [`todo_prioritization.md`](./todo_prioritization.md) if it's critical.

**Q: How do I update my progress?**
A: Edit the tracker file, change `TODO` → `IN-PROGRESS`, add your name/notes. Mark `DONE` when complete.

**Q: What's the difference between the trackers?**
A: Domain trackers are detailed/technical; [`todo_prioritization.md`](./todo_prioritization.md) is strategic/high-level with sprint plan.

**Q: Are there tools to help manage this?**
A: Currently manual (grep, text editors). Future: Consider scripting unified views, GitHub Issues integration, dashboards.

---

## Contributing

When adding TODOs:
1. Choose the right tracker (domain-specific vs. `todo_master.md`)
2. Add priority tag (`[P0]`, `[P1]`, `[P2]`) if known
3. Provide effort estimate (Small/Medium/Large)
4. Include context (why important, dependencies, validation)
5. Cross-reference related items

When updating status:
1. Mark `IN-PROGRESS` when starting (with owner)
2. Add brief notes on blockers/progress
3. Mark `DONE` when complete (with commit ref)
4. Update sprint plan if it affects milestones

---

## Feedback

Found an issue or have suggestions? See:
- **Issues:** File a GitHub issue linking to this doc
- **Improvements:** PRs welcome (keep formatting consistent)
- **Questions:** Ask in project chat or standup

---

**System Health:** ✅ Excellent
- 30+ TODO tracker files (25+ domain + 6 meta)
- ~8,742 lines of TODO tracking
- ~1,120+ items tracked across all areas
- Clear priorities (38 P0, ~80 P1, ~1000+ P2/P3)
- Sprint plan ready
- Comprehensive coverage: RTL, rendering, drivers, testing, hardware, performance, security, simulation, examples, community, deployment, data formats, debugging tools, research

**Next Action:** Team review of [`todo_prioritization.md`](./todo_prioritization.md) and Sprint 1 owner assignment.

---

*For detailed session notes, see [`todo_session_summary_2025_11_25.md`](./todo_session_summary_2025_11_25.md).*
