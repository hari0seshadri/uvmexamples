UVM_HOME=$(MGLS_HOME)/verilog_src/uvm-1.2
QUESTA_UVM_HOME= $(MGLS_HOME)/verilog_src/questa_uvm_pkg-1.2
VERILOG_FILES = adder.sv adder_interface.sv adder_pkg.sv testbench.sv
UVM_FILES =  +incdir+${UVM_HOME}/src +define+UVM_NO_DEPRECATED +define+QUESTA ${UVM_HOME}/src/uvm.sv
UVM_DEBUG_FILES = +incdir+${QUESTA_UVM_HOME}/src ${QUESTA_UVM_HOME}/src/questa_uvm_pkg.sv ${UVM_HOME}/src/dpi/uvm_dpi.cc -ccflags "-DQUESTA"
UVM_DEBUG_OPTION = -classdebug -msgmode both -uvmcontrol=all 
TOPLEVEL = top

help:
	@echo "Make targets:"
	@echo "> make questa_gui   	# Compile and run with Questa in GUI mode"
	@echo "> make questa_batch 	# Compile and run with Questa in batch mode"
	@echo "> make clean        	# Clean up all intermediate files"
	@echo "> make tar          	# Create a tar file for the current directory"
	@echo "> make help         	# This message"

# Questa section
questa_gui: 
	vlib work
	vmap work work
	vlog -64 +acc ${VERILOG_FILES} ${UVM_FILES} ${UVM_DEBUG_FILES} 
	vsim -64 ${UVM_DEBUG_OPTION} -L $(MGLS_HOME)/uvm-1.2 -do run.do ${TOPLEVEL}

questa_batch:  ${VERILOG_FILES} clean
	vlib work
	vmap work work
	vlog -64 +acc ${UVM_FILES} ${VERILOG_FILES}
	vsim -64 -c -L $(MGLS_HOME)/uvm-1.2 -do run.do ${TOPLEVEL}

#############################################################################
# Housekeeping

DIR = $(shell basename `pwd`)

tar:	clean
	cd ..; \
	tar cvf ${DIR}.tar ${DIR}

clean:
	@# Questa stuff
	@rm -rf work transcript vsim.wlf
