//=============================================================================
// counter_test.sv
//
// UVM test and sequence for the counter testbench.
//
// This file defines two classes:
//
//   counter_sequence  (defined first — used by counter_test, so must appear
//                      before counter_test to avoid a forward-reference error)
//   counter_test
//
// counter_sequence
// ----------------
//   A directed sequence that sends six hard-coded transactions covering all
//   test_type_t cases in a fixed order:
//     1. TEST_RESET      – assert/release reset
//     2. TEST_LOAD 42    – load the value 42
//     3. TEST_COUNT_UP   – count up 3 cycles from start=10 → expect 13
//     4. TEST_COUNT_DOWN – count down 2 cycles from start=20 → expect 18
//     5. TEST_OVERFLOW   – count up from MAX (255) → expect count=0, ovf=1
//     6. TEST_UNDERFLOW  – count down from 0 → expect count=255, unf=1
//
// counter_test
// ------------
//   Instantiates the environment, starts counter_sequence on the agent's
//   sequencer, waits 100 ns for the last transaction to drain, then drops
//   the objection to allow simulation to end cleanly.
//   Prints the UVM topology at end_of_elaboration for debug visibility.
//=============================================================================

//=============================================================================
// counter_sequence — directed stimulus sequence
//=============================================================================
class counter_sequence extends uvm_sequence #(counter_transaction);
  `uvm_object_utils(counter_sequence)  // register with UVM factory

  // Standard UVM sequence constructor
  function new(string name = "counter_sequence");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // body — called by the sequencer when the sequence is started.
  // Each transaction is created, configured, then sent to the driver via the
  // standard start_item / finish_item protocol.
  //   start_item : grants the sequencer arbitration and sends the item header
  //   finish_item: completes randomisation (if any) and delivers to driver
  //--------------------------------------------------------------------------
  virtual task body();
    counter_transaction tr;

    // ------------------------------------------------------------------
    // 1. Reset — assert and release DUT reset
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type = TEST_RESET;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 2. Load 42 — parallel-load the counter with decimal 42
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type  = TEST_LOAD;
    tr.load_value = 42;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 3. Count up 3 cycles starting from 10 — expect final count = 13
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_COUNT_UP;
    tr.start_count = 10;
    tr.up_cycles   = 3;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 4. Count down 2 cycles starting from 20 — expect final count = 18
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_COUNT_DOWN;
    tr.start_count = 20;
    tr.down_cycles = 2;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 5. Overflow — load MAX (255) then count up once; expect count=0, ovf=1
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_OVERFLOW;
    tr.start_count = COUNTER_MAX;
    tr.up_cycles   = 1;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 6. Underflow — load 0 then count down once; expect count=255, unf=1
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_UNDERFLOW;
    tr.start_count = 0;
    tr.down_cycles = 1;
    finish_item(tr);

  endtask
endclass

//=============================================================================
// counter_test — top-level UVM test
//=============================================================================
class counter_test extends uvm_test;
  `uvm_component_utils(counter_test)  // register with UVM factory

  // Handle to the environment — created in build_phase
  counter_env env;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — create the environment.
  // The environment in turn creates the agent, driver, monitor, sequencer.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = counter_env::type_id::create("env", this);
  endfunction

  //--------------------------------------------------------------------------
  // end_of_elaboration_phase — print the full UVM component hierarchy.
  // Useful for verifying that all components were created and connected.
  //--------------------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — start the sequence and manage the UVM objection.
  //
  // raise_objection prevents the phase from ending prematurely while the
  // sequence is running.  drop_objection signals that the test is done and
  // allows UVM to proceed to the cleanup phases and end simulation.
  // The extra #100 delay gives the last transaction time to propagate through
  // the DUT and be captured by the monitor before objection drops.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    counter_sequence seq;
    phase.raise_objection(this);              // keep simulation alive

    seq = counter_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);           // run all 6 transactions

    #100;                                     // drain final transaction
    phase.drop_objection(this);              // allow simulation to end
  endtask

endclass
