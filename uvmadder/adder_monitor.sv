
class adder_monitor extends uvm_monitor;
  `uvm_component_utils(adder_monitor)
  
  virtual adder_interface vif;
  adder_sequence_item item;
  
  uvm_analysis_port #(adder_sequence_item) monitor_port;
  
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "adder_monitor", uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "Inside Constructor!", UVM_HIGH)
  endfunction: new
  
  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Build Phase!", UVM_HIGH)
    
    monitor_port = new("monitor_port", this);
    
    uvm_config_db #(virtual adder_interface)::get(this, "*", "vif", vif);
    
  endfunction: build_phase
  
  //--------------------------------------------------------
  //Connect Phase
  //--------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(), "Connect Phase!", UVM_HIGH)
    
  endfunction: connect_phase
  
  
  //--------------------------------------------------------
  //Run Phase
  //--------------------------------------------------------
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(get_type_name(), "Inside Run Phase!", UVM_HIGH)
    
    forever begin
      item = adder_sequence_item::type_id::create("item");
      
      wait(!vif.reset);
      
      //sample inputs
      @(posedge vif.clock);
      item.input_1 = vif.input_1;
      item.input_2 = vif.input_2;
      
      //sample output
      @(posedge vif.clock);
      item.output_3 = vif.output_3;
      
      // send item to scoreboard
      monitor_port.write(item);
    end
        
  endtask: run_phase
  
  
endclass: adder_monitor
