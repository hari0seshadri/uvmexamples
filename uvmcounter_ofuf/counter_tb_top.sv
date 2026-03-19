`timescale 1ns/1ps
import uvm_pkg::*;          // UVM base classes (uvm_config_db, run_test, ...)
`include "uvm_macros.svh"   // UVM macros (`uvm_info, etc.)
import counter_pkg::*;      // testbench types, parameters, and component classes

//=============================================================================
// counter_tb_top.sv
//
// Top-level testbench module — the simulation entry point.
//
// Responsibilities:
//   1. Clock generation — produces a 10 ns period (100 MHz) clock using an
//      initial/forever block.  The clock is passed directly into counter_if.
//
//   2. Interface instantiation — creates the counter_if instance that connects
//      the DUT and all UVM components through a single shared port bundle.
//
//   3. DUT instantiation — connects the RTL counter module to the interface
//      via the 'dut' modport, which exposes only the signals the RTL needs.
//
//   4. UVM config_db setup — registers the virtual interface handle with the
//      UVM configuration database under the key "vif".  The driver and
//      monitor retrieve this handle in their build_phase, giving them access
//      to the physical signals without requiring direct hierarchical paths.
//
//   5. run_test() — launches the UVM test named on the command line
//      (+UVM_TESTNAME=counter_test) or defaults to "counter_test".
//      This call blocks until all UVM phases complete and all objections drop.
//
//   6. Waveform dump — calls $dumpfile/$dumpvars to record a VCD waveform
//      for post-simulation viewing in a waveform viewer.
//=============================================================================
module counter_tb_top;

  //--------------------------------------------------------------------------
  // Clock generation — 10 ns period (50% duty cycle)
  //--------------------------------------------------------------------------
  logic clk;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;   // toggle every 5 ns → 10 ns period
  end

  //--------------------------------------------------------------------------
  // Interface instantiation — shared signal bundle for DUT and TB
  // The clock is passed as a port argument to the interface.
  //--------------------------------------------------------------------------
  counter_if intf (clk);

  //--------------------------------------------------------------------------
  // DUT instantiation — connects to the interface via the 'dut' modport.
  // The modport restricts DUT visibility to input/output signals only
  // (no clocking block) which is appropriate for synthesisable RTL.
  //--------------------------------------------------------------------------
  counter dut (.intf(intf.dut));

  //--------------------------------------------------------------------------
  // UVM startup block
  //--------------------------------------------------------------------------
  initial begin
    // Publish the virtual interface into the config database so that the
    // driver and monitor can retrieve it in their build_phase.
    // null  : set at the root context (accessible from anywhere in the hierarchy)
    // "*"   : wildcard path — any component requesting "vif" will receive it
    uvm_config_db#(virtual counter_if)::set(null, "*", "vif", intf);

    // Start the UVM test.  The test name is taken from the +UVM_TESTNAME
    // plusarg if provided, otherwise defaults to the argument given here.
    run_test("counter_test");
  end

  //--------------------------------------------------------------------------
  // Waveform dump — records all signals for post-simulation viewing.
  // Open counter_tb_top.vcd in GTKWave or Questa's wave viewer.
  //--------------------------------------------------------------------------
  initial begin
    $dumpfile("counter_tb_top.vcd");
    $dumpvars(0, counter_tb_top);   // 0 = dump all levels of hierarchy
  end

endmodule
