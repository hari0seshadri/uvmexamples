package my_testbench_pkg;
  import uvm_pkg::*;
 `include "uvm_macros.svh" // Include UVM macros
 
  `include "my_config.sv" 
 `include "my_sequences.sv"

  // The UVM sequence, transaction item, and driver are in these files:
 
  `include "my_driver.sv"
  `include "my_monitor.sv"
  `include "my_subscriber.sv"
  `include "my_agent.sv"
  `include "my_env.sv"
  `include "my_test.sv" 
  
endpackage
