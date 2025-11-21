PROJECT_ROOT := ..
RTL_DIR      := $(PROJECT_ROOT)/rtl
SIM_DIR      := $(PROJECT_ROOT)/sim

TOP_MODULE   := voxel_framebuffer_top

CXX_SRCS     := live_sdl_main.cpp
CXX_EXE      := sim_voxel

VERILATOR    ?= verilator
CXX          ?= g++

SDL_CFLAGS   ?= $(shell sdl2-config --cflags)
SDL_LIBS     ?= $(shell sdl2-config --libs) -LDFLAGS -lSDL2_ttf


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
