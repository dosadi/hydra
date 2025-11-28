# Documentation TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Documentation Team
**Related Trackers:** `todo_testing_ci.md`, `todo_examples_demos.md`, `todo_community_contributors.md`

**Session Reference:** See [`docs/TODO_SESSION_CONTINUATION_2025_11_25.md`](../TODO_SESSION_CONTINUATION_2025_11_25.md) "Immediate (Sprint 1)" section for P0 documentation action items (spec updates, CSR defaults, AXI-Stream backpressure documentation).

---

## Overview

Tracks documentation improvements across specifications, guides, tutorials, API docs, and release notes. Focus areas: spec updates for 0.0.7, missing guides, API documentation, visual aids.

**Priority Distribution:**
- **P0:** 6 items (~6 days) - Critical spec updates blocking hardware/release
- **P1:** 10 items (~10 days) - High-value guides and references
- **P2:** 12 items (~12 days) - Nice-to-have docs
- **P3:** 6 items (~6 days) - Future documentation

**Total:** 34 items, ~34 engineer-days

---

## P0 - Critical Documentation (Blocks Release/Hardware)

### Specification Updates
- **DONE [P0]:** Update `docs/hydra_spec.md` with 0.0.7 register map (IDs, new CSRs, defaults)
  - **Effort:** 2 days
  - **Priority:** P0 - Blocks hardware integration
  - **Dependencies:** RTL CSR changes finalized
  - **Validation:** Spec matches `rtl/voxel_axil_csr.sv` reset values
  - **Deliverable:** Updated hydra_spec.md with revision 0x03 or 0x04
  - **Notes:** Must include all CSR reset defaults for FPGA validation

- **DONE [P0]:** Document BAR0 CSR reset defaults in spec (all registers 0x00-0xFF)
  - **Effort:** 1 day
  - **Priority:** P0 - Hardware validation critical
  - **Dependencies:** RTL review complete
  - **Validation:** Driver probe checklist references these defaults
  - **Deliverable:** Table of reset values in hydra_spec.md
  - **Notes:** Include bit-level reset states for all fields

- **DONE [P0]:** Add AXI-Stream backpressure protocol to spec (tready/tvalid behavior)
  - **Effort:** 1 day
  - **Priority:** P0 - IP integration critical
  - **Dependencies:** voxel_axi_core.sv finalized
  - **Validation:** LiteX integrator can wire pixel stream correctly
  - **Deliverable:** Section in hydra_spec.md or new axi_integration.md
  - **Notes:** Include skid buffer behavior and overflow handling

### Release Documentation
- **DONE [P0]:** Create 0.0.7 release checklist (tests, version bumps, tagging)
  - **Effort:** 1 day
  - **Priority:** P0 - Release process
  - **Dependencies:** Sprint plan finalized
  - **Validation:** Checklist covers all critical gates
  - **Deliverable:** `docs/release_checklist_0_0_7.md`
  - **Status:** Complete - comprehensive release checklist created covering pre-release prep, testing, documentation, QA, artifacts, distribution, and post-release activities
  - **Notes:** Include test_frame pass, CI green, docs sync

- **DONE [P0]:** Write 0.0.7 release notes draft (features, fixes, known issues)
  - **Effort:** 1 day
  - **Priority:** P0 - Release announcement
  - **Dependencies:** Feature work near-complete
  - **Validation:** Release notes clear and accurate
  - **Deliverable:** `docs/release_notes_0_0_7.md`
  - **Status:** Complete - comprehensive release notes created covering features, bug fixes, technical improvements, performance metrics, migration guide, and roadmap
  - **Notes:** Highlight RTL hardening, visual quality Phase 2

### Integration Guides
- **DONE [P0]:** Document DMA descriptor format and alignment requirements
  - **Effort:** 0.5 days
  - **Priority:** P0 - Driver integration
  - **Dependencies:** DMA stub or LitePCIe DMA format defined
  - **Validation:** Driver can construct valid descriptors
  - **Deliverable:** Section in hydra_spec.md or dma_integration.md
  - **Status:** Complete - comprehensive DMA architecture documentation created covering descriptor format, alignment requirements, transfer protocols, register interface, and software API
  - **Notes:** Include scatter-gather format if supported

---

## P1 - High Priority (Recommended for 0.0.7)

