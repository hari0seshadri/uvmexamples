`timescale 1ns/1ps
import uvm_pkg::*;          // UVM base classes (uvm_config_db, run_test, ...)
`include "uvm_macros.svh"   // UVM macros (`uvm_info, `uvm_fatal, etc.)
import counter_pkg::*;      // testbench types, parameters, and component classes

//=============================================================================
// counter_tb_top.sv  (UPDATED — Lab12: adds config_db deposit and run_test())
//
// Top-level testbench module — the simulation entry point.
//
// Responsibilities:
//   1. Clock generation — produces a 10 ns period (100 MHz) clock.
//   2. Interface instantiation — creates the shared counter_if signal bundle.
//   3. DUT instantiation — connects the RTL counter module to the interface.
//   4. Config creation — [Lab12 NEW] creates a counter_config with default
//      knobs and deposits it in config_db so the test can override or use it.
//   5. Virtual interface deposit — publishes intf handle to config_db so
//      that counter_driver and counter_monitor can retrieve it in build_phase.
//   6. run_test() — [Lab12 UPDATED] called without arguments so the test
//      is selected at runtime via +UVM_TESTNAME=<test_name>.
//   7. Waveform dump — $dumpfile/$dumpvars for post-simulation viewing.
//
// MULTIPLE TEST SELECTION (Lab12)
// --------------------------------
// In Lab11 the test was hard-coded: run_test("counter_test").
// In Lab12 we call run_test() with NO argument.  The test name is supplied
// on the simulator command line:
//   +UVM_TESTNAME=counter_test         → directed test (6 transactions)
//   +UVM_TESTNAME=counter_random_test  → random test  (N transactions)
//   +UVM_TESTNAME=counter_virtual_test → virtual sequence test
// If +UVM_TESTNAME is not provided, UVM issues a fatal error.
//
// CONFIG_DB DEPOSIT ORDER
// -----------------------
// The initial block runs at simulation time 0.  At that point the UVM
// hierarchy does not yet exist (it is created by run_test()).  Deposits
// made before run_test() are accessible to any component that calls get()
// during build_phase, because build_phase runs after run_test() sets up
// the hierarchy.  The deposit path "*" makes the config visible to all
// components regardless of their hierarchical path.
//=============================================================================
module counter_tb_top;

  //--------------------------------------------------------------------------
  // Clock generation — 10 ns period (50% duty cycle)
  //--------------------------------------------------------------------------
  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // toggle every 5 ns → 100 MHz
  end

  //--------------------------------------------------------------------------
  // Interface instantiation
  //--------------------------------------------------------------------------
  counter_if intf (clk);   // shared signal bundle; clk port drives all sync logic

  //--------------------------------------------------------------------------
  // DUT instantiation — uses the 'dut' modport (input/output subset only)
  //--------------------------------------------------------------------------
  counter dut (.intf(intf.dut));

  //--------------------------------------------------------------------------
  // UVM startup block
  //--------------------------------------------------------------------------
  initial begin

    // ── [Lab12] Create and configure the counter_config object ─────────────
    // The test may override individual fields in its build_phase.
    // If the test finds this config in config_db, it uses these values;
    // if not found, the test creates a fresh default config instead.
    begin
      counter_config cfg;
      cfg = counter_config::type_id::create("cfg");
      cfg.num_transactions = 20;    // how many random transactions to generate
      cfg.enable_coverage  = 1;     // create the coverage collector
      cfg.use_random_test  = 0;     // overridden to 1 by counter_random_test

      // Deposit config at root context ("*" = visible everywhere).
      // key "cfg" matches what counter_test and counter_env look for.
      uvm_config_db#(counter_config)::set(null, "*", "cfg", cfg);
    end

    // ── Virtual interface deposit ───────────────────────────────────────────
    // counter_driver and counter_monitor call config_db::get("vif") in their
    // build_phase.  Depositing here (before run_test) ensures the handle is
    // available when those build_phases execute.
    uvm_config_db#(virtual counter_if)::set(null, "*", "vif", intf);

    // ── Start UVM — test selected via +UVM_TESTNAME on command line ─────────
    // Supported test names:
    //   +UVM_TESTNAME=counter_test         (default directed test)
    //   +UVM_TESTNAME=counter_random_test  (factory override → random stimulus)
    //   +UVM_TESTNAME=counter_virtual_test (virtual sequence pattern)
    run_test();   // blocks until all UVM phases complete
  end

  //--------------------------------------------------------------------------
  // Waveform dump
  //--------------------------------------------------------------------------
  initial begin
    $dumpfile("counter_tb_top.vcd");
    $dumpvars(0, counter_tb_top);   // 0 = all levels of hierarchy
  end

endmodule
