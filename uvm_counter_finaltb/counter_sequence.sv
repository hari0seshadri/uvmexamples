//=============================================================================
// counter_sequence.sv  (extracted from Lab11 counter_test.sv, UNCHANGED)
//
// Directed stimulus sequence for the counter testbench.
//
// In Lab11 this class was defined inside counter_test.sv.  In Lab12 it is
// moved to its own file so that:
//   a) counter_random_test can register a global factory type-override that
//      replaces every counter_sequence with counter_random_sequence without
//      touching this file.
//   b) counter_virtual_sequence can start a counter_sequence as one phase of
//      a multi-phase virtual stimulus plan.
//
// SEQUENCE BODY
// -------------
// The body() task sends six hard-coded transactions covering all test_type_t
// cases in a deterministic order:
//   1. TEST_RESET      – assert/release DUT reset
//   2. TEST_LOAD 42    – load the value 42; expected count = 42
//   3. TEST_COUNT_UP   – count up 3 from 10;   expected count = 13
//   4. TEST_COUNT_DOWN – count down 2 from 20;  expected count = 18
//   5. TEST_OVERFLOW   – count up 1 from 255;   expected count = 0, ovf=1
//   6. TEST_UNDERFLOW  – count down 1 from 0;   expected count = 255, unf=1
//
// UVM SEQUENCE PROTOCOL
// ---------------------
//   start_item(tr)  – requests the sequencer for a slot (may block if busy)
//   finish_item(tr) – delivers tr to the driver; blocks until driver calls
//                     item_done() (i.e., until the operation is done)
//
// BASE CLASS FOR FACTORY OVERRIDE
// --------------------------------
// counter_random_test calls:
//   counter_sequence::type_id::set_type_override(
//       counter_random_sequence::get_type())
// After this override, every call to counter_sequence::type_id::create()
// inside the factory returns a counter_random_sequence instead.
// counter_test creates "seq" via type_id::create, so without any code change
// in counter_test, the random test runs counter_random_sequence.
//=============================================================================
class counter_sequence extends uvm_sequence #(counter_transaction);
  `uvm_object_utils(counter_sequence)  // register with UVM factory

  // Standard UVM sequence constructor
  function new(string name = "counter_sequence");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // body — directed stimulus: six deterministic transactions
  //--------------------------------------------------------------------------
  virtual task body();
    counter_transaction tr;

    // ------------------------------------------------------------------
    // 1. Reset — assert and release DUT reset; counter returns to 0
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type = TEST_RESET;
    finish_item(tr);   // blocks until driver calls item_done()

    // ------------------------------------------------------------------
    // 2. Load 42 — parallel-load the counter with the value 42
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type  = TEST_LOAD;
    tr.load_value = 42;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 3. Count up 3 cycles from start = 10 → expect final count = 13
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_COUNT_UP;
    tr.start_count = 10;
    tr.up_cycles   = 3;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 4. Count down 2 cycles from start = 20 → expect final count = 18
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_COUNT_DOWN;
    tr.start_count = 20;
    tr.down_cycles = 2;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 5. Overflow — load MAX (255) then count up once
    //    → expect count = 0, act_ovf = 1
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_OVERFLOW;
    tr.start_count = COUNTER_MAX;   // 255
    tr.up_cycles   = 1;
    finish_item(tr);

    // ------------------------------------------------------------------
    // 6. Underflow — load 0 then count down once
    //    → expect count = 255, act_unf = 1
    // ------------------------------------------------------------------
    tr = counter_transaction::type_id::create("tr");
    start_item(tr);
    tr.test_type   = TEST_UNDERFLOW;
    tr.start_count = 0;
    tr.down_cycles = 1;
    finish_item(tr);

  endtask

endclass
