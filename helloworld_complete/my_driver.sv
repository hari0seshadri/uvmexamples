  class my_driver extends uvm_driver #(my_transaction);
  
    `uvm_component_utils(my_driver)

     my_dut_config dut_config_0;
     virtual dut_if dut_vi;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       assert( uvm_config_db #(my_dut_config)::get(this, "", "dut_config", 
						   dut_config_0) );
       dut_vi = dut_config_0.dut_vi;
       // other config settings from dut_config_0 object as needed
    endfunction : build_phase
   
    task run_phase(uvm_phase phase);
      forever
      begin
        my_transaction tx;
        
        @(posedge dut_vi.clock);
        seq_item_port.get(tx);
        
        // Wiggle pins of DUT
        dut_vi.cmd  = tx.cmd;
        dut_vi.addr = tx.addr;
        dut_vi.data = tx.data;
      end
    endtask: run_phase

  endclass: my_driver


