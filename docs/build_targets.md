# Build Targets Reference

This document provides detailed descriptions of all available `make` targets in the Hydra project. Use `make help` for a quick overview, or refer to this document for comprehensive guidance.

## Core Build Targets

### `make all` (default)
Builds the Verilator simulation with SDL viewer. This is the primary development target.
- **Dependencies**: Verilator, SDL2, SDL2_ttf, C++ compiler
- **Output**: `sim/sim_voxel` executable
- **Use when**: Starting development, testing changes

### `make sim`
Alias for `make all`. Builds the complete Verilator+SDL simulation.
- **Time**: ~2-5 minutes on modern hardware
- **Artifacts**: `sim/obj_dir/`, `sim/sim_voxel`

### `make quick`
Rebuilds only the C++ harness without re-Verilating the RTL.
- **Prerequisites**: Existing `sim/obj_dir/` from previous `make sim`
- **Time**: ~30 seconds
- **Use when**: Only C++ viewer code changed, not RTL

### `make smoke`
Minimal simulation build with only default backends enabled.
- **Purpose**: Fast validation, CI builds
- **Excludes**: Optional SDL backends, extended features
- **Time**: ~1-2 minutes

### `make sanitize`
Builds simulation with AddressSanitizer and UndefinedBehaviorSanitizer.
- **Purpose**: Memory corruption detection, undefined behavior catching
- **Performance**: 2-3x slower execution
- **Use when**: Debugging crashes, memory issues

## Testing Targets

### `make test`
Runs the frame regression test suite.
- **What it does**: Builds sim, runs automated frame tests
- **Output**: Test results, PPM comparison images
- **Use when**: Validating changes don't break rendering

### `make bench`
Quick performance benchmark with frame logging.
- **Environment**: Sets `LOG_FRAMES=1 AUTO_EXIT=1`
- **Output**: Frame times printed to console
- **Use when**: Measuring rendering performance

### `make pixel-test`
Runs unit test for pixel96_to_argb conversion.
- **Location**: `sim/tests/test_pixel96.cpp`
- **Purpose**: Validates color space conversion logic

## Driver and SDK Targets

### `make driver-linux`
Builds the Linux PCIe kernel driver.
- **Prerequisites**: Linux kernel headers, kernel build environment
- **Output**: `drivers/linux/hydra.ko`
- **Use when**: Hardware testing, FPGA integration

### `make driver-freebsd`
Builds the FreeBSD PCI driver stub.
- **Prerequisites**: FreeBSD build environment
- **Output**: FreeBSD kernel module
- **Status**: Currently a placeholder/stub

### `make drivers`
Builds all drivers plus libhydra library.
- **Includes**: Linux driver, FreeBSD stub, libhydra
- **Use when**: Full hardware development setup

### `make libhydra`
Builds the userspace libhydra static library.
- **Output**: `drivers/libhydra/libhydra.a`
- **Purpose**: Userspace API for camera control, DMA, etc.
- **Use when**: Developing applications that control Hydra

### `make sdk-setup`
Builds complete SDK: libhydra + helper tools.
- **Includes**: Library, smoketests, utilities
- **Use when**: Setting up development environment

### `make blit-smoketest`
Builds user-space blit smoke test.
- **Purpose**: Validates DMA blit functionality
- **Requires**: Running driver and hardware

### `make drm-info`
Builds Hydra DRM info tool.
- **Purpose**: Queries DRM/KMS information
- **Requires**: DRM kernel support

## Hardware Testing Targets

### `make dma-negative`
Builds and runs negative DMA ioctl tests.
- **Purpose**: Validates error handling in DMA operations
- **Requires**: `/dev/hydra_pcie` device node
- **Expected**: May fail (testing error paths)

### `make cam-reset`
Resets camera, flags, and selection via libhydra.
- **Requires**: `/dev/hydra_pcie` device
- **Purpose**: Hardware state reset

### `make mmap-smoke`
Maps BAR0 and dumps ID/REV/STATUS registers.
- **Purpose**: Basic PCIe connectivity test
- **Output**: Register values to console

### `make bar1-hexdump`
Maps BAR1 and hexdumps a small memory range.
- **Purpose**: PCIe memory access validation
- **Requires**: Hardware with BAR1 configured

### `make cam-flags-demo`
Demonstrates setting camera/flags/selection via libhydra.
- **Purpose**: API usage example
- **Requires**: Hardware device

## Quality Assurance Targets

### `make lint`
Runs all linting tools on RTL and C++ code.
- **Includes**: Verilator lint, clang-tidy (if available), shellcheck, whitespace checks
- **Use when**: Code review, pre-commit validation

### `make docs` / `make docs-lint`
Runs documentation linting and link checking.
- **Checks**: Local links, formatting, TODO uniqueness
- **Use when**: Documentation changes

### `make docs-only`
Documentation-only quality checks.
- **Includes**: docs-lint + spellcheck
- **Use when**: Documentation PR validation

