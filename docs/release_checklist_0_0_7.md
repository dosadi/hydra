# Hydra 0.0.7 Release Checklist

**Release Version:** 0.0.7
**Release Date:** [Target Date]
**Release Manager:** [Your Name]
**Previous Release:** 0.0.6 (October 2025)

## Overview

This checklist ensures all critical release gates are met before publishing Hydra 0.0.7. The release focuses on RTL hardening, visual quality improvements, and enhanced developer experience.

## Pre-Release Preparation

### Code Freeze & Branching
- [ ] Create release branch: `git checkout -b release/0.0.7`
- [ ] Update version numbers in all relevant files
- [ ] Freeze feature branches (no new commits to main)
- [ ] Notify team of code freeze

### Version Updates Required
- [ ] `CMakeLists.txt`: Update `PROJECT_VERSION` to 0.0.7
- [ ] `rtl/voxel_axil_csr.sv`: Update version register default
- [ ] `drivers/linux/hydra.h`: Update version macros
- [ ] `docs/hydra_spec.md`: Update revision number
- [ ] `README.md`: Update version badges and compatibility notes
- [ ] `RELEASE_NOTES_0.0.7.md`: Finalize release notes

## Testing & Validation

### Core Functionality Tests
- [ ] **test_frame passes**: `./sim/sim_voxel` runs without crashes for 100+ frames
- [ ] **Basic rendering**: All render modes work (solid, wireframe, points)
- [ ] **Camera controls**: WASD movement, mouse look, zoom functions
- [ ] **Voxel editing**: Place, erase, select operations work
- [ ] **Hotkeys**: All documented hotkeys functional (F4, T, Y, J, etc.)

### RTL Validation
- [ ] **Verilator compilation**: `make` completes without errors
- [ ] **Cocotb tests**: `cd sim/tests/cocotb_hydra && make SIM=icarus` passes
- [ ] **Waveform generation**: VCD files generated for debugging
- [ ] **CSR functionality**: All control/status registers accessible
- [ ] **AXI-Stream**: Pixel stream backpressure handling verified

### Driver Testing
- [ ] **Linux driver compilation**: `cd drivers/linux && make` succeeds
- [ ] **Module loading**: `sudo insmod hydra.ko` works without errors
- [ ] **Device enumeration**: `lspci | grep Hydra` shows device
- [ ] **Basic IOCTLs**: Camera control, rendering commands work
- [ ] **Interrupt handling**: Frame completion interrupts functional
- [ ] **Memory mapping**: BAR0/BAR1 regions accessible

### Cross-Platform Testing
- [ ] **Ubuntu 20.04+**: Full test suite passes
- [ ] **FreeBSD**: Driver stub loads (parity documented)
- [ ] **Cross-compilation**: aarch64 build succeeds
- [ ] **WebAssembly**: Emscripten build generates valid output

### Performance Benchmarks
- [ ] **Frame rate**: Maintains 30+ FPS on reference hardware
- [ ] **Memory usage**: Under 500MB resident memory
- [ ] **CPU utilization**: Under 50% on quad-core system
- [ ] **Load times**: Application starts within 5 seconds

## Documentation & Legal

### Documentation Completeness
- [ ] **hydra_spec.md**: Updated with 0.0.7 register map and defaults
- [ ] **Release notes**: `RELEASE_NOTES_0.0.7.md` complete and accurate
- [ ] **API documentation**: Doxygen docs generated and current
- [ ] **Build guides**: All build methods documented and tested
- [ ] **Troubleshooting**: Common issues documented with solutions

### Legal & Compliance
- [ ] **License headers**: All source files have correct copyright notices
- [ ] **Third-party credits**: Vendored code properly attributed
- [ ] **Export controls**: No restricted technology included
- [ ] **Security review**: No known vulnerabilities in release

## Quality Assurance

### Code Quality Gates
- [ ] **Static analysis**: No critical issues from clang-tidy/cppcheck
- [ ] **Memory safety**: Valgrind clean (no leaks, no invalid accesses)
- [ ] **Thread safety**: Race condition analysis complete
- [ ] **Code coverage**: Core functionality >80% coverage
- [ ] **Compiler warnings**: Zero warnings on all supported compilers

### Integration Testing
- [ ] **SoC integration**: LiteX integration example works
- [ ] **DMA functionality**: Memory transfers working correctly
- [ ] **PCIe compliance**: Basic enumeration and configuration
- [ ] **HDMI output**: Video signal generation verified (if applicable)

