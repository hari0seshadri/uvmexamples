//=============================================================================
// counter_virtual_test.sv  (NEW — Lab12)
//
// UVM test that demonstrates the virtual sequence / virtual sequencer pattern.
//
// Run with: +UVM_TESTNAME=counter_virtual_test
//
// PURPOSE
// -------
// This test overrides run_phase to start a counter_virtual_sequence on the
// environment's virtual sequencer (env.vseqr) rather than starting a real
// sequence directly on the agent's sequencer.
//
// VIRTUAL SEQUENCE PATTERN BENEFITS
// ----------------------------------
// 1. Separation of concerns:
//    - The virtual sequence decides the HIGH-LEVEL PLAN
//      (which sub-sequences to run and in what order / concurrently)
//    - The real sequences decide the LOW-LEVEL PROTOCOL
//      (how to translate a transaction into pin-level stimulus)
//    - The test just says "start the plan"
//
// 2. Scalability:
//    - In a multi-agent testbench (CPU + memory + peripherals), the virtual
//      sequence can coordinate all three agents by starting sub-sequences on
//      each agent's sequencer through the virtual sequencer handles.
//    - Adding a new agent means adding one handle to the virtual sequencer
//      and potentially starting new sub-sequences — not rewriting tests.
//
// 3. Reusability:
//    - The virtual sequence can be reused across different tests by varying
//      only the sub-sequences it starts (directed vs random vs corner-case).
//
// HOW IT WORKS
// ------------
//   counter_test::build_phase creates env (which creates env.vseqr)
//   counter_env::connect_phase assigns env.vseqr.counter_seqr = agent.sequencer
//
//   run_phase here:
//     vseq = counter_virtual_sequence::type_id::create("vseq")
//     vseq.start(env.vseqr)        ← note: virtual sequencer, not agent seqr
//
//   Inside counter_virtual_sequence::body():
//     $cast(vseqr, m_sequencer)    ← m_sequencer IS env.vseqr
//     dir_seq.start(vseqr.counter_seqr)  ← directed on the REAL sequencer
//     rnd_seq.start(vseqr.counter_seqr)  ← random on the REAL sequencer
//=============================================================================
class counter_virtual_test extends counter_test;
  `uvm_component_utils(counter_virtual_test)

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — start the virtual sequence on the virtual sequencer.
  //
  // This completely overrides counter_test::run_phase.  We do NOT call
  // super.run_phase() because the base run_phase would also start
  // counter_sequence on the agent sequencer, causing a double run.
  //
  // drain delay #100: gives the last transaction time to propagate through
  // the DUT and be captured by the monitor before the objection drops.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    counter_virtual_sequence vseq;

    phase.raise_objection(this);   // prevent premature simulation end

    // Create the virtual sequence through the factory.
    // Factory creation allows type overrides if a test needs to swap in
    // a different virtual sequence without modifying this file.
    vseq = counter_virtual_sequence::type_id::create("vseq");

    `uvm_info("VTEST",
      "Starting counter_virtual_sequence on env.vseqr", UVM_LOW)

    // Start the virtual sequence on the VIRTUAL SEQUENCER (env.vseqr).
    // If started on the agent sequencer instead, the $cast inside
    // counter_virtual_sequence::body() would fail because m_sequencer
    // would be a uvm_sequencer#(counter_transaction), not a
    // counter_virtual_sequencer.
    vseq.start(env.vseqr);

    `uvm_info("VTEST", "Virtual sequence complete", UVM_LOW)

    #100;                          // drain last monitor capture
    phase.drop_objection(this);   // allow cleanup phases to begin
  endtask

endclass
