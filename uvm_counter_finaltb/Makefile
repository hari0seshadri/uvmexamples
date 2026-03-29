#==============================================================================
# Makefile — counter_uvm_lab12
#
# Build and run the Lab12 counter UVM testbench under QuestaSim.
#
# TESTS
# -----
# Three tests are available, selected via the TEST variable:
#
#   make TEST=counter_test           → directed test (6 corner-case transactions)
#   make TEST=counter_random_test    → random test   (factory override to random)
#   make TEST=counter_virtual_test   → virtual sequence test (directed + random)
#
# If TEST is not specified on the command line, it defaults to counter_test.
#
# USAGE
#   make questa_gui   TEST=counter_test          # compile + run in GUI
#   make questa_batch TEST=counter_random_test   # compile + run in batch mode
#   make clean                                   # remove intermediate files
#   make tar                                     # create tar archive
#   make help                                    # print this help
#
# UVM PATHS
#   UVM_HOME         : path to UVM-1.2 source (standard UVM)
#   QUESTA_UVM_HOME  : path to Questa-specific UVM package (debug support)
#==============================================================================

UVM_HOME        = $(MGLS_HOME)/verilog_src/uvm-1.2
QUESTA_UVM_HOME = $(MGLS_HOME)/verilog_src/questa_uvm_pkg-1.2

#------------------------------------------------------------------------------
# RTL and testbench source files
#------------------------------------------------------------------------------
SRC_RTL = counter.sv

# Compile-time file list (order matters: pkg before interface before top)
VERILOG_FILES = counter_pkg.sv \
                counter_if.sv  \
                $(SRC_RTL)     \
                counter_tb_top.sv

# UVM library flags
UVM_FILES       = +incdir+$(UVM_HOME)/src \
                  +define+UVM_NO_DEPRECATED \
                  +define+QUESTA \
                  $(UVM_HOME)/src/uvm.sv

# Questa debug/coverage extras
UVM_DEBUG_FILES = +incdir+$(QUESTA_UVM_HOME)/src \
                  $(QUESTA_UVM_HOME)/src/questa_uvm_pkg.sv \
                  $(UVM_HOME)/src/dpi/uvm_dpi.cc \
                  -ccflags "-DQUESTA"

UVM_DEBUG_OPTION = -classdebug -msgmode both -uvmcontrol=all

TOPLEVEL = counter_tb_top

#------------------------------------------------------------------------------
# Default test — override on command line: make TEST=counter_random_test
#------------------------------------------------------------------------------
TEST ?= counter_test

#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------

help:
	@echo "============================================================"
	@echo "  counter_uvm_lab12 Makefile"
	@echo "============================================================"
	@echo "  make questa_gui   [TEST=<name>]   compile + run in GUI mode"
	@echo "  make questa_batch [TEST=<name>]   compile + run in batch mode"
	@echo "  make clean                         remove intermediate files"
	@echo "  make tar                           create tar archive"
	@echo ""
	@echo "  Available tests:"
	@echo "    counter_test         directed 6-transaction test (default)"
	@echo "    counter_random_test  factory override → random stimulus"
	@echo "    counter_virtual_test virtual sequence (directed + random)"
	@echo ""
	@echo "  Example:"
	@echo "    make questa_batch TEST=counter_random_test"
	@echo "============================================================"

# Compile and run with Questa in GUI mode
questa_gui:
	vlib work
	vmap work work
	vlog -64 +acc $(VERILOG_FILES) $(UVM_FILES) $(UVM_DEBUG_FILES)
	vsim -64 $(UVM_DEBUG_OPTION) \
	     -L $(MGLS_HOME)/uvm-1.2 \
	     +UVM_TESTNAME=$(TEST) \
	     -do run.do \
	     $(TOPLEVEL)

# Compile and run with Questa in batch mode (no GUI)
questa_batch: $(VERILOG_FILES) clean
	vlib work
	vmap work work
	vlog -64 +acc $(UVM_FILES) $(VERILOG_FILES)
	vsim -64 -c \
	     -L $(MGLS_HOME)/uvm-1.2 \
	     +UVM_TESTNAME=$(TEST) \
	     -do run.do \
	     $(TOPLEVEL)

#------------------------------------------------------------------------------
# Housekeeping
#------------------------------------------------------------------------------
DIR = $(shell basename `pwd`)

tar: clean
	cd ..; \
	tar cvf $(DIR).tar $(DIR)

clean:
	@# Questa work library and log files
	@rm -rf work transcript vsim.wlf counter_tb_top.vcd
