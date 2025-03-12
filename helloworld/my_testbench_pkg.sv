package my_testbench_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh" // Include UVM macros
  
  // The UVM sequence, transaction item, and driver are in these files:
  `include "my_sequence.sv"
  `include "my_driver.sv"
  `include "my_agent.sv"
  `include "my_env.sv"
  `include "my_test.sv" 
  
endpackage
