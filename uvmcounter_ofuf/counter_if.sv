`timescale 1ns/1ps
//=============================================================================
// counter_if.sv
//
// SystemVerilog interface for the counter DUT.
//
// Responsibilities:
//   - Declares all DUT signals (rst_n, load_data, mode, count, overflow,
//     underflow) in one place so the TB and DUT share a single port list.
//   - Defines a clocking block (tb_cb) that synchronises all TB-driven
//     stimulus and DUT-sampled responses to the posedge of clk, with a
//     standard 1 ns input/output skew.
//   - Provides two modports:
//       dut  – subset seen by the RTL module (no clocking block)
//       TB   – subset seen by the testbench (clocking block + clk)
//   - Implements four reusable interface tasks that the driver calls to
//     produce protocol-correct stimulus without duplicating timing logic.
//=============================================================================
interface counter_if (input logic clk);
  import counter_pkg::*;   // gives access to counter_mode_t and COUNTER_WIDTH

  //--------------------------------------------------------------------------
  // Signal declarations
  //--------------------------------------------------------------------------
  logic rst_n;                          // active-low synchronous reset
  logic [COUNTER_WIDTH-1:0] load_data; // parallel load value
  counter_mode_t             mode;      // operation select (see counter_mode_t)
  logic [COUNTER_WIDTH-1:0] count;      // current counter value (DUT output)
  logic                      overflow;  // pulses high when count wraps 255→0
  logic                      underflow; // pulses high when count wraps 0→255

  //--------------------------------------------------------------------------
  // Clocking block — all TB stimulus/sampling is synchronised through here.
  // output #1ns : TB drives signals 1 ns after the clock edge (hold time).
  // input  #1ns : TB samples signals 1 ns before the next clock edge (setup).
  //--------------------------------------------------------------------------
  clocking tb_cb @(posedge clk);
    default input #1ns output #1ns;
    output rst_n, load_data, mode;
    input  count, overflow, underflow;
  endclocking

  //--------------------------------------------------------------------------
  // Modports
  //--------------------------------------------------------------------------
  // dut  – RTL sees raw signals; no clocking block needed in synthesisable code
  modport dut (
    input  clk, rst_n, load_data, mode,
    output count, overflow, underflow
  );

  // TB   – testbench accesses signals through the clocking block for
  //        synchronised stimulus and glitch-free sampling
  modport TB (
    clocking tb_cb,
    input clk
  );

  //--------------------------------------------------------------------------
  // Interface tasks — encapsulate common protocol sequences so the driver
  // does not need to know the low-level timing details.
  //--------------------------------------------------------------------------

  // apply_reset: assert rst_n low for 'cycles' clock cycles then release.
  // Also idles mode to HOLD and clears load_data during reset.
  task apply_reset(int cycles = 3);
    tb_cb.rst_n     <= 0;
    tb_cb.load_data <= 0;
    tb_cb.mode      <= MODE_HOLD;
    repeat (cycles) @(tb_cb);  // hold reset for requested number of clocks
    tb_cb.rst_n <= 1;           // release reset
  endtask

  // load_counter: parallel-load 'data' into the counter, then return to HOLD.
  // Takes two clock cycles: one LOAD cycle + one HOLD cycle.
  task load_counter(logic [COUNTER_WIDTH-1:0] data);
    tb_cb.mode      <= MODE_LOAD;
    tb_cb.load_data <= data;
    @(tb_cb);             // clock in the load
    tb_cb.mode <= MODE_HOLD;
    @(tb_cb);             // one idle cycle before next operation
  endtask

  // count_up: switch to COUNT_UP mode for 'cycles' clocks, then HOLD.
  // Captures overflow/underflow flags seen during the counting window.
  task count_up(int cycles, output logic ovf_flag, output logic unf_flag);
    @(tb_cb);
    ovf_flag = 0;
    unf_flag = 0;
    tb_cb.mode <= MODE_COUNT_UP;
    for (int i = 0; i < cycles; i++) begin
      @(tb_cb);
      if (overflow)  ovf_flag = 1;   // latch if overflow seen at any cycle
      if (underflow) unf_flag = 1;
    end
    tb_cb.mode <= MODE_HOLD;
    @(tb_cb);   // one idle cycle to let DUT settle
  endtask

  // count_down: switch to COUNT_DN mode for 'cycles' clocks, then HOLD.
  // Captures overflow/underflow flags seen during the counting window.
  task count_down(int cycles, output logic ovf_flag, output logic unf_flag);
    @(tb_cb);
    ovf_flag = 0;
    unf_flag = 0;
    tb_cb.mode <= MODE_COUNT_DN;
    for (int i = 0; i < cycles; i++) begin
      @(tb_cb);
      if (overflow)  ovf_flag = 1;
      if (underflow) unf_flag = 1;
    end
    tb_cb.mode <= MODE_HOLD;
    @(tb_cb);
  endtask

endinterface
