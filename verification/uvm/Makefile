# Hydra UVM Verification Makefile

# Tools
VCS ?= vcs
VSIM ?= vsim
VERILATOR ?= verilator

# Directories
VERIFICATION_DIR = .
RTL_DIR = ../../rtl
SIM_DIR = sim
WORK_DIR = $(SIM_DIR)/work

# Files
PKG_FILE = hydra_uvm_pkg.sv
TB_FILE = hydra_testbench.sv
SOURCES = $(PKG_FILE) $(TB_FILE)

# UVM options
UVM_OPTS = -ntb_opts uvm-1.2

# Default test
TEST ?= hydra_csr_test
PRODUCT_CONFIG ?= hydra_usb_product

.PHONY: all clean compile_vcs compile_modelsim compile_verilator run_vcs run_modelsim help

all: compile run

# VCS compilation and simulation
compile_vcs:
	@echo "Compiling with VCS..."
	mkdir -p $(SIM_DIR)
	$(VCS) -sverilog $(UVM_OPTS) $(SOURCES) -o $(SIM_DIR)/hydra_tb_simv

run_vcs: compile_vcs
	@echo "Running VCS simulation..."
	$(SIM_DIR)/hydra_tb_simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=MEDIUM

# ModelSim/Questa compilation and simulation
compile_modelsim:
	@echo "Compiling with ModelSim..."
	mkdir -p $(WORK_DIR)
	vlib $(WORK_DIR)
	vmap work $(WORK_DIR)
	vlog -sv $(UVM_OPTS) $(SOURCES)

run_modelsim: compile_modelsim
	@echo "Running ModelSim simulation..."
	vsim -c -do "run -all; quit" work.hydra_testbench +UVM_TESTNAME=$(TEST)

# Verilator syntax check only
compile_verilator:
	@echo "Checking syntax with Verilator..."
	$(VERILATOR) --lint-only -sv $(UVM_OPTS) $(SOURCES)

# Auto-detect available simulator
compile:
	@if command -v $(VCS) >/dev/null 2>&1; then \
		$(MAKE) compile_vcs; \
	elif command -v $(VSIM) >/dev/null 2>&1; then \
		$(MAKE) compile_modelsim; \
	else \
		$(MAKE) compile_verilator; \
	fi

run:
	@if command -v $(VCS) >/dev/null 2>&1; then \
		$(MAKE) run_vcs; \
	elif command -v $(VSIM) >/dev/null 2>&1; then \
		$(MAKE) run_modelsim; \
	else \
		echo "No full simulator found. Use 'make compile_verilator' for syntax check."; \
	fi

# Test targets
test_csr:
	$(MAKE) run TEST=hydra_csr_test

test_dma:
	$(MAKE) run TEST=hydra_dma_test

test_blit:
	$(MAKE) run TEST=hydra_blit_test

test_integration:
	$(MAKE) run TEST=hydra_integration_test

# Product-specific tests
test_usb_product:
	$(MAKE) run TEST=hydra_config_test PRODUCT_CONFIG=hydra_usb_product

test_hdmi_product:
	$(MAKE) run TEST=hydra_config_test PRODUCT_CONFIG=hydra_hdmi_product

test_enterprise_product:
	$(MAKE) run TEST=hydra_config_test PRODUCT_CONFIG=hydra_enterprise_product

# Clean up
clean:
	rm -rf $(SIM_DIR)
	rm -f *.vcd
	rm -f *.log

# Help
help:
	@echo "Hydra UVM Verification Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  compile          - Compile using available simulator"
	@echo "  run              - Run simulation using available simulator"
	@echo "  compile_vcs      - Compile with VCS"
	@echo "  run_vcs          - Run with VCS"
	@echo "  compile_modelsim - Compile with ModelSim/Questa"
	@echo "  run_modelsim     - Run with ModelSim/Questa"
	@echo "  compile_verilator- Syntax check with Verilator"
	@echo "  test_csr         - Run CSR tests"
	@echo "  test_dma         - Run DMA tests"
	@echo "  test_blit        - Run blitter tests"
	@echo "  test_integration - Run integration tests"
	@echo "  clean            - Clean simulation files"
	@echo ""
	@echo "Variables:"
	@echo "  TEST=<testname>  - Specify test to run (default: hydra_csr_test)"
	@echo "  VCS=<path>       - Path to VCS executable"
	@echo "  VSIM=<path>      - Path to vsim executable"