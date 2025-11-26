# Mesa/Cross-Platform Drivers TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Driver Team
**Related Trackers:** `todo_security.md`, `todo_testing_ci.md`, `todo_multiplatform_builds.md`

**Session Reference:** See [`docs/TODO_SESSION_CONTINUATION_2025_11_25.md`](../TODO_SESSION_CONTINUATION_2025_11_25.md) "Near-Term (Sprint 2-3)" section for P1 cross-platform driver action items (FreeBSD parity, driver testing, package creation).

---

## Overview

Tracks driver development for FreeBSD, Windows, macOS, and Mesa (Linux DRM/DRI) integration. Focus areas: FreeBSD parity with Linux, Windows kernel driver, macOS driver, Mesa Gallium integration.

**Priority Distribution:**
- **P0:** 0 items - No cross-platform blockers for 0.0.7
- **P1:** 8 items (~15 days) - FreeBSD hardening and bring-up
- **P2:** 20 items (~60 days) - Mesa and Windows drivers
- **P3:** 12 items (~32 days) - macOS and advanced features

**Total:** 40 items, ~107 engineer-days (post-0.0.7 focus)

**Note:** Cross-platform driver work is **post-0.0.7**. The 0.0.7 release focuses on Linux driver hardening. FreeBSD stub is functional but basic.

---

## P1 - High Priority FreeBSD Driver (Recommended for 0.0.7)

### FreeBSD Driver Hardening
- **TODO [P1]:** Bring FreeBSD driver to parity with Linux (all ioctls, BAR access)
  - **Effort:** 3 days
  - **Priority:** P1 - Platform parity
  - **Dependencies:** Linux driver stable
  - **Validation:** All Linux userspace tools work on FreeBSD
  - **Deliverable:** Updated drivers/bsd/hydra_pci_stub.c
  - **Status:** Basic ioctls done - add DMA, blitter, remaining CSRs

- **TODO [P1]:** Add FreeBSD sysctl nodes for status (match Linux debugfs)
  - **Effort:** 2 days
  - **Priority:** P1 - Debugging parity
  - **Dependencies:** None
  - **Validation:** sysctl dev.hydra shows BAR sizes, IRQ count, status
  - **Deliverable:** Sysctl implementation in FreeBSD driver
  - **Status:** DONE - extend with more status info

- **TODO [P1]:** Test FreeBSD driver on real hardware (or VM with passthrough)
  - **Effort:** 2 days
  - **Priority:** P1 - Validation
  - **Dependencies:** FreeBSD driver complete
  - **Validation:** Driver loads, userspace tools work
  - **Deliverable:** FreeBSD test pass log

- **TODO [P1]:** Add FreeBSD driver to CI (if FreeBSD VM available)
  - **Effort:** 3 days
  - **Priority:** P1 - Regression prevention
  - **Dependencies:** CI infrastructure
  - **Validation:** FreeBSD driver builds in CI
  - **Deliverable:** CI job for FreeBSD build

### FreeBSD Userspace
- **TODO [P1]:** Build libhydra on FreeBSD (handle platform differences)
  - **Effort:** 2 days
  - **Priority:** P1 - Userspace support
  - **Dependencies:** FreeBSD driver working
  - **Validation:** libhydra builds and runs on FreeBSD
  - **Deliverable:** FreeBSD build support in libhydra

- **TODO [P1]:** Test all userspace tools on FreeBSD (smoketests, demos, info)
  - **Effort:** 1 day
  - **Priority:** P1 - Platform validation
  - **Dependencies:** libhydra on FreeBSD
  - **Validation:** All tools work identically to Linux
  - **Deliverable:** FreeBSD test matrix

- **TODO [P1]:** Document FreeBSD installation and usage (README or docs/bsd_driver.md)
  - **Effort:** 1 day
  - **Priority:** P1 - User guidance
  - **Dependencies:** FreeBSD driver stable
  - **Validation:** Users can install and use on FreeBSD
  - **Deliverable:** docs/freebsd_installation.md

- **TODO [P1]:** Add FreeBSD package (pkg or ports entry)
  - **Effort:** 2 days
  - **Priority:** P1 - Distribution
  - **Dependencies:** FreeBSD driver stable
  - **Validation:** pkg install hydra works
  - **Deliverable:** FreeBSD port or package

---

## P2 - Medium Priority Mesa and Windows Drivers (Post-0.0.7)

