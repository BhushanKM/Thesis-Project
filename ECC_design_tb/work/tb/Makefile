#================================================================================
# ECC UVM Testbench Makefile
# RS16(19,17) ECC Engine for HBM3/HBM4
#================================================================================

# Simulator selection: vcs, questa, xcelium
SIM ?= vcs

# Test selection
TEST ?= ecc_sanity_test

# Verbosity: UVM_NONE, UVM_LOW, UVM_MEDIUM, UVM_HIGH, UVM_FULL
VERBOSITY ?= UVM_MEDIUM

# Design files
RTL_DIR = ../Design
RTL_FILES = $(RTL_DIR)/gf_mul_16.v \
            $(RTL_DIR)/ecc_encoder.v \
            $(RTL_DIR)/ecc_decoder.v \
            $(RTL_DIR)/ecc_engine_top.v

# Testbench files
TB_DIR = .
TB_FILES = $(TB_DIR)/ecc_pkg.sv \
           $(TB_DIR)/ecc_top.sv

# Include directories
INC_DIRS = +incdir+$(TB_DIR) +incdir+$(RTL_DIR)

#================================================================================
# VCS
#================================================================================
VCS_OPTS = -full64 -sverilog -ntb_opts uvm-1.2 \
           -timescale=1ns/1ps \
           +vcs+lic+wait \
           -debug_access+all \
           $(INC_DIRS)

vcs: compile_vcs run_vcs

compile_vcs:
	vcs $(VCS_OPTS) $(RTL_FILES) $(TB_FILES) -o simv

run_vcs:
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)

#================================================================================
# Questa/ModelSim
#================================================================================
QUESTA_OPTS = -sv +acc \
              $(INC_DIRS)

questa: compile_questa run_questa

compile_questa:
	vlib work
	vlog $(QUESTA_OPTS) $(RTL_FILES) $(TB_FILES)

run_questa:
	vsim -c ecc_top +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) -do "run -all; quit"

#================================================================================
# Xcelium
#================================================================================
XRUN_OPTS = -sv -uvm -uvmhome CDNS-1.2 \
            -timescale 1ns/1ps \
            $(INC_DIRS)

xcelium: 
	xrun $(XRUN_OPTS) $(RTL_FILES) $(TB_FILES) \
		+UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)

#================================================================================
# Test Targets
#================================================================================
sanity:
	$(MAKE) $(SIM) TEST=ecc_sanity_test

sbe:
	$(MAKE) $(SIM) TEST=ecc_sbe_test

dbe:
	$(MAKE) $(SIM) TEST=ecc_dbe_test

sse:
	$(MAKE) $(SIM) TEST=ecc_sse_test

dase:
	$(MAKE) $(SIM) TEST=ecc_dase_test

boundary:
	$(MAKE) $(SIM) TEST=ecc_boundary_test

comprehensive:
	$(MAKE) $(SIM) TEST=ecc_comprehensive_test

stress:
	$(MAKE) $(SIM) TEST=ecc_stress_test

regression:
	$(MAKE) $(SIM) TEST=ecc_regression_test

#================================================================================
# Utilities
#================================================================================
clean:
	rm -rf simv simv.daidir csrc *.log *.vpd *.vcd
	rm -rf work transcript vsim.wlf
	rm -rf xcelium.d *.history *.shm

view_waves:
	dve -vpd ecc_tb.vpd &

help:
	@echo "ECC UVM Testbench"
	@echo "================="
	@echo "Usage: make [target] [SIM=vcs|questa|xcelium] [TEST=test_name]"
	@echo ""
	@echo "Targets:"
	@echo "  sanity       - Quick functionality check"
	@echo "  sbe          - Single Bit Error exhaustive test"
	@echo "  dbe          - Double Bit Error test"
	@echo "  sse          - Single Symbol Error test"
	@echo "  dase         - Double Adjacent Symbol Error test"
	@echo "  boundary     - Boundary pattern test"
	@echo "  comprehensive - All error types"
	@echo "  stress       - Back-to-back stress test"
	@echo "  regression   - Full regression suite"
	@echo "  clean        - Clean generated files"
	@echo ""
	@echo "Available Tests:"
	@echo "  ecc_sanity_test, ecc_sbe_test, ecc_dbe_test, ecc_sse_test,"
	@echo "  ecc_dase_test, ecc_boundary_test, ecc_comprehensive_test,"
	@echo "  ecc_stress_test, ecc_test_mode_test, ecc_regression_test"

.PHONY: vcs questa xcelium compile_vcs run_vcs compile_questa run_questa
.PHONY: sanity sbe dbe sse dase boundary comprehensive stress regression
.PHONY: clean view_waves help
