// Code your testbench here
// or browse Examples


`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"
import adder_pkg::*;



module top;
  
  //--------------------------------------------------------
  //Instantiation
  //--------------------------------------------------------

  logic clock;
  
  adder_interface intf(.clock(clock));
  
  adder dut(
    .clock(intf.clock),
    .reset(intf.reset),
    .input_1(intf.input_1),
    .input_2(intf.input_2),
    .output_3(intf.output_3)
  );
  
  
  //--------------------------------------------------------
  //Interface Setting
  //--------------------------------------------------------
  initial begin
    uvm_config_db #(virtual adder_interface)::set(null, "*", "vif",intf );
  end
  
  
  
  //--------------------------------------------------------
  //Start The Test
  //--------------------------------------------------------
  initial begin
    run_test("random_test");
  end
  
  
  //--------------------------------------------------------
  //Clock Generation
  //--------------------------------------------------------
  initial begin
    clock = 0;
    #5;
    forever begin
      clock = ~clock;
      #2;
    end
  end
  
  
  //--------------------------------------------------------
  //Maximum Simulation Time
  //--------------------------------------------------------
  initial begin
    #5000;
    $display("Sorry! Ran out of clock cycles!");
    $finish();
  end
  
  
  //--------------------------------------------------------
  //Generate Waveforms
  //--------------------------------------------------------
  initial begin
    $dumpfile("d.vcd");
    $dumpvars();
  end
  
  
  
endmodule: top