### Mesa DRM/DRI Integration (Linux)
- **TODO [P2]:** Research Mesa Gallium driver architecture for custom accelerators
  - **Effort:** 5 days
  - **Priority:** P2 - Mesa prerequisite
  - **Dependencies:** None
  - **Validation:** Understand Gallium pipe driver interface
  - **Deliverable:** Mesa integration design doc

- **TODO [P2]:** Create Mesa Gallium pipe driver stub for Hydra
  - **Effort:** 10 days
  - **Priority:** P2 - Mesa foundation
  - **Dependencies:** Research complete
  - **Validation:** Mesa builds with Hydra driver stub
  - **Deliverable:** mesa/src/gallium/drivers/hydra/

- **TODO [P2]:** Implement basic Mesa context creation and state tracking
  - **Effort:** 7 days
  - **Priority:** P2 - Mesa functionality
  - **Dependencies:** Gallium stub created
  - **Validation:** glxinfo shows Hydra renderer
  - **Deliverable:** Context management in Gallium driver

- **TODO [P2]:** Add voxel rendering commands to Mesa driver (glDrawArrays → voxel ops)
  - **Effort:** 10 days
  - **Priority:** P2 - Rendering pipeline
  - **Dependencies:** Context creation working
  - **Validation:** Simple OpenGL app renders via Hydra
  - **Deliverable:** Rendering command translation

- **TODO [P2]:** Integrate Mesa driver with Linux DRM driver (GEM, prime, etc.)
  - **Effort:** 8 days
  - **Priority:** P2 - Memory management
  - **Dependencies:** Mesa driver basic functionality
  - **Validation:** Buffer sharing works
  - **Deliverable:** DRM integration in Mesa driver

- **TODO [P2]:** Test Mesa driver with example OpenGL applications
  - **Effort:** 3 days
  - **Priority:** P2 - Validation
  - **Dependencies:** Mesa driver functional
  - **Validation:** glxgears, es2gears render correctly
  - **Deliverable:** Mesa test pass log

- **TODO [P2]:** Document Mesa driver architecture and usage
  - **Effort:** 3 days
  - **Priority:** P2 - Documentation
  - **Dependencies:** Mesa driver stable
  - **Validation:** Developers can extend Mesa driver
  - **Deliverable:** docs/mesa_driver_architecture.md

### Windows Kernel Driver (WDDM or WDM)
- **TODO [P2]:** Research Windows driver models (WDDM for graphics, WDM for PCIe)
  - **Effort:** 4 days
  - **Priority:** P2 - Windows prerequisite
  - **Dependencies:** None
  - **Validation:** Understand Windows driver architecture
  - **Deliverable:** Windows driver design doc

- **TODO [P2]:** Create Windows kernel driver stub (WDM PCIe driver)
  - **Effort:** 8 days
  - **Priority:** P2 - Windows foundation
  - **Dependencies:** Research complete, Windows DDK
  - **Validation:** Driver loads on Windows, enumerates PCIe device
  - **Deliverable:** drivers/windows/hydra_wdm.sys

- **TODO [P2]:** Implement Windows ioctl interface (matching Linux ioctls)
  - **Effort:** 6 days
  - **Priority:** P2 - Userspace interface
  - **Dependencies:** WDM driver stub created
  - **Validation:** Userspace can read/write CSRs
  - **Deliverable:** Ioctl handlers in Windows driver

- **TODO [P2]:** Add Windows DMA support (scatter-gather, MDLs)
  - **Effort:** 8 days
  - **Priority:** P2 - Performance
  - **Dependencies:** Basic ioctl working
  - **Validation:** DMA transfers work on Windows
  - **Deliverable:** DMA implementation in Windows driver

- **TODO [P2]:** Implement Windows interrupt handling (MSI/MSI-X)
  - **Effort:** 5 days
  - **Priority:** P2 - Interrupt delivery
  - **Dependencies:** WDM driver working
  - **Validation:** Interrupts delivered to driver
  - **Deliverable:** IRQ handlers in Windows driver

- **TODO [P2]:** Create Windows userspace library (libhydra for Windows)
  - **Effort:** 5 days
  - **Priority:** P2 - Userspace support
  - **Dependencies:** Windows driver functional
  - **Validation:** Userspace tools work on Windows
  - **Deliverable:** drivers/windows/libhydra_win.dll

