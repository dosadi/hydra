PROJECT_ROOT := ..
RTL_DIR      := $(PROJECT_ROOT)/rtl
SIM_DIR      := $(PROJECT_ROOT)/sim

TOP_MODULE   := voxel_framebuffer_top

CXX_SRCS     := viewer_main.cpp \
				 viewer_globals.cpp \
				 viewer_input.cpp \
				 viewer_rendering.cpp \
				 viewer_backend.cpp \
				 harness_common.cpp \
				 render_instrumentation.cpp \
				 dut_wrapper.cpp \
                 platform/platform_stub.cpp \
                 platform/backend_selector.cpp \
                 platform/backend_sdl.cpp \
                 platform/backend_headless.cpp \
				 platform/backend_aalib.cpp \
                 platform/backend_gl.cpp \
                 platform/backend_vulkan.cpp \
                 platform/backend_wayland.cpp \
                 platform/backend_x11.cpp \
                 platform/backend_fbdev.cpp \
                 platform/backend_win32.cpp \
                 platform/backend_macos.cpp

ifeq ($(VNC),1)
CXX_SRCS     += platform/backend_vnc.cpp
endif
CXX_EXE      := sim_voxel

VERILATOR    ?= verilator
CXX          ?= g++
SANITIZE     ?= 0
CCACHE       ?= 0
FAST         ?= 0

SDL_CONFIG   ?= sdl2-config
SDL_CONFIG_AVAILABLE := $(shell command -v $(SDL_CONFIG) >/dev/null 2>&1 && echo 1 || echo 0)
ifeq ($(SDL_CONFIG_AVAILABLE),1)
  SDL_CFLAGS ?= $(shell $(SDL_CONFIG) --cflags)
  SDL_LIBS   ?= $(shell $(SDL_CONFIG) --libs)
else
  # If sdl2-config is unavailable (e.g., MSYS2/MinGW), allow overriding SDL_CFLAGS/SDL_LIBS via env.
  SDL_CFLAGS ?=
  SDL_LIBS   ?= -lSDL2
endif
SDL_LIBS += -lSDL2_ttf

WAYLAND      ?= 0
WAYLAND_CFLAGS ?=
WAYLAND_LIBS   ?= -lwayland-client

X11          ?= 0
X11_CFLAGS   ?=
X11_LIBS     ?= -lX11

GL           ?= 0
GL_CFLAGS    ?=
GL_LIBS      ?= -lGL

VULKAN       ?= 0
VULKAN_CFLAGS ?=
VULKAN_LIBS   ?= -lvulkan

VNC           ?= 0
VNC_CFLAGS    ?=
VNC_LIBS      ?= -lvncserver

ifeq ($(WAYLAND),1)
  EXTRA_CFLAGS += -DHYDRA_ENABLE_WAYLAND $(WAYLAND_CFLAGS)
  EXTRA_LIBS   += $(WAYLAND_LIBS)
endif

ifeq ($(X11),1)
  EXTRA_CFLAGS += -DHYDRA_ENABLE_X11 $(X11_CFLAGS)
  EXTRA_LIBS   += $(X11_LIBS)
endif

ifeq ($(GL),1)
  EXTRA_CFLAGS += -DHYDRA_ENABLE_GL $(GL_CFLAGS)
  EXTRA_LIBS   += $(GL_LIBS)
endif

ifeq ($(VULKAN),1)
  EXTRA_CFLAGS += -DHYDRA_ENABLE_VULKAN $(VULKAN_CFLAGS)
  EXTRA_LIBS   += $(VULKAN_LIBS)
endif

ifeq ($(VNC),1)
  EXTRA_CFLAGS += -DHYDRA_ENABLE_VNC $(VNC_CFLAGS)
  EXTRA_LIBS   += $(VNC_LIBS)
endif

