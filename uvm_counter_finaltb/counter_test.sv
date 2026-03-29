//=============================================================================
// counter_test.sv  (UPDATED — Lab12: adds config creation and config_db deposit)
//
// Base UVM test for the counter testbench.
//
// This class is the base test from which counter_random_test and
// counter_virtual_test both derive.  It provides:
//   - Configuration object creation and config_db deposit
//   - Environment instantiation
//   - A default run_phase that runs the directed counter_sequence
//
// CONFIGURATION FLOW
// ------------------
// The test is responsible for creating the counter_config and depositing it
// in config_db BEFORE the environment's build_phase runs (UVM guarantees
// that the test's build_phase runs before its children, so depositing in
// build_phase is safe).
//
//   1. Try to get a pre-built config from config_db (e.g., deposited by
//      counter_tb_top with command-line override values).
//   2. If not found, create a default counter_config with built-in defaults.
//   3. Re-deposit the config so the environment and all components below
//      can retrieve it with:
//        uvm_config_db#(counter_config)::get(this, "", "cfg", cfg)
//
// FACTORY OVERRIDE HOOK
// ---------------------
// counter_random_test overrides build_phase:
//   counter_sequence::type_id::set_type_override(
//       counter_random_sequence::get_type())
// before calling super.build_phase(phase).
// This replaces the factory mapping so that when counter_test::run_phase
// calls counter_sequence::type_id::create("seq"), the factory returns a
// counter_random_sequence instead — without changing a single line of code
// in this base class.
//
// VIRTUAL SEQUENCE OVERRIDE
// -------------------------
// counter_virtual_test overrides run_phase entirely to start a
// counter_virtual_sequence on env.vseqr instead of using the base run_phase.
//=============================================================================
class counter_test extends uvm_test;
  `uvm_component_utils(counter_test)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Handles
  //--------------------------------------------------------------------------
  counter_env    env;   // top-level environment
  counter_config cfg;   // configuration object

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — create config and environment.
  //
  // Called before the environment's build_phase.  All config_db deposits made
  // here are visible to children that call get() in their own build_phase.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // ── Step 1: Try to get a pre-configured config object ─────────────────
    // counter_tb_top may have deposited one with command-line knob values.
    // The context path "" means "anywhere at or below this component" which
    // matches the set() made by tb_top with path "*".
    if (!uvm_config_db#(counter_config)::get(this, "", "cfg", cfg)) begin
      // No config found — create a default one.  All fields take their
      // class-level defaults (num_transactions=20, enable_coverage=1).
      cfg = counter_config::type_id::create("cfg");
      `uvm_info("TEST",
        "counter_config not in config_db; using defaults (num_tx=20, cov=1)",
        UVM_LOW)
    end

    // ── Step 2: Print the configuration for debug visibility ──────────────
    cfg.print();

    // ── Step 3: Re-deposit config so env and all components can get it ─────
    // We set it from 'this' (the test) with path "*" so it is visible to
    // every component instantiated by the test (env, agent, sequences).
    uvm_config_db#(counter_config)::set(this, "*", "cfg", cfg);

    // ── Step 4: Create the environment ────────────────────────────────────
    // counter_env::build_phase will call config_db::get to retrieve cfg.
    env = counter_env::type_id::create("env", this);
  endfunction

  //--------------------------------------------------------------------------
  // end_of_elaboration_phase — print the full UVM component topology.
  //
  // Runs after all build_phase and connect_phase calls complete.  Useful for
  // verifying that all components were created and that analysis port
  // connections are correct (shows ports and exports in the topology).
  //--------------------------------------------------------------------------
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — start the directed sequence and manage the UVM objection.
  //
  // raise_objection: prevents UVM from ending the run_phase prematurely.
  //                  UVM ends run_phase when all objections are dropped.
  //
  // seq.start():    runs the full body() of counter_sequence (or whatever
  //                 the factory maps counter_sequence::type_id::create to).
  //                 Blocks until all finish_item() calls return.
  //
  // #100:           small drain delay so the last transaction propagates
  //                 through the DUT and is captured by the monitor before
  //                 the objection drops and simulation ends.
  //
  // drop_objection: signals that this test is done; UVM begins cleanup phases.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    counter_sequence seq;
    phase.raise_objection(this);   // keep simulation alive

    // Create via factory — counter_random_test's type override replaces this
    // with counter_random_sequence without changing any code here.
    seq = counter_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);   // run all transactions

    #100;                             // drain last transaction through DUT
    phase.drop_objection(this);      // allow simulation to end
  endtask

endclass