- **TODO [P2]:** Test Windows driver on Windows 10/11
  - **Effort:** 3 days
  - **Priority:** P2 - Validation
  - **Dependencies:** Windows driver complete
  - **Validation:** Driver stable on Windows 10 and 11
  - **Deliverable:** Windows test pass log

- **TODO [P2]:** Add Windows driver signing (test-signing or commercial cert)
  - **Effort:** 2 days
  - **Priority:** P2 - Distribution
  - **Dependencies:** Windows driver stable
  - **Validation:** Driver installs without warnings
  - **Deliverable:** Signed driver package

- **TODO [P2]:** Document Windows driver installation and usage
  - **Effort:** 2 days
  - **Priority:** P2 - User guidance
  - **Dependencies:** Windows driver stable
  - **Validation:** Users can install and use on Windows
  - **Deliverable:** docs/windows_installation.md

- **TODO [P2]:** Investigate WDDM for Windows graphics integration (if OpenGL/DirectX support desired)
  - **Effort:** 5 days
  - **Priority:** P2 - Graphics stack
  - **Dependencies:** WDM driver working
  - **Validation:** Feasibility assessment complete
  - **Deliverable:** WDDM investigation report

- **TODO [P2]:** Add Windows to CI (if Windows runner available)

### Windows Driver Status & Plan
- **Status:** Work in progress; research + WDM stub exist but full DMA/IRQ support pending. 32-bit (x86) build scripts rely on the same source tree as 64-bit (x64), but we still need dual-target build flags (MSVC toolset) and installers that include both architectures.
- **Next steps:** Formalize the cross-build pipeline (MSVC/x64/x86), produce matching INF/drop-in packages, and expand docs that describe how the Windows runtime loads the Hydra device on both bitnesses.

### Supplemental Windows Todos
- **TODO [P1]:** Add MSVC solution configurations for both Win32 and Win64 builds, ensuring the driver and `libhydra_win.dll` compile cleanly with the same sources; document the paths in `docs/windows_installation.md`.
- **TODO [P2]:** Create a dual-architecture installer (INF + driver catalog) that bundles x86 + x64 binaries plus a `HydraInstaller.exe` for both versions.
- **TODO [P2]:** Build automation this repo (scripts/windows-build.sh) that invokes both `msbuild /p:Platform=x86` and `/p:Platform=x64`, runs `scripts/test_litex_stubs.sh`, and calls `scripts/automation_watchdog.sh` to keep TODOs in sync; add CI coverage once Windows runners are available.
- **TODO [P3]:** Document how to configure Windows Device Installation settings (driver store, disable driver signature enforcement) and capture a checklist for prepping Windows 10/11 test VMs.
  - **Effort:** 3 days
  - **Priority:** P2 - CI coverage
  - **Dependencies:** Windows driver buildable
  - **Validation:** Windows driver builds in CI
  - **Deliverable:** CI job for Windows build

---

## P3 - Low Priority macOS and Advanced Features (Future Work)

### macOS Kernel Extension (kext) or DriverKit
- **TODO [P3]:** Research macOS driver models (kext deprecated, DriverKit preferred)
  - **Effort:** 4 days
  - **Priority:** P3 - macOS prerequisite
  - **Dependencies:** None
  - **Validation:** Understand macOS driver architecture
  - **Deliverable:** macOS driver design doc

- **TODO [P3]:** Create macOS DriverKit stub for PCIe device
  - **Effort:** 8 days
  - **Priority:** P3 - macOS foundation
  - **Dependencies:** Research complete, macOS SDK
  - **Validation:** DriverKit loads on macOS, enumerates device
  - **Deliverable:** drivers/macos/HydraDriver.dext/

- **TODO [P3]:** Implement macOS user-client interface (matching Linux ioctls)
  - **Effort:** 6 days
  - **Priority:** P3 - Userspace interface
  - **Dependencies:** DriverKit stub created
  - **Validation:** Userspace can communicate with driver
  - **Deliverable:** User-client implementation

- **TODO [P3]:** Add macOS DMA support (IOMemoryDescriptor, scatter-gather)
  - **Effort:** 7 days
  - **Priority:** P3 - Performance
  - **Dependencies:** User-client working
  - **Validation:** DMA transfers work on macOS
  - **Deliverable:** DMA implementation

- **TODO [P3]:** Implement macOS interrupt handling (IOFilterInterruptEventSource)
  - **Effort:** 5 days
  - **Priority:** P3 - Interrupt delivery
  - **Dependencies:** DriverKit working
  - **Validation:** Interrupts delivered correctly
  - **Deliverable:** IRQ handlers

