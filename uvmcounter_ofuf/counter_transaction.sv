//=============================================================================
// counter_transaction.sv
//
// UVM sequence item (transaction) for the counter testbench.
//
// A counter_transaction describes ONE complete counter operation to be
// performed by the driver, and also carries the observed results captured
// by the monitor so that a scoreboard can compare expected vs actual.
//
// Stimulus fields (randomisable):
//   test_type   – which operation to perform (see test_type_t in pkg)
//   load_value  – value to load for TEST_LOAD
//   start_count – value to pre-load before a count-up/down/overflow/underflow
//   up_cycles   – number of clock cycles to count up
//   down_cycles – number of clock cycles to count down
//
// Result fields (filled by monitor, not randomised):
//   act_count   – counter value observed after the operation
//   act_ovf     – overflow flag observed
//   act_unf     – underflow flag observed
//
// Constraints ensure that each test_type gets consistent, legal field values.
// A weighted distribution (test_type_weight) skews random generation toward
// LOAD and count operations, which are more commonly useful stimuli.
//=============================================================================
class counter_transaction extends uvm_sequence_item;
  `uvm_object_utils(counter_transaction)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Stimulus fields
  //--------------------------------------------------------------------------
  rand test_type_t              test_type;    // operation selector
  rand logic [COUNTER_WIDTH-1:0] load_value; // parallel-load value
  rand int                       up_cycles;  // cycles to count up
  rand int                       down_cycles;// cycles to count down
  rand logic [COUNTER_WIDTH-1:0] start_count;// pre-load before counting

  //--------------------------------------------------------------------------
  // Result fields — written by the monitor after observing the DUT
  //--------------------------------------------------------------------------
  logic [COUNTER_WIDTH-1:0] act_count;  // observed counter value
  logic                     act_ovf;    // observed overflow flag
  logic                     act_unf;    // observed underflow flag

  //--------------------------------------------------------------------------
  // Constraint: valid — keeps all fields in legal ranges and makes field
  // values consistent with the chosen test_type.
  //--------------------------------------------------------------------------
  constraint valid {
    load_value  inside {[0:COUNTER_MAX]};
    start_count inside {[0:COUNTER_MAX]};
    up_cycles   >= 0;  down_cycles >= 0;
    up_cycles   <= 20; down_cycles <= 20;

    // For LOAD: only load_value matters; cycle counts and start unused
    if (test_type == TEST_LOAD)       { up_cycles == 0; down_cycles == 0; start_count == 0; }
    // For COUNT_UP: must count at least one cycle upward
    if (test_type == TEST_COUNT_UP)   { up_cycles >= 1; down_cycles == 0; }
    // For COUNT_DOWN: must count at least one cycle downward
    if (test_type == TEST_COUNT_DOWN) { down_cycles >= 1; up_cycles == 0; }
    // For OVERFLOW: start at max value, count up once to wrap
    if (test_type == TEST_OVERFLOW)   { start_count == COUNTER_MAX; up_cycles == 1; down_cycles == 0; }
    // For UNDERFLOW: start at 0, count down once to wrap
    if (test_type == TEST_UNDERFLOW)  { start_count == 0; down_cycles == 1; up_cycles == 0; }
    // For RESET: all fields irrelevant; zero them out
    if (test_type == TEST_RESET)      { load_value == 0; start_count == 0; up_cycles == 0; down_cycles == 0; }
  }

  //--------------------------------------------------------------------------
  // Constraint: test_type_weight — biases random test type selection.
  // LOAD is most common (weight 3); corner cases (OVERFLOW/UNDERFLOW/RESET)
  // are generated less frequently (weight 1).
  //--------------------------------------------------------------------------
  constraint test_type_weight {
    test_type dist {
      TEST_LOAD       := 3,
      TEST_COUNT_UP   := 2,
      TEST_COUNT_DOWN := 2,
      TEST_OVERFLOW   := 1,
      TEST_UNDERFLOW  := 1,
      TEST_RESET      := 1
    };
  }

  // Standard UVM constructor
  function new(string name = "counter_transaction");
    super.new(name);
  endfunction

  // convert2string — returns a human-readable one-line summary of the
  // transaction, used by the driver's UVM_INFO print and debug logs.
  virtual function string convert2string();
    return $sformatf("test_type=%s load=%0d up=%0d down=%0d start=%0d",
                     test_type.name(), load_value, up_cycles, down_cycles, start_count);
  endfunction

endclass
