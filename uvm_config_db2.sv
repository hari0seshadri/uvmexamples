// Configuration class
class my_config extends uvm_object;
  `uvm_object_utils(my_config)
  bit enable;
  int threshold;

  function new(string name = "my_config");
    super.new(name);
  endfunction
endclass

// Environment class
class my_env extends uvm_env;
  `uvm_component_utils(my_env)
  my_config cfg;

  function new(string name = "my_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(my_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("MY_ENV", "Configuration object not set in config_db")
  endfunction
endclass

// Test class
class my_test extends uvm_test;
  `uvm_component_utils(my_test)
  my_env env;
  my_config cfg;

  function new(string name = "my_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    cfg = my_config::type_id::create("cfg");
    cfg.enable = 1;
    cfg.threshold = 100;

    // Setting configuration object in config_db
    uvm_config_db#(my_config)::set(this, "env", "cfg", cfg);

    env = my_env::type_id::create("env", this);
  endfunction
endclass
