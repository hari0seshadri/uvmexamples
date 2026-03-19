//=============================================================================
// counter_agent.sv
//
// UVM agent for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env → counter_agent
//
// An agent is the standard UVM container that groups together the three
// components needed to stimulate and observe a single DUT interface:
//
//   sequencer  – arbitrates between competing sequences and hands
//                transactions to the driver one at a time
//   driver     – translates transactions into pin-level stimulus on the
//                virtual interface
//   monitor    – passively observes pin-level activity and publishes
//                completed transactions on its analysis port
//
// Connection (connect_phase):
//   driver.seq_item_port  ←→  sequencer.seq_item_export
//   This TLM connection is the standard UVM pull model: the driver calls
//   get_next_item() on its port, the sequencer fulfils requests from whatever
//   sequence is currently running.
//
// Note: this agent is always ACTIVE (it drives the DUT).  A passive agent
// would omit the driver and sequencer; that pattern is not needed here.
//=============================================================================
class counter_agent extends uvm_agent;
  `uvm_component_utils(counter_agent)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Sub-component handles — created in build_phase
  //--------------------------------------------------------------------------
  counter_driver                          driver;
  counter_monitor                         monitor;
  uvm_sequencer #(counter_transaction)    sequencer;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("AGENT", "Agent object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — instantiate all three sub-components via the UVM factory.
  // Using type_id::create() allows factory overrides in tests if needed.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = counter_driver::type_id::create("driver", this);
    monitor   = counter_monitor::type_id::create("monitor", this);
    sequencer = uvm_sequencer #(counter_transaction)::type_id::create("sequencer", this);
  endfunction

  //--------------------------------------------------------------------------
  // connect_phase — wire the driver's TLM request port to the sequencer's
  // export so that the driver can pull transactions from the sequencer.
  //--------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
