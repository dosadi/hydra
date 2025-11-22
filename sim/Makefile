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
	cd $(SIM_DIR) && $(VERILATOR) $(VERILATOR_FLAGS) $(SDL_CFLAGS) $(EXTRA_CFLAGS) -LDFLAGS $(SDL_LIBS) $(EXTRA_LIBS)

clean:
	rm -rf obj_dir $(CXX_EXE)

.PHONY: all clean
