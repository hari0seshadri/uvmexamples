// Object class


class adder_sequence extends uvm_sequence;
  `uvm_object_utils(adder_sequence)
  
  adder_sequence_item reset_pkt;
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name= "adder_sequence");
    super.new(name);
    `uvm_info(get_type_name(), "Inside Constructor!", UVM_HIGH)
  endfunction
  
  
  //--------------------------------------------------------
  //Body Task
  //--------------------------------------------------------
  task body();
    `uvm_info(get_type_name(), "Inside body task!", UVM_HIGH)
    
    reset_pkt = adder_sequence_item::type_id::create("reset_pkt");
    start_item(reset_pkt);
    reset_pkt.randomize() with {reset==1;};
    finish_item(reset_pkt);
        
  endtask: body
  
  
endclass: adder_sequence



class adder_test_sequence extends adder_sequence;
  `uvm_object_utils(adder_test_sequence)
  
  adder_sequence_item item;
  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name= "adder_test_sequence");
    super.new(name);
    `uvm_info(get_type_name(), "Inside Constructor!", UVM_HIGH)
  endfunction
  
  
  //--------------------------------------------------------
  //Body Task
  //--------------------------------------------------------
  task body();
    `uvm_info(get_type_name(), "Inside body task!", UVM_HIGH)
    
    item = adder_sequence_item::type_id::create("item");
    start_item(item);
    item.randomize() with {reset==0;};
    finish_item(item);
        
  endtask: body
  
  
endclass: adder_test_sequence
