//=============================================================================
// counter_pkg.sv  (UPDATED — Lab12: adds config, scoreboard, coverage,
//                  virtual sequencer, random/virtual sequences and tests)
//
// Package that acts as the single compilation unit for the entire UVM
// testbench.  Everything the TB needs — types, parameters, and all UVM
// component classes — is declared here so that any file that does
//   import counter_pkg::*;
// instantly gets access to the full testbench namespace.
//
// COMPILE ORDER
// -------------
// Each file must be compiled AFTER all files it depends on.
// (A class cannot reference another class that hasn't been declared yet.)
//
// Lab11 files (reused from Lab11):
//   1. counter_transaction   – sequence item (leaf; no TB dependencies)
//   2. counter_driver        – drives DUT; now has analysis port ap
//   3. counter_monitor       – observes DUT; has analysis port ap
//   4. counter_agent         – bundles driver + monitor + sequencer
//
// Lab12 new types (must come before classes that use them):
//   5. counter_config        – configuration knobs object
//      → must precede env and tests that reference counter_config
//
// Lab12 scoreboard (macros at package scope before the class):
//   6. counter_scoreboard    – checker with dual analysis imps
//      → `uvm_analysis_imp_decl macros are OUTSIDE the class, at package
//         scope; they expand at compile time into two new class definitions
//
//   7. counter_coverage      – functional coverage subscriber
//   8. counter_virtual_sequencer  – virtual sequencer hub
//   9. counter_env           – env with sb, cov, vseqr, cfg
//
// Sequences (base before derived):
//  10. counter_sequence          – directed sequence (base class for override)
//  11. counter_random_sequence   – constrained-random (extends counter_sequence)
//  12. counter_virtual_sequence  – coordinates sub-sequences via virtual seqr
//
// Tests (base before derived):
//  13. counter_test              – base test: config, env, directed sequence
//  14. counter_random_test       – extends counter_test: factory type override
//  15. counter_virtual_test      – extends counter_test: virtual sequence run
//=============================================================================
package counter_pkg;
  import uvm_pkg::*;          // all UVM base classes
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
  // Stimulus-type enumeration
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
  // Lab11 components (sequence item, agent-level components, agent)
  //--------------------------------------------------------------------------
  `include "counter_transaction.sv"     // sequence item with stimulus+result fields
  `include "counter_driver.sv"          // driver with analysis port ap (Lab12 update)
  `include "counter_monitor.sv"         // passive observer, broadcasts on ap
  `include "counter_agent.sv"           // bundles driver + monitor + sequencer

  //--------------------------------------------------------------------------
  // Lab12 new components
  //--------------------------------------------------------------------------

  // Configuration object — must precede env and tests
  `include "counter_config.sv"          // knobs: num_transactions, enable_coverage

  // Scoreboard — `uvm_analysis_imp_decl macros inside this file expand at
  // package scope (before the class definition in that file), which is correct
  `include "counter_scoreboard.sv"      // dual-imp checker with expected queue

  // Functional coverage subscriber
  `include "counter_coverage.sv"        // covergroup: test_type × value × cycles

  // Virtual sequencer — must precede env (env creates it) and virtual sequence
  `include "counter_virtual_sequencer.sv"   // holds real sequencer handle

  // Environment — must come after all components it instantiates
  `include "counter_env.sv"             // env with agent, sb, cov, vseqr

  //--------------------------------------------------------------------------
  // Lab12 sequences (base before derived)
  //--------------------------------------------------------------------------
  `include "counter_sequence.sv"        // directed: 6 corner-case transactions
  `include "counter_random_sequence.sv" // constrained-random (extends counter_sequence)
  `include "counter_virtual_sequence.sv"// virtual: orchestrates sub-sequences

  //--------------------------------------------------------------------------
  // Lab12 tests (base before derived)
  //--------------------------------------------------------------------------
  `include "counter_test.sv"            // base test: config + directed run
  `include "counter_random_test.sv"     // factory override: directed → random
  `include "counter_virtual_test.sv"    // virtual sequence: directed + random

endpackage