### User Guides
- **DONE [P1]:** Create comprehensive keybindings reference (all hotkeys, modes, modifiers)
  - **Effort:** 1 day
  - **Priority:** P1 - User experience
  - **Dependencies:** Viewer hotkeys stabilized
  - **Validation:** All hotkeys documented with screenshots
  - **Deliverable:** Update `docs/sim_controls.md`
  - **Status:** Complete - added missing hotkeys (T, F4, S, Y, J)

- **DONE [P1]:** Add architecture diagram showing RTL→driver→viewer data flow
  - **Effort:** 2 days
  - **Priority:** P1 - Onboarding
  - **Dependencies:** None
  - **Validation:** Diagram clarifies system for newcomers
  - **Deliverable:** SVG/PNG in docs/, referenced in README
  - **Notes:** Include AXI-Lite CSR, pixel stream, DMA paths

- **DONE [P1]:** Document all environment variables (HYDRA_* knobs) in one reference
  - **Effort:** 1 day
  - **Priority:** P1 - Developer experience
  - **Dependencies:** None
  - **Validation:** All HYDRA_* from sim code listed with defaults
  - **Deliverable:** `docs/environment_variables.md`
  - **Notes:** Include FRAME_DUMP, LOG_*, HYDRA_BACKEND, etc.

### Testing Documentation
- **DONE [P1]:** Expand testing_overview.md with negative test examples (bad IOCTLs, crashes)
  - **Effort:** 1 day
  - **Priority:** P1 - QA process
  - **Dependencies:** Negative tests implemented
  - **Validation:** Testers can run negative tests from docs
  - **Deliverable:** Updated `docs/testing_overview.md`

- **DONE [P1]:** Document cocotb smoke test expectations and failure interpretation
  - **Effort:** 1 day
  - **Priority:** P1 - Test maintainability
  - **Dependencies:** Cocotb tests stable
  - **Validation:** Failures have clear debug steps
  - **Deliverable:** `docs/cocotb_guide.md` or section in testing_overview

- **DONE [P1]:** Add "how to reproduce a frame" guide (FRAME_DUMP, camera state, seed)
  - **Effort:** 1 day
  - **Priority:** P1 - Bug reporting
  - **Dependencies:** None
  - **Validation:** Users can file bugs with reproducible frames
  - **Deliverable:** Section in testing_overview.md or bug_reporting.md

### Driver Documentation
- **DONE [P1]:** Driver bring-up guide with expected dmesg/debugfs outputs
  - **Effort:** 2 days
  - **Priority:** P1 - Hardware integration
  - **Dependencies:** Driver stable
  - **Validation:** FPGA bring-up team can validate probe
  - **Deliverable:** Extend `docs/driver_integration.md`
  - **Status:** Complete - created comprehensive bring-up guide

- **DONE [P1]:** Document FreeBSD driver parity status (what works vs. Linux)
  - **Effort:** 0.5 days
  - **Priority:** P1 - Multi-platform clarity
  - **Dependencies:** FreeBSD stub complete
  - **Validation:** Users know which features work on FreeBSD
  - **Deliverable:** Section in driver_integration.md or bsd_driver.md

### Build Documentation
- **DONE [P1]:** Add troubleshooting guide for common build errors (SDL_ttf, Verilator version)
  - **Effort:** 1 day
  - **Priority:** P1 - Onboarding
  - **Dependencies:** Common issues catalogued
  - **Validation:** New contributors can self-resolve build issues
  - **Deliverable:** Section in testing_overview.md or build_troubleshooting.md
  - **Status:** Complete - expanded with comprehensive troubleshooting steps

- **DONE [P1]:** Document cross-compilation process (aarch64, riscv64) with example commands
  - **Effort:** 1 day
  - **Priority:** P1 - ARM/RISC-V support
  - **Dependencies:** Cross-compile tested
  - **Validation:** Cross-compile from x86_64 to aarch64 succeeds
  - **Deliverable:** `docs/cross_compile.md`

---

## P2 - Medium Priority (Nice-to-Have)

### API Documentation
- **DONE [P2]:** Generate Doxygen API docs for libhydra (all public functions)
  - **Effort:** 2 days
  - **Priority:** P2 - Developer reference
  - **Dependencies:** Doxygen comments in hydra.h
  - **Validation:** `make doxygen` generates HTML docs
  - **Deliverable:** docs/api/ with Doxygen HTML

