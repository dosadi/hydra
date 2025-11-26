# Top-level convenience targets (does not auto-build drivers by default)

.PHONY: all sim test driver-linux driver-freebsd drivers backends blit-smoketest libhydra drm-info clean distclean sdk-setup dev-loop ip-fetch help cmake-linux quick smoke sanitize purge-obj-dir env-probe shellcheck whitespace docs docs-lint docs-only diff-summary fmt package lint verilator-check files todo-unique bench spellcheck license-check pixel-test dma-negative cam-reset mmap-smoke cam-flags-demo bar1-hexdump backend-probe

all: sim

# Display available targets
help:
	@echo "Hydra Build System - Available Targets:"
	@echo ""
	@echo "  make all           - Build Verilator sim (default)"
	@echo "  make sim           - Build Verilator+SDL sim"
	@echo "  make test          - Run frame regression test"
	@echo "  make quick         - Rebuild sim C++ harness only (no re-Verilate; requires existing obj_dir)"
	@echo "  make smoke         - Minimal sim build (default backends only)"
	@echo "  make sanitize      - Build sim with ASan/UBSan enabled"
	@echo "  make purge-obj-dir - Drop sim/obj_dir when Verilator version changes"
	@echo "  make env-probe     - Print tool versions (verilator/gcc/sdl2-config/etc.)"
	@echo "  make shellcheck    - Lint bash scripts if shellcheck is available"
	@echo "  make whitespace    - Check for tabs/trailing whitespace in SV/C/C++ sources"
	@echo "  make docs          - Run docs lint (local link check)"
	@echo "  make docs-lint     - Same as docs (kept for clarity)"
	@echo "  make docs-only     - Docs-only pass (docs-lint + spellcheck)"
	@echo "  make diff-summary  - Summarize git diff stats and TODO touches (for PRs)"
	@echo "  make fmt           - Format C/C++/SV sources (clang-format/verible if available)"
	@echo "  make package       - Bundle sim binary/tests/docs into out/hydra-package.tar.gz"
	@echo "  make lint          - Lint RTL and sim C++ (verilator --lint-only, clang-tidy if available)"
	@echo "  make verilator-check - Ensure Verilator meets recommended major version"
	@echo "  make files         - Verify required repo files exist"
	@echo "  make todo-unique   - Ensure docs/toodo/todo_master.md has no duplicate TODO entries"
	@echo "  make bench         - Quick sim benchmark (LOG_FRAMES=1 AUTO_EXIT=1)"
	@echo "  make spellcheck    - Run codespell on docs (skips if tool missing)"
	@echo "  make license-check - Verify SPDX headers on source files"
	@echo "  make pixel-test    - Run pixel96_to_argb unit test (sim/tests/test_pixel96.cpp)"
	@echo "  make dma-negative  - Build/run negative DMA ioctl test (expects driver node)"
	@echo "  make cam-reset     - Reset camera/flags/selection via libhydra (uses /dev/hydra_pcie)"
	@echo "  make mmap-smoke    - Map BAR0 and dump ID/REV/STATUS (skips if missing)"
	@echo "  make bar1-hexdump  - Map BAR1 and hexdump a small range (skips if missing)"
	@echo "  make cam-flags-demo- Sample: set camera/flags/selection via libhydra"
	@echo "  make backend-probe - Probe SDL backends (best effort; skips if SDL missing)"
	@echo "  make dev-loop      - Full dev cycle (sim + test + SDK + optional RTL/QEMU)"
	@echo "  make ip-fetch      - Fetch third-party IP (LitePCIe/LiteDRAM/LiteX)"
	@echo "  make bsd-kmod      - Build FreeBSD hydra kmod (drivers/bsd/Makefile.kmod)"
	@echo ""
	@echo "  make libhydra      - Build libhydra.a static library"
	@echo "  make blit-smoketest- Build user blit smoke test"
	@echo "  make drm-info      - Build Hydra DRM info tool"
	@echo "  make sdk-setup     - Build all SDK tools (libhydra + smoketests)"
	@echo ""
	@echo "  make driver-linux  - Build Linux PCIe driver (requires kernel headers)"
	@echo "  make driver-freebsd- Build FreeBSD PCI driver stub"
	@echo "  make drivers       - Build all drivers + libhydra"
	@echo "  make cmake-linux   - Configure + build host libs/tools via CMake preset"
	@echo ""
	@echo "  make clean         - Clean build artifacts"
	@echo "  make distclean     - Clean plus generated dumps/PPMs/objs (aggressive)"
	@echo ""
	@echo "For detailed instructions, see README.md and docs/testing_overview.md"

# Run frame regression test
test:
	@$(MAKE) -C sim test_frame

# One-shot dev loop (mirrors CI): sim build+frame test, SDK build, optional RTL/QEMU
# Usage: make dev-loop

dev-loop:
	@./scripts/hydra_dev_loop.sh

# Fetch third-party IP cores (LitePCIe/LiteDRAM/LiteICLink/LiteX/wb2axip) into third_party/
# Usage: make ip-fetch

ip-fetch:
	@./scripts/fetch_ip.sh

sim:
	@$(MAKE) -C sim

# Rebuild sim harness quickly (no re-Verilation; requires existing obj_dir).
quick:
	@$(MAKE) -C sim quick

# Minimal sim build, no optional backends toggled.
smoke:
	@$(MAKE) -C sim smoke

