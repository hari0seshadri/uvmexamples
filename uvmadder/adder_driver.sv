
class adder_driver extends uvm_driver#(adder_sequence_item);
  `uvm_component_utils(adder_driver)
  
  virtual adder_interface vif;
  adder_sequence_item item;
  
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "adder_driver", uvm_component parent);
    super.new(name, parent);
    `uvm_info(get_type_name(), "Inside Constructor!", UVM_HIGH)
  endfunction: new
  
  
  //--------------------------------------------------------
  //Build Phase
  //--------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "Build Phase!", UVM_HIGH)
    
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
      seq_item_port.get_next_item(item);
      drive(item);
      seq_item_port.item_done();
    end
    
  endtask: run_phase
  
  
  //--------------------------------------------------------
  //[Method] Drive
  //--------------------------------------------------------
  task drive(adder_sequence_item item);
    @(posedge vif.clock);
    vif.reset <= item.reset;
    vif.input_1 <= item.input_1;
    vif.input_2 <= item.input_2;
  endtask: drive
  
  
endclass: adder_driver