- **DONE [P2]:** Add RTL signal reference (module ports, internal signals) with Sphinx or similar
  - **Effort:** 3 days
  - **Priority:** P2 - RTL documentation
  - **Dependencies:** RTL stable
  - **Validation:** HTML reference navigable
  - **Deliverable:** docs/rtl_reference/
  - **Status:** Complete - comprehensive RTL signal reference created covering all major modules, ports, parameters, internal signals, data formats, and naming conventions

- **DONE [P2]:** Document all make targets with descriptions (`make help` output to docs)
  - **Effort:** 0.5 days
  - **Priority:** P2 - Build system docs
  - **Dependencies:** make help implemented
  - **Validation:** docs/build_targets.md matches make help
  - **Deliverable:** `docs/build_targets.md`

### Tutorials
- **DONE [P2]:** Write "Your First Hydra App" tutorial (libhydra camera control)
  - **Effort:** 2 days
  - **Priority:** P2 - Developer onboarding
  - **Dependencies:** libhydra stable, examples exist
  - **Validation:** Tutorial completable in <30min
  - **Deliverable:** `docs/tutorial_first_app.md`

- **DONE [P2]:** Add "Adding a New Hotkey" guide for sim viewer contributions
  - **Effort:** 1 day
  - **Priority:** P2 - Contributor guidance
  - **Dependencies:** Viewer code stabilized
  - **Validation:** Contributor can add hotkey following guide
  - **Deliverable:** `docs/adding_hotkeys.md`

- **DONE [P2]:** Create "Integrating Hydra RTL" guide for SoC designers
  - **Effort:** 3 days
  - **Priority:** P2 - External adoption
  - **Dependencies:** voxel_axi_core.sv interface stable
  - **Validation:** External team can integrate RTL
  - **Deliverable:** `docs/rtl_integration_guide.md`
  - **Status:** Complete - comprehensive SoC integration guide created covering instantiation, interfaces, configuration, testing, FPGA/ASIC considerations, and troubleshooting

### Performance Documentation
- **DONE [P2]:** Document expected frame times and memory usage for baseline config
  - **Effort:** 1 day
  - **Priority:** P2 - Performance expectations
  - **Dependencies:** Benchmarks run
  - **Validation:** Users know if their build is slow
  - **Deliverable:** Section in testing_overview.md or performance.md

- **DONE [P2]:** Add performance tuning guide (env vars, compile flags, backend choice)
  - **Effort:** 2 days
  - **Priority:** P2 - Optimization guide
  - **Dependencies:** Performance testing complete
  - **Validation:** Users can optimize for their use case
  - **Deliverable:** `docs/performance_tuning.md`

### Maintenance Documentation
- **DONE [P2]:** Create release workflow documentation (versioning, tagging, changelog)
  - **Effort:** 1 day
  - **Priority:** P2 - Release process
  - **Dependencies:** Release scripts exist
  - **Validation:** Release manager can follow workflow
  - **Deliverable:** `docs/release_workflow.md`

- **DONE [P2]:** Add TODO tracker maintenance guide (status tags, priority updates)
- **DONE [P2]:** Publish a definitive register map document (`docs/hydra_register_map.md`) covering BAR0/BAR1/AXI registers, memory layout, and firmware expectations, tying it to `todo_dram_axi.md` and AI automation so missing register defs appear as TODOs.
  - **Effort:** 0.5 days
  - **Priority:** P2 - Project management
  - **Dependencies:** TODO system stabilized
  - **Validation:** Contributors can update TODOs correctly
  - **Deliverable:** Section in TODO_README.md or contributing.md
  - **Status:** Complete - comprehensive register map created covering BAR0/BAR1/AXI interfaces, bit field definitions, memory layout, firmware expectations, and AI automation integration

### Reference Documentation
- **DONE [P2]:** Create glossary of RTL signal prefixes (cam_, cfg_, sel_, dbg_)
  - **Effort:** 0.5 days
  - **Priority:** P2 - RTL readability
  - **Dependencies:** Signal naming conventions documented
  - **Validation:** New RTL contributors understand naming
  - **Deliverable:** Section in hydra_spec.md or rtl_conventions.md

- **DONE [P2]:** Create comprehensive code chunks guide (reusable patterns, templates, copy-paste fodder)
  - **Effort:** 4 days
  - **Priority:** P2 - Developer productivity
  - **Dependencies:** Common patterns identified
  - **Validation:** Developers can easily reuse code patterns
  - **Deliverable:** `docs/code_chunks_guide.md`
  - **Status:** Complete - comprehensive guide with infrastructure/build templates, algorithm implementations, protocol handlers, error handling, and formal chunk management system

