//=============================================================================
// counter_virtual_sequencer.sv  (NEW — Lab12)
//
// Virtual sequencer for the counter testbench.
//
// PURPOSE
// -------
// A virtual sequencer is a sequencer that does NOT directly drive a driver.
// Instead, it holds HANDLES to one or more real (agent) sequencers and acts
// as a coordination hub through which virtual sequences can orchestrate
// activity across multiple real sequencers simultaneously.
//
// In this testbench there is only one real sequencer (the counter agent's
// sequencer), so the virtual sequencer pattern is demonstrated with a single
// handle.  In a multi-agent testbench (e.g., CPU + memory), the virtual
// sequencer would hold handles to all agent sequencers and a virtual sequence
// could interleave operations on both.
//
// USAGE PATTERN
// -------------
//   1. counter_env::build_phase  creates counter_virtual_sequencer
//   2. counter_env::connect_phase assigns:
//        vseqr.counter_seqr = agent.sequencer
//   3. A virtual test starts a virtual sequence on the virtual sequencer:
//        vseq.start(env.vseqr)
//   4. Inside the virtual sequence:
//        $cast(vseqr, m_sequencer)       → get the virtual sequencer handle
//        sub_seq.start(vseqr.counter_seqr) → run on the real sequencer
//
// Why extend uvm_sequencer with no type parameter?
//   The virtual sequencer itself never generates transactions, so it does not
//   need a transaction type.  We extend the base uvm_sequencer (or
//   uvm_virtual_sequencer if available) with no parameter.
//
// IMPORTANT: counter_seqr is NOT created here.
//   It is assigned in counter_env::connect_phase after the agent's sequencer
//   is built.  Creating it here would produce a second, unconnected sequencer
//   that the driver knows nothing about.
//=============================================================================
class counter_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(counter_virtual_sequencer)

  //--------------------------------------------------------------------------
  // Handle to the real agent sequencer.
  //
  // Declared here, assigned in counter_env::connect_phase.
  // Virtual sequences cast m_sequencer to this class and access counter_seqr
  // to start sub-sequences on the real driver-connected sequencer.
  //--------------------------------------------------------------------------
  uvm_sequencer #(counter_transaction) counter_seqr;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // build_phase — nothing to do; counter_seqr is assigned externally
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

endclass