- **TODO [P3]:** Create macOS userspace library (libhydra for macOS)
  - **Effort:** 4 days
  - **Priority:** P3 - Userspace support
  - **Dependencies:** macOS driver functional
  - **Validation:** Userspace tools work on macOS
  - **Deliverable:** drivers/macos/libhydra_macos.dylib

- **TODO [P3]:** Test macOS driver on macOS 12+ (Monterey and later)
  - **Effort:** 3 days
  - **Priority:** P3 - Validation
  - **Dependencies:** macOS driver complete
  - **Validation:** Driver stable on recent macOS
  - **Deliverable:** macOS test pass log

- **TODO [P3]:** Handle macOS code signing and notarization
  - **Effort:** 3 days
  - **Priority:** P3 - Distribution
  - **Dependencies:** macOS driver stable
  - **Validation:** Driver installs without warnings
  - **Deliverable:** Signed and notarized driver

- **TODO [P3]:** Document macOS driver installation and usage
  - **Effort:** 2 days
  - **Priority:** P3 - User guidance
  - **Dependencies:** macOS driver stable
  - **Validation:** Users can install and use on macOS
  - **Deliverable:** docs/macos_installation.md

- **TODO [P3]:** Add macOS to CI (if macOS runner available)
  - **Effort:** 3 days
  - **Priority:** P3 - CI coverage
  - **Dependencies:** macOS driver buildable
  - **Validation:** macOS driver builds in CI
  - **Deliverable:** CI job for macOS build

### Advanced Cross-Platform Features
- **TODO [P3]:** Create unified userspace API abstraction (same API across Linux/FreeBSD/Windows/macOS)
  - **Effort:** 5 days
  - **Priority:** P3 - API consistency
  - **Dependencies:** Multiple platforms working
  - **Validation:** Same code compiles on all platforms
  - **Deliverable:** Unified libhydra API

- **TODO [P3]:** Add platform-agnostic test suite (runs on all OSes)
  - **Effort:** 4 days
  - **Priority:** P3 - Cross-platform testing
  - **Dependencies:** Unified API
  - **Validation:** Test suite passes on all platforms
  - **Deliverable:** Cross-platform test harness

---

## Platform Status Matrix

| Platform | Kernel Driver | Userspace Lib | Tools | Status | Priority |
|----------|---------------|---------------|-------|--------|----------|
| **Linux** | ✅ Complete | ✅ Complete | ✅ Complete | Production | P0 (0.0.7) |
| **FreeBSD** | 🟡 Basic | 🟡 Partial | 🟡 Partial | Functional | P1 (0.0.7) |
| **Windows** | ❌ Not started | ❌ Not started | ❌ Not started | Planned | P2 (Post-0.0.7) |
| **macOS** | ❌ Not started | ❌ Not started | ❌ Not started | Planned | P3 (Future) |
| **Mesa** | ❌ Not started | N/A | N/A | Planned | P2 (Post-0.0.7) |

**Legend:**
- ✅ Complete and tested
- 🟡 Partial or basic implementation
- ❌ Not started or placeholder only

---

## Cross-References

**Related Work:**
- See `todo_security.md` for driver security hardening
- See `todo_testing_ci.md` for cross-platform CI
- See `todo_multiplatform_builds.md` for build system support
- See `todo_deployment_operations.md` for packaging

**Blocking Items:**
- P1 FreeBSD driver recommended for 0.0.7 (broad platform support)
- P2 Mesa/Windows are post-0.0.7 efforts (3-6 months)

---

## Notes

- **Linux driver is primary focus for 0.0.7**
- FreeBSD driver (P1) provides BSD support with moderate effort
- Windows driver (P2) is significant effort (~40 days) due to WDDM complexity
- macOS driver (P3) is lowest priority due to DriverKit learning curve
- Mesa integration (P2) enables OpenGL support on Linux

**Recommended Phasing:**
1. **0.0.7 (Now):** Linux driver hardening, FreeBSD parity
2. **0.0.8 (Next):** Mesa Gallium driver, Windows WDM stub
3. **0.1.0 (Later):** macOS DriverKit, WDDM for Windows

**Next Actions:**
1. Complete FreeBSD driver parity (P1)
2. Test FreeBSD driver on hardware (P1)
3. Research Mesa Gallium architecture (P2)
4. Plan Windows driver architecture (P2)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for cross-platform drivers