### `make spellcheck`
Runs codespell on documentation files.
- **Skips if**: codespell not installed
- **Use when**: Documentation review

### `make shellcheck`
Lints bash scripts with shellcheck.
- **Skips if**: shellcheck not available
- **Use when**: Script changes

### `make whitespace`
Checks for tabs and trailing whitespace in source files.
- **Covers**: SystemVerilog, C, C++ sources
- **Use when**: Code formatting validation

### `make license-check`
Verifies SPDX license headers on source files.
- **Purpose**: License compliance
- **Use when**: Adding new files

### `make verilator-check`
Ensures Verilator meets recommended version requirements.
- **Purpose**: Compatibility validation

### `make files`
Verifies all required repository files exist.
- **Purpose**: Repository integrity check

### `make todo-unique`
Ensures no duplicate TODO entries in documentation.
- **Purpose**: TODO tracker maintenance

## Development Workflow Targets

### `make dev-loop`
Complete development cycle: build sim, run tests, build SDK.
- **Optional**: RTL/QEMU testing if available
- **Use when**: Full development iteration

### `make ip-fetch`
Fetches third-party IP cores into `third_party/`.
- **Includes**: LitePCIe, LiteDRAM, LiteX, wb2axip
- **Use when**: Initial setup or IP updates

### `make fmt`
Formats source code using available formatters.
- **Tools**: clang-format (C/C++), verible (SystemVerilog)
- **Use when**: Code formatting

### `make package`
Bundles sim binary, tests, docs into `out/hydra-package.tar.gz`.
- **Prerequisites**: Built sim (`make sim`)
- **Use when**: Distribution, deployment

### `make cmake-linux`
Configures and builds host libraries/tools using CMake.
- **Output**: `build/linux/` directory
- **Alternative**: To Make-based builds in `sim/`

## Automation and Touch System Targets

### `make touch-check-all`
Checks freshness of both documentation and build artifacts.
- **Uses**: Touch system dependency tracking
- **Purpose**: Validation before commits

### `make touch-freshen-all`
Auto-freshens Tier 1 documentation (dates, broken references).
- **Purpose**: Keep docs current automatically

### `make doc-scan`
Scans documentation dependencies for touch system.
- **Output**: Updates `docs/todo/doc_dependencies.json`

### `make doc-check`
Checks documentation freshness against dependencies.

### `make doc-freshen`
Auto-updates Tier 1 docs (dates, version numbers, etc.).

### `make doc-freshen-analyze`
Analyzes which docs are stale and why.

### `make doc-ai-prompts`
Generates AI update prompts for Tier 2 documentation.

### `make build-scan`
Scans build tree dependencies.

### `make build-check`
Checks build artifact freshness.

### `make build-freshen`
Analyzes build freshening plan.

## Automation Orchestration Targets

### `make automate-priority`
Runs comprehensive priority sector automation.
- **Covers**: Build, test, quality, docs, benchmark, security, integration sectors

### `make automate-top-level`
Full top-level automation orchestrator for project health.

### `make automate-quick`
Quick automation subset for fast feedback.

### `make automate-agents`
Agent coordination checks for multi-agent development.

### `make full-automation`
Complete automation suite: priority sectors + touch system + quality checks.

### `make ci-validate`
CI-like validation: build + test + quality + validation checks.

## Utility Targets

### `make help`
Displays this target reference with brief descriptions.

### `make env-probe`
Prints versions of all build tools and dependencies.

### `make purge-obj-dir`
Removes `sim/obj_dir/` when Verilator version changes.

### `make clean`
Cleans build artifacts (sim, drivers, tools).

### `make distclean`
Aggressive clean: removes build artifacts + generated dumps + PPMs.

## Target Dependencies

Most targets can be run independently, but some have prerequisites:

- `test` → requires `sim` to be built
- `package` → requires `sim` to be built
- Hardware testing targets → require running driver and hardware
- `quick` → requires existing `obj_dir` from `sim`

## Common Development Workflows

### New Feature Development
```bash
make sim          # Build and test
make test         # Validate no regressions
make touch-check-all  # Ensure docs/build fresh
```

### Hardware Integration
```bash
make drivers      # Build all drivers
make sdk-setup    # Build userspace tools
# Insert hardware testing commands
make dma-negative # Test error handling
```

### Documentation Updates
```bash
make docs-only    # Lint docs
make touch-freshen-all  # Auto-update dates/references
make doc-check    # Verify freshness
```

### Release Preparation
```bash
make ci-validate # Full validation
make package     # Create distribution
make docs-only   # Final doc check
```

## Troubleshooting

If targets fail, check:
1. `make env-probe` - Verify tool versions
2. `make verilator-check` - Verilator compatibility
3. `make files` - Required files present
4. Individual target prerequisites

For hardware targets, ensure:
- Kernel headers installed (Linux)
- `/dev/hydra_pcie` device exists
- Hardware is powered and configured</content>
<parameter name="filePath">/workspaces/hydra/docs/build_targets.md