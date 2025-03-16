
package adder_pkg;
  import uvm_pkg::*; // Import UVM library
  `include "uvm_macros.svh" // Include UVM macros

  `include "adder_sequence_item.sv"
  `include "adder_driver.sv"
//  `include "adder_sequencer.sv"
  `include "adder_monitor.sv"
  `include "adder_agent.sv"
  `include "adder_scoreboard.sv"
  `include "adder_env.sv"
  `include "adder_sequence.sv"
 `include "random_test.sv"

endpackage
