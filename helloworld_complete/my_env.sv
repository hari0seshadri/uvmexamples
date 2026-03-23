class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  UVM_FILE file_h;                 // File handle for log
  my_agent      my_agent_h;        // Agent instance
  my_subscriber my_subscriber_h;   // Subscriber instance

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    // Create subcomponents
    my_agent_h      = my_agent     ::type_id::create("my_agent_h", this);
    my_subscriber_h = my_subscriber::type_id::create("my_subscriber_h", this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    // Connect agent's analysis port to subscriber's analysis export
    my_agent_h.aport.connect( my_subscriber_h.analysis_export );
  endfunction: connect_phase

  function void start_of_simulation_phase(uvm_phase phase);
    // Set verbosity for all components
    // uvm_top.set_report_verbosity_level_hier(UVM_NONE);
    uvm_top.set_report_verbosity_level_hier(UVM_HIGH);

    // Open a log file and redirect all UVM_INFO messages to both display and file
    file_h = $fopen("uvm_basics_complete.log", "w");
    uvm_top.set_report_default_file_hier(file_h);
    uvm_top.set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY + UVM_LOG);
  endfunction: start_of_simulation_phase
endclass: my_env