## Release Artifacts

### Build Artifacts
- [ ] **Source tarball**: `hydra-0.0.7.tar.gz` created and tested
- [ ] **Debian packages**: .deb files generated for Ubuntu
- [ ] **Docker images**: Build and runtime images available
- [ ] **Cross-compiled binaries**: ARM64 binaries available

### Documentation Artifacts
- [ ] **HTML documentation**: Generated from Markdown sources
- [ ] **PDF manual**: Single-file documentation for offline use
- [ ] **API reference**: Doxygen HTML output
- [ ] **Installation guide**: Step-by-step setup instructions

## Distribution & Deployment

### Repository Management
- [ ] **Git tags**: `git tag -a v0.0.7 -m "Release 0.0.7"` created
- [ ] **GitHub release**: Draft release created with artifacts
- [ ] **Branch protection**: Release branch protected from force pushes
- [ ] **Archive branches**: Feature branches merged and cleaned up

### Package Distribution
- [ ] **GitHub Releases**: All artifacts uploaded and verified
- [ ] **Package repositories**: Debian/Ubuntu packages uploaded
- [ ] **Docker Hub**: Images pushed with correct tags
- [ ] **Homebrew**: Formula updated (if applicable)

### Announcement Preparation
- [ ] **Release notes**: Formatted for GitHub release
- [ ] **Changelog**: Summary of changes since 0.0.6
- [ ] **Migration guide**: Breaking changes documented
- [ ] **Known issues**: Outstanding bugs listed with workarounds

## Post-Release Activities

### Monitoring & Support
- [ ] **CI/CD**: Release branch pipelines passing
- [ ] **Issue tracking**: Release-specific labels created
- [ ] **Community notification**: Release announced on relevant channels
- [ ] **Support channels**: Documentation of support availability

### Follow-up Tasks
- [ ] **Hotfix branch**: `release/0.0.7-hotfixes` created
- [ ] **Next version planning**: 0.0.8 milestone created
- [ ] **Feedback collection**: User feedback mechanisms in place
- [ ] **Security monitoring**: Vulnerability reporting process active

## Rollback Plan

### Emergency Procedures
- [ ] **Tag reversion**: Ability to revert release tag if critical issues found
- [ ] **Package removal**: Process to remove packages from distribution channels
- [ ] **Communication**: Plan for notifying users of issues and fixes
- [ ] **Hotfix process**: Procedure for releasing patched versions

## Sign-off Checklist

### Release Manager Verification
- [ ] All checklist items completed or properly documented exceptions
- [ ] Critical path items (testing, documentation) verified personally
- [ ] Cross-functional review completed (engineering, QA, documentation)
- [ ] Business approval obtained (if required)
- [ ] Legal review completed (if required)

### Final Release Steps
- [ ] GitHub release published
- [ ] Release announcement sent
- [ ] Release branch merged back to main (if appropriate)
- [ ] Post-mortem meeting scheduled for lessons learned

---

## Release Notes Template

```markdown
# Hydra 0.0.7 Release Notes

## Overview
Hydra 0.0.7 focuses on RTL hardening, visual quality improvements, and enhanced developer experience.

## New Features
- Enhanced rendering pipeline with improved visual quality
- Expanded hotkey support for voxel editing
- Improved driver stability and error handling
- Cross-platform build support (ARM64, RISC-V)

## Bug Fixes
- Fixed camera control issues in certain configurations
- Resolved memory leaks in long-running sessions
- Corrected AXI-Stream backpressure handling
- Fixed build issues on newer compiler versions

## Technical Improvements
- Hardened RTL implementation with additional assertions
- Improved test coverage across all components
- Enhanced documentation with new guides and references
- Performance optimizations for better frame rates

## Breaking Changes
- Updated CSR register map (see migration guide)
- Modified driver API for better error reporting

## Known Issues
- WebAssembly demo has limited feature set
- Some advanced rendering features require specific hardware

## Installation
See [Installation Guide](docs/installation.md) for detailed setup instructions.

## Migration Guide
For upgrading from 0.0.6, see [Migration Guide](docs/migration_0.0.7.md).
```

---

**Checklist Version:** 1.0
**Created:** 2025-11-28
**Last Updated:** 2025-11-28
**Status:** Ready for 0.0.7 release process