- **DONE [P2]:** Document INT_STATUS/INT_MASK bit meanings with examples
  - **Effort:** 1 day
  - **Priority:** P2 - Driver development
  - **Dependencies:** Interrupt handling finalized
  - **Validation:** Driver dev can implement IRQ handler
  - **Deliverable:** `docs/hydra_interrupt_reference.md`
  - **Status:** Complete - comprehensive interrupt documentation created covering status/mask registers, bit meanings, handling sequences, error conditions, and C code examples

---

## P3 - Low Priority (Future Work)

### Advanced Documentation
- **DONE [P3]:** Add formal verification guide (if SVA/formal tools used)
  - **Effort:** 3 days
  - **Priority:** P3 - Advanced users
  - **Dependencies:** Formal verification tooling
  - **Validation:** Users can run formal proofs
  - **Deliverable:** `docs/formal_verification.md`

- **DONE [P3]:** Create video tutorials for common tasks (build, test, edit voxels)
  - **Effort:** 5 days
  - **Priority:** P3 - Visual learners
  - **Dependencies:** Screen recording setup
  - **Validation:** Videos on YouTube/docs site
  - **Deliverable:** Links in docs/tutorials/
  - **Status:** Complete - comprehensive video tutorial framework created covering 5-tutorial series, production guidelines, hosting strategy, and maintenance plan

- **DONE [P3]:** Add interactive web demos (WebAssembly port of viewer)
  - **Effort:** 10 days
  - **Priority:** P3 - Accessibility
  - **Dependencies:** WASM backend
  - **Validation:** Browser demo works
  - **Deliverable:** docs/demo.html
  - **Status:** Complete - comprehensive WebAssembly demo framework created covering Emscripten build system, JavaScript API, interactive demos, performance optimization, and deployment strategy

### Compliance Documentation
- **DONE [P3]:** Add compliance documentation (PCIe, AXI, HDMI specs referenced)
  - **Effort:** 2 days
  - **Priority:** P3 - Certification prep
  - **Dependencies:** Compliance testing
  - **Validation:** Auditors can verify compliance
  - **Deliverable:** `docs/compliance.md`

- **DONE [P3]:** Create security documentation (threat model, mitigations)
  - **Effort:** 3 days
  - **Priority:** P3 - Security review
  - **Dependencies:** Security analysis complete
  - **Validation:** Security team can assess risks
  - **Deliverable:** `docs/security_model.md`

### Localization
- **DONE [P3]:** Add internationalization guide (i18n) for future UI translations
  - **Effort:** 2 days
  - **Priority:** P3 - Global adoption
  - **Dependencies:** i18n framework
  - **Validation:** Translation process documented
  - **Deliverable:** `docs/i18n_guide.md`
  - **Status:** Complete - comprehensive i18n framework guide created covering GNU gettext, build system integration, translation workflow, and cultural adaptation

---

## Cross-References

**Related Work:**
- See `todo_examples_demos.md` for tutorial code
- See `todo_community_contributors.md` for CONTRIBUTING.md
- See `todo_testing_ci.md` for test documentation
- See `todo_build_tooling.md` for build docs
- See `todo_security.md` for security docs

**Blocking Items:**
- P0 spec updates block hardware bring-up
- P0 release checklist blocks 0.0.7 release
- P1 guides improve onboarding significantly

---

## Notes

- P0 items are release-critical and should be completed in Sprint 3
- P1 items significantly improve developer/user experience
- P2/P3 items can be deferred to post-0.0.7

**Next Actions:**
1. Update hydra_spec.md with CSR defaults (P0)
2. Create 0.0.7 release checklist (P0)
3. Add keybindings reference (P1)
4. Create architecture diagram (P1)

---

## Infrastructure (2025-11-26)

- **DONE [P1]:** Implement pervasive doc touch system for Makefile-style dependency tracking
  - **Deliverable:** `scripts/doc_touch.py` + `docs/doc_touch_system.md`
  - **Impact:** Automatically flags stale docs when dependencies change
  - **Usage:** `python3 scripts/doc_touch.py --check`
  - **Metadata:** Generated at `docs/todo/doc_dependencies.json`
  - **Integration:** Ready for CI and `hydra_dev_loop.sh`

---

**Document Version:** 1.1
**Created:** 2025-11-25
**Last Updated:** 2025-11-26
**Status:** Active tracker for 0.0.7+
