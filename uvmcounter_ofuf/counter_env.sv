//=============================================================================
// counter_env.sv
//
// UVM environment for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env
//
// The environment is the top-level container for all reusable verification
// components.  It instantiates the agent (and in a larger testbench would
// also instantiate scoreboards, functional coverage collectors, and other
// checkers).  Keeping these components inside the env makes the env reusable
// across different tests and projects with minimal changes.
//
// In this testbench the env contains:
//   counter_agent  – active agent with driver + monitor + sequencer
//
// The test accesses env.agent.sequencer to start sequences, and can also
// connect to env.agent.monitor.ap to add a scoreboard or coverage model.
//=============================================================================
class counter_env extends uvm_env;
  `uvm_component_utils(counter_env)  // register with UVM factory

  // Handle to the agent — created in build_phase
  counter_agent agent;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("ENV", "Environment object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — instantiate the agent via the UVM factory.
  // Additional components (scoreboard, coverage) would also be created here.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = counter_agent::type_id::create("agent", this);
  endfunction

endclass
