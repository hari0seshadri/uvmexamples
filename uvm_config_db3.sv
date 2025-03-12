// Component that retrieves an integer from the database
class my_component extends uvm_component;
  `uvm_component_utils(my_component)

  int my_value;

  function new(string name = "my_component", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(int)::get(this, "", "my_value", my_value))
      `uvm_fatal("MY_COMPONENT", "Integer value not set in config_db")
    else
      `uvm_info("MY_COMPONENT", $sformatf("Retrieved my_value: %0d", my_value), UVM_MEDIUM)
  endfunction
endclass

// Test class
class my_test extends uvm_test;
  `uvm_component_utils(my_test)
  my_component comp;

  function new(string name = "my_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // Setting an integer value in config_db
    uvm_config_db#(int)::set(this, "comp", "my_value", 42);

    comp = my_component::type_id::create("comp", this);
  endfunction
endclass
