//=============================================================================
// counter_agent.sv  (unchanged from Lab11)
//
// UVM agent for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env → counter_agent
//
// An agent is the standard UVM container that groups together the three
// components needed to stimulate and observe a single DUT interface:
//
//   sequencer  – arbitrates between competing sequences and hands transactions
//                to the driver one at a time via TLM get port
//   driver     – translates transactions into pin-level stimulus
//   monitor    – passively observes DUT outputs and publishes response
//                transactions on its analysis port
//
// TLM Connection (connect_phase):
//   driver.seq_item_port ↔ sequencer.seq_item_export
//   This is the standard UVM pull model: the driver calls get_next_item()
//   on its port; the sequencer fulfils the request from whichever sequence
//   is currently running on it.
//
// Lab12 note:
//   The driver now has an analysis port (driver.ap) and the monitor's
//   analysis port (monitor.ap) must be connected to the scoreboard and
//   coverage collector.  Those connections are made in counter_env::
//   connect_phase (not here), because the scoreboard and coverage are
//   owned by the environment, not the agent.
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
  //
  // type_id::create() routes through the factory.  In counter_random_test,
  // a factory override replaces counter_sequence with counter_random_sequence
  // globally; the agent itself is never overridden in this testbench.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = counter_driver::type_id::create("driver", this);
    monitor   = counter_monitor::type_id::create("monitor", this);
    // Generic sequencer parameterised on counter_transaction.
    // In Lab12 the virtual sequencer holds a handle to THIS sequencer
    // so virtual sequences can drive the DUT through it.
    sequencer = uvm_sequencer #(counter_transaction)::type_id::create("sequencer", this);
  endfunction

  //--------------------------------------------------------------------------
  // connect_phase — wire driver TLM port to sequencer export.
  //
  // After this connection, driver.seq_item_port.get_next_item() will block
  // until the sequencer has a transaction to provide (from a running sequence).
  //--------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
