 class my_monitor extends uvm_monitor;
  
    `uvm_component_utils(my_monitor)

     uvm_analysis_port #(my_transaction) aport;
    
     my_dut_config dut_config_0;
     virtual dut_if dut_vi;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
       dut_config_0 = my_dut_config::type_id::create("config");
       aport = new("aport", this);
       assert( uvm_config_db #(my_dut_config)::get(this, "", "dut_config",
						   dut_config_0) );
       dut_vi = dut_config_0.dut_vi;
       // other config settings as needed
    endfunction : build_phase
   
    task run_phase(uvm_phase phase);
      forever
      begin
        my_transaction tx;
        
         @(posedge dut_vi.clock);
        tx = my_transaction::type_id::create("tx");
        tx.cmd  = dut_vi.cmd;
        tx.addr = dut_vi.addr;
        tx.data = dut_vi.data;
        
        aport.write(tx);
      end
    endtask: run_phase

  endclass: my_monitor
