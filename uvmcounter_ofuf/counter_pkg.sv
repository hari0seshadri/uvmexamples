//=============================================================================
// counter_pkg.sv
//
// Package that acts as the single compilation unit for the entire UVM
// testbench.  Everything the TB needs — types, parameters, and all UVM
// component classes — is declared here so that any file that does
//   import counter_pkg::*;
// instantly gets access to the full testbench namespace.
//
// Compile order inside the package (matters for forward references):
//   1. counter_transaction  – sequence item (leaf, no TB dependencies)
//   2. counter_driver       – drives DUT via interface tasks
//   3. counter_monitor      – observes DUT outputs passively
//   4. counter_agent        – bundles driver + monitor + sequencer
//   5. counter_env          – top-level TB environment (contains agent)
//   6. counter_test         – UVM test + sequence (uses all of the above)
//=============================================================================
package counter_pkg;
  import uvm_pkg::*;          // bring in all UVM base classes
  `include "uvm_macros.svh"   // `uvm_info, `uvm_fatal, `uvm_component_utils, ...

  //--------------------------------------------------------------------------
  // Shared types
  //--------------------------------------------------------------------------

  // Encoding of the counter's four operating modes (drives the mode port).
  typedef enum logic [1:0] {
    MODE_HOLD      = 2'b00,   // hold current value
    MODE_COUNT_UP  = 2'b01,   // increment by 1 each clock
    MODE_COUNT_DN  = 2'b10,   // decrement by 1 each clock
    MODE_LOAD      = 2'b11    // parallel-load from load_data
  } counter_mode_t;

  //--------------------------------------------------------------------------
  // Shared parameters
  //--------------------------------------------------------------------------
  parameter int COUNTER_WIDTH = 8;            // DUT data-path width (bits)
  parameter int COUNTER_MAX   = 255;          // maximum count value (2^WIDTH - 1)

  //--------------------------------------------------------------------------
  // Enumeration used in counter_transaction to select the test stimulus type.
  //--------------------------------------------------------------------------
  typedef enum {
    TEST_RESET,        // assert reset and release
    TEST_LOAD,         // load a specific value
    TEST_COUNT_UP,     // count up for N cycles from a start value
    TEST_COUNT_DOWN,   // count down for N cycles from a start value
    TEST_OVERFLOW,     // count up from MAX to trigger overflow flag
    TEST_UNDERFLOW     // count down from 0 to trigger underflow flag
  } test_type_t;

  //--------------------------------------------------------------------------
  // Include all UVM component files.
  // Each file is compiled in the context of counter_pkg, so the types and
  // parameters declared above are directly visible inside those files.
  //--------------------------------------------------------------------------
  `include "counter_transaction.sv"
  `include "counter_driver.sv"
  `include "counter_monitor.sv"
  `include "counter_agent.sv"
  `include "counter_env.sv"
  `include "counter_test.sv"

endpackage
