class my_driver extends uvm_driver #(my_transaction);
  `uvm_component_utils(my_driver)

  my_dut_config dut_config_0;   // Configuration object
  virtual dut_if dut_vi;        // Virtual interface to DUT

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    // Retrieve the DUT configuration from the database
    assert( uvm_config_db #(my_dut_config)::get(this, "", "dut_config", dut_config_0) );
    dut_vi = dut_config_0.dut_vi;   // Get the virtual interface
    // Other configuration settings from dut_config_0 could be used here
  endfunction : build_phase

  // Main driver task: gets a transaction and drives pins on clock edge
  task run_phase(uvm_phase phase);
    forever begin
      my_transaction tx;
      @(posedge dut_vi.clock);          // Wait for clock edge
      seq_item_port.get(tx);             // Get next transaction from sequencer
      // Drive DUT pins
      dut_vi.cmd  = tx.cmd;
      dut_vi.addr = tx.addr;
      dut_vi.data = tx.data;
    end
  endtask: run_phase
endclass: my_driver
