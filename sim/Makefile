PROJECT_ROOT := ..
RTL_DIR      := $(PROJECT_ROOT)/rtl
SIM_DIR      := $(PROJECT_ROOT)/sim

TOP_MODULE   := voxel_framebuffer_top

CXX_SRCS     := live_sdl_main.cpp \
                 platform/platform_stub.cpp \
                 platform/backend_selector.cpp \
                 platform/backend_sdl.cpp \
                 platform/backend_gl.cpp \
                 platform/backend_vulkan.cpp \
                 platform/backend_wayland.cpp \
                 platform/backend_x11.cpp \
                 platform/backend_fbdev.cpp \
                 platform/backend_win32.cpp \
                 platform/backend_macos.cpp
CXX_EXE      := sim_voxel

VERILATOR    ?= verilator
CXX          ?= g++

SDL_CONFIG   ?= sdl2-config
# If sdl2-config is unavailable (e.g., MSYS2/MinGW), allow overriding SDL_CFLAGS/SDL_LIBS via env.
SDL_CFLAGS   ?= $(shell which $(SDL_CONFIG) >/dev/null 2>&1 && $(SDL_CONFIG) --cflags)
SDL_LIBS     ?= $(shell which $(SDL_CONFIG) >/dev/null 2>&1 && $(SDL_CONFIG) --libs) -LDFLAGS -lSDL2_ttf


VERILATOR_FLAGS := \
    -Wall --Wno-fatal --trace \
    --Wno-WIDTHEXPAND --Wno-UNUSEDSIGNAL --Wno-UNUSEDPARAM --Wno-BLKSEQ --Wno-INITIALDLY \
    --cc $(TOP_MODULE).sv \
    --top-module $(TOP_MODULE) \
    -O3 --exe $(CXX_SRCS) \
    -I$(RTL_DIR)

all: $(CXX_EXE)

$(CXX_EXE): V$(TOP_MODULE)___024root.h
	$(MAKE) -C obj_dir -f V$(TOP_MODULE).mk
	cp obj_dir/V$(TOP_MODULE) $(CXX_EXE)

V$(TOP_MODULE)___024root.h: $(RTL_DIR)/*.sv $(SIM_DIR)/$(CXX_SRCS)
	cd $(SIM_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) $(SDL_CFLAGS) -LDFLAGS $(SDL_LIBS)

clean:
	rm -rf obj_dir $(CXX_EXE)

.PHONY: all clean