VERILATOR_LDFLAGS := $(SDL_LIBS) $(EXTRA_LIBS) -O3
CXXFLAGS += -O3
ifeq ($(SANITIZE),1)
  EXTRA_CFLAGS += -fsanitize=address,undefined -fno-omit-frame-pointer
  VERILATOR_LDFLAGS += -fsanitize=address,undefined
endif

ifeq ($(PROFILE),1)
  EXTRA_CFLAGS += -pg
  VERILATOR_LDFLAGS += -pg
endif

VERILATOR_FLAGS := \
    -Wall --Wno-fatal \
    --Wno-WIDTHEXPAND --Wno-UNUSEDSIGNAL --Wno-UNUSEDPARAM --Wno-BLKSEQ --Wno-INITIALDLY \
    --cc $(TOP_MODULE).sv \
    --top-module $(TOP_MODULE) \
    --public-flat-rw \
    -GMAX_RAY_STEPS=32 \
    -GRAY_STEP_SHIFT=8 \
    $(if $(filter 1,$(FAST)),-O1,--inline-mult -O3 --x-assign fast --noassert --unroll-count 1024 --unroll-stmts 1024) \
    --threads $(if $(filter 1,$(FAST)),1,1) \
    --exe $(CXX_SRCS) \
    -I$(RTL_DIR)

ifeq ($(CCACHE),1)
  CXX := ccache $(CXX)
endif

all: $(CXX_EXE)

$(CXX_EXE): V$(TOP_MODULE)___024root.h
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk
	cp obj_dir/V$(TOP_MODULE) $(CXX_EXE)

