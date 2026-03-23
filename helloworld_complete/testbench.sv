module top;

  import uvm_pkg::*;          // Import UVM package
  import my_testbench_pkg::*; // Import our custom testbench package

  // Instantiate the DUT interface
  dut_if dut_if1 ();

  // Instantiate the DUT, connecting it to the interface
  dut dut1 ( .dif(dut_if1) );

  // Clock generator: 10 ns period (5 ns high, 5 ns low)
  initial
  begin
    dut_if1.clock = 0;
    forever #5 dut_if1.clock = ~dut_if1.clock;
  end

  // Reset generator: assert reset for three clock cycles
  initial
  begin
    dut_if1.reset = 1;
    repeat(3) @(negedge dut_if1.clock); // Wait for 3 negative clock edges
    dut_if1.reset = 0;                  // Deassert reset
  end

  // UVM test runner
  initial
  begin: blk
    // Set the virtual interface in the UVM configuration database.
    // It will be retrieved by the test and configuration objects.
    uvm_config_db #(virtual dut_if)::set(null, "uvm_test_top",
                                         "dut_vi", dut_if1);

    // Tell UVM to finish the simulation when all objections are dropped
    uvm_top.finish_on_completion  = 1;

    // Run the test (the test name can be supplied via +UVM_TESTNAME on the command line)
    run_test();
  end

endmodule: top