# Build sim with sanitizers enabled (ASan/UBSan).
sanitize:
	@$(MAKE) -C sim SANITIZE=1

# Drop obj_dir if Verilator version changed.
purge-obj-dir:
	@$(MAKE) -C sim purge_obj_dir

# Optional: build the Linux PCIe driver stub (requires kernel headers)
driver-linux:
	@$(MAKE) -C drivers/linux -f Makefile

# Optional: FreeBSD PCI driver stub (placeholder)
driver-freebsd:
	@$(MAKE) -C drivers/bsd -f Makefile

# Build all host-side bits we have in-tree (stubs included)
drivers: libhydra driver-linux driver-freebsd

# Platform backend stubs (no-op today; keeps build knobs centralized)
backends:
	@echo "Platform backends are stubbed; nothing to build yet."

blit-smoketest:
	@echo "Building user blit smoke test"
	@gcc -I drivers/linux/uapi -O2 -o scripts/hydra_blit_smoketest scripts/hydra_blit_smoketest.c

libhydra:
	@$(MAKE) -C drivers/libhydra

drm-info:
	@echo "Building Hydra DRM info tool"
	@gcc -I drivers/linux/uapi -o scripts/hydra_drm_info scripts/hydra_drm_info.c -ldrm

sdk-setup:
	@echo "Setting up Hydra SDK (libhydra + tools)"
	@./scripts/setup_sdk.sh

env-probe:
	@./scripts/env_probe.sh

shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck..."; \
		shellcheck scripts/hydra_dev_loop.sh scripts/fetch_ip.sh scripts/purge_obj_dir.sh || exit $$?; \
	else \
		echo "shellcheck not found; skipping."; \
	fi

whitespace:
	@./scripts/check_whitespace.sh

docs docs-lint:
	@./scripts/docs_lint.py
	@./scripts/check_todo_unique.py

docs-only:
	@$(MAKE) docs
	@$(MAKE) spellcheck

diff-summary:
	@./scripts/diff_summary.sh

fmt:
	@./scripts/format_sources.sh

package:
	@test -x sim/sim_voxel || { echo "Build sim first (run 'make sim')"; exit 1; }
	@mkdir -p out
	@tar czf out/hydra-package.tar.gz sim/sim_voxel sim/tests docs README.md scripts/check_frame.py scripts/requirements.txt
	@echo "Created out/hydra-package.tar.gz"

lint:
	@$(MAKE) -C sim lint
	@$(MAKE) shellcheck
	@$(MAKE) whitespace

verilator-check:
	@./scripts/verilator_check.sh

files:
	@./scripts/check_required_files.py

todo-unique:
	@./scripts/check_todo_unique.py

bench:
	@$(MAKE) -C sim bench

bsd-kmod:
	@$(MAKE) -C drivers/bsd -f Makefile.kmod

spellcheck:
	@./scripts/spellcheck_docs.sh

license-check:
	@./scripts/check_license_headers.py

pixel-test:
	@c++ -std=c++17 -Wall -Wextra -O2 -o sim/tests/test_pixel96 sim/tests/test_pixel96.cpp
	@sim/tests/test_pixel96

dma-negative:
	@cc -Wall -Wextra -O2 -o scripts/tests/test_hydra_dma_negative scripts/tests/test_hydra_dma_negative.c
	@./scripts/tests/test_hydra_dma_negative || true

cam-reset:
	@cc -Wall -Wextra -O2 -I drivers/linux/uapi -I drivers/libhydra -o scripts/hydra_cam_reset scripts/hydra_cam_reset.c drivers/libhydra/hydra.c
	@./scripts/hydra_cam_reset || true

mmap-smoke:
	@cc -Wall -Wextra -O2 -o scripts/hydra_mmap_smoke scripts/hydra_mmap_smoke.c
	@./scripts/hydra_mmap_smoke || true

cam-flags-demo:
	@cc -Wall -Wextra -O2 -I drivers/linux/uapi -I drivers/libhydra -o scripts/hydra_cam_flags_demo scripts/hydra_cam_flags_demo.c drivers/libhydra/hydra.c
	@./scripts/hydra_cam_flags_demo || true

bar1-hexdump:
	@cc -Wall -Wextra -O2 -I drivers/linux/uapi -o scripts/hydra_bar1_hexdump scripts/hydra_bar1_hexdump.c
	@./scripts/hydra_bar1_hexdump || true

backend-probe:
	@./scripts/check_backends.sh
clean:
	@$(MAKE) -C sim clean || true
	@rm -f drivers/libhydra/libhydra.a drivers/libhydra/*.o
	@rm -f scripts/hydra_blit_smoketest scripts/hydra_dma_blit_demo scripts/hydra_drm_info
	@rm -rf build build/linux
	@rm -f drivers/linux/*.o drivers/linux/*.ko drivers/linux/*.mod.c drivers/linux/*.order drivers/linux/Module.symvers drivers/linux/modules.order

distclean: clean
	@rm -f out
	@rm -f *.vvp *.vcd
	@rm -f sim/test_*.ppm sim/*.ppm
	@rm -f sim/tests/rtl/*.vvp sim/tests/rtl/*.vcd
	@rm -rf sim/obj_dir sim/build

# Configure + build host libs/tools using the CMake preset (Linux).
cmake-linux:
	cmake --preset linux-default
	cmake --build build/linux