V$(TOP_MODULE)___024root.h: $(RTL_DIR)/*.sv $(SIM_DIR)/$(CXX_SRCS)
	cd $(SIM_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) -CFLAGS '$(SDL_CFLAGS) $(EXTRA_CFLAGS)' -LDFLAGS '$(VERILATOR_LDFLAGS)'
	@$(VERILATOR) --version | head -n1 > obj_dir/.verilator_version || true

# Simple non-interactive frame test: dumps one frame and compares to golden.
TEST_BUILD_DIR := $(SIM_DIR)/build
TEST_FRAME     := $(TEST_BUILD_DIR)/frame_test.ppm
GOLDEN_FRAME   := $(SIM_DIR)/tests/golden_frame.ppm

.PHONY: test_frame smoke quick purge_obj_dir lint bench
# Unit test: AXI WRAP
.PHONY: test_axi_wrap
test_axi_wrap:
	@echo "Running AXI WRAP unit test"
	@cd tests && bash ./run_axi_wrap_test.sh
test_frame: $(CXX_EXE)
	@mkdir -p $(TEST_BUILD_DIR)
	@rm -f $(TEST_FRAME) $(TEST_BUILD_DIR)/frame_diff.log
	cd $(SIM_DIR) && FRAME_DUMP="build/frame_test.ppm" AUTO_EXIT=1 ./$(CXX_EXE) >/dev/null 2>&1 || true
	@cd $(PROJECT_ROOT) && { \
		python3 scripts/check_frame.py sim/tests/golden_frame.ppm sim/build/frame_test.ppm > sim/build/frame_diff.log 2>&1; \
		status=$$?; \
		cat sim/build/frame_diff.log; \
		exit $$status; \
	}

# Minimal build without optional backends; identical to default but handy for CI/debug messaging.
smoke: $(CXX_EXE)
	@echo "sim_voxel smoke build complete (no optional backends)"

# Rebuild C++ harness only (skip re-Verilating). Requires existing obj_dir from a prior full build.
quick:
	@test -f obj_dir/V$(TOP_MODULE).mk || { echo "quick build requires existing obj_dir (run 'make' first)"; exit 1; }
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk
	cp obj_dir/V$(TOP_MODULE) $(CXX_EXE)

# Remove obj_dir if Verilator version changed (avoids stale builds).
purge_obj_dir:
	@$(PROJECT_ROOT)/scripts/purge_obj_dir.sh

# Lint RTL and C++ harness (best-effort clang-tidy).
lint:
	@echo "[lint] Verilator lint on RTL..."
	@$(VERILATOR) -Wall --Wno-fatal --Wno-PINCONNECTEMPTY --Wno-MULTITOP --lint-only --top-module voxel_sim_harness -I$(RTL_DIR) $(shell find $(RTL_DIR) -name '*.sv' ! -name 'crossbar_*.sv' ! -name 'ucie_*.sv' ! -path '*/ip_cores/*' ! -path '*/deprecated/*')
	@if command -v clang-tidy >/dev/null 2>&1; then \
		echo "[lint] clang-tidy on sim C++ sources..."; \
		clang-tidy $(CXX_SRCS) -- $(SDL_CFLAGS) $(EXTRA_CFLAGS) -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd || exit $$?; \
	else \
		echo "[lint] clang-tidy not found; skipping C++ lint."; \
	fi

# Simple benchmark: run one AUTO_EXIT frame with LOG_FRAMES=1.
bench: $(CXX_EXE)
	@echo "[bench] Running sim_voxel with LOG_FRAMES=1 AUTO_EXIT=1"
	cd $(SIM_DIR) && LOG_FRAMES=1 AUTO_EXIT=1 ./$(CXX_EXE) >/dev/null 2>&1 || true

# Unit test for pixel96_to_argb conversion function
test_pixel96:
	@echo "[test] Building and running test_pixel96"
	$(CXX) -o tests/test_pixel96 tests/test_pixel96.cpp -std=c++11
	./tests/test_pixel96
	@echo "[test] test_pixel96 PASSED"

clean:
	rm -f tests/test_pixel96
	rm -rf obj_dir $(CXX_EXE) $(TEST_BUILD_DIR)

.PHONY: all clean test_frame test_pixel96 help smoke quick purge_obj_dir lint bench

help:
	@echo "Sim Build System - Available Targets:"
	@echo ""
	@echo "  make all        - Build Verilator sim (default)"
	@echo "  make FAST=1     - Build with reduced optimization for faster compilation"
	@echo "  make test_frame - Build sim and run frame regression test"
	@echo "  make test_pixel96 - Build and run pixel96_to_argb unit test"
	@echo "  make smoke      - Build sim with minimal defaults (no optional backends)"
	@echo "  make quick      - Rebuild C++ harness only (requires existing obj_dir)"
	@echo "  make purge_obj_dir - Delete obj_dir if Verilator version changed"
	@echo "  make clean      - Remove build artifacts"
	@echo ""
	@echo "Optional backend flags (build time):"
	@echo "  make GL=1       - Enable OpenGL backend"
	@echo "  make X11=1      - Enable X11 backend"
	@echo "  make WAYLAND=1  - Enable Wayland backend"
	@echo "  make VULKAN=1   - Enable Vulkan backend"
	@echo "  make VNC=1      - Enable VNC backend"
	@echo ""
	@echo "Runtime environment variables:"
	@echo "  HYDRA_BACKEND=<SDL|GL|X11|WAYLAND|VULKAN|FBDEV|WIN32|MACOS|VNC>"
	@echo "  LOG_FRAMES=1    - Print per-frame stats"
	@echo "  LOG_KEYS=1      - Print keyboard events"
	@echo "  FRAME_DUMP=file.ppm AUTO_EXIT=1 - Non-interactive frame dump"
	@echo "  HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=N - Numbered frame dumps"
	@echo "  HYDRA_CAM_POS=x,y,z HYDRA_CAM_ANG=yaw,pitch - Set initial camera"
	@echo "  HYDRA_MOVE_SPEED, HYDRA_MOUSE_SENS, HYDRA_FPS_TARGET, HYDRA_CLEAR_COLOR, HYDRA_FONT, HYDRA_FONT_SCALE"
