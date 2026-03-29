//=============================================================================
// counter_random_sequence.sv  (NEW — Lab12)
//
// Constrained-random stimulus sequence for the counter testbench.
//
// PURPOSE
// -------
// Directed tests are great for specific scenarios but cannot scale to cover
// the entire input space.  A constrained-random sequence lets the simulator
// automatically generate many diverse stimulus combinations, guided by
// constraints that keep values legal and meaningful.
//
// FACTORY OVERRIDE RELATIONSHIP
// --------------------------------
// counter_random_sequence EXTENDS counter_sequence (the directed sequence).
// This makes it a drop-in replacement via the UVM factory:
//
//   counter_sequence::type_id::set_type_override(
//       counter_random_sequence::get_type())
//
// After this override (registered in counter_random_test::build_phase),
// every counter_sequence::type_id::create() call in the factory returns
// a counter_random_sequence instead.  counter_test::run_phase creates "seq"
// via type_id::create — so the random test automatically runs this class
// without any changes to counter_test.
//
// CONFIGURATION
// -------------
// The sequence reads num_transactions from the counter_config in config_db.
// The sequencer is the context (get_sequencer() returns the sequencer this
// sequence is running on).  If config not found, a default of 20 is used.
//
// RANDOMISATION STRATEGY
// -----------------------
// Each iteration:
//   1. create a fresh counter_transaction via the factory
//   2. call start_item() to request the sequencer slot (may block)
//   3. randomize() the transaction — uses the constraints in counter_transaction
//      plus an optional inline constraint block
//   4. call finish_item() to deliver to the driver
//
// The counter_transaction constraints already ensure legal field values for
// each test_type (start_count>0 for COUNT_UP/DOWN, correct overflow values).
// We add no extra inline constraints here — the base constraints are sufficient.
//=============================================================================
class counter_random_sequence extends counter_sequence;
  `uvm_object_utils(counter_random_sequence)  // register with factory

  // Standard UVM sequence constructor
  function new(string name = "counter_random_sequence");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // body — constrained-random stimulus loop.
  //
  // Override body() completely — do NOT call super.body(), which would run
  // the directed sequence first.  This sequence replaces the directed body.
  //--------------------------------------------------------------------------
  virtual task body();
    counter_transaction tr;
    counter_config      cfg;
    int                 num_trans = 20;   // default if config not found

    // ── Read num_transactions from configuration ───────────────────────────
    // get_sequencer() returns the sequencer this sequence is running on.
    // That sequencer is the config_db context for sequences — the same path
    // used by the test to deposit the config object.
    if (uvm_config_db#(counter_config)::get(get_sequencer(), "", "cfg", cfg))
      num_trans = cfg.num_transactions;
    else
      `uvm_warning("RNDSEQ", "counter_config not found; using default num_transactions=20")

    `uvm_info("RNDSEQ",
      $sformatf("Starting random sequence: %0d transactions", num_trans),
      UVM_LOW)

    // ── Generate num_trans random transactions ─────────────────────────────
    repeat (num_trans) begin
      // Create a new transaction through the factory each iteration.
      // Using a fresh object avoids residual field values from prior randomisation.
      tr = counter_transaction::type_id::create("tr");

      // Request the sequencer slot — blocks if another sequence holds it.
      start_item(tr);

      // Randomize using the constraints declared in counter_transaction:
      //   valid          : legal field ranges for each test_type
      //   test_type_weight: biased distribution (LOAD most common)
      // If randomization fails (overconstrained), it is a testbench bug.
      if (!tr.randomize())
        `uvm_fatal("RNDSEQ", "counter_transaction randomize() failed — check constraints")

      // Deliver the randomized transaction to the driver; blocks until done.
      finish_item(tr);

      `uvm_info("RNDSEQ",
        $sformatf("Sent random[%0d]: %s", num_trans, tr.convert2string()),
        UVM_HIGH)
    end

    `uvm_info("RNDSEQ",
      $sformatf("Random sequence complete: %0d transactions sent", num_trans),
      UVM_LOW)
  endtask

endclass
