class my_agent extends uvm_agent;
  `uvm_component_utils(my_agent)

  uvm_analysis_port #(my_transaction) aport;   // Analysis port to export monitor's transactions

  typedef uvm_sequencer #(my_transaction) my_sequencer;
  my_sequencer my_sequencer_h;   // Sequencer handle
  my_driver    my_driver_h;      // Driver handle
  my_monitor   my_monitor_h;     // Monitor handle

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    aport = new("aport", this);
    // Create subcomponents
    my_sequencer_h = my_sequencer::type_id::create("my_sequencer_h", this);
    my_driver_h    = my_driver   ::type_id::create("my_driver_h"   , this);
    my_monitor_h   = my_monitor  ::type_id::create("my_monitor_h"  , this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    // Connect driver to sequencer
    my_driver_h.seq_item_port.connect( my_sequencer_h.seq_item_export );
    // Connect monitor's analysis port to agent's analysis port
    my_monitor_h.aport.connect( aport );
  endfunction: connect_phase
endclass: my_agent
