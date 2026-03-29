//=============================================================================
// counter_virtual_sequence.sv  (NEW — Lab12)
//
// Virtual sequence for the counter testbench.
//
// PURPOSE
// -------
// A virtual sequence runs on a virtual sequencer rather than directly on a
// driver-connected sequencer.  It coordinates sub-sequences that each run on
// real (agent) sequencers.  This separates the "what order to run" logic
// (virtual sequence) from the "how to drive" logic (driver + real sequences).
//
// In a multi-agent testbench a virtual sequence could interleave operations
// on, say, the CPU agent and the memory agent.  Here we demonstrate the
// pattern with a two-phase stimulus plan on a single counter agent:
//
//   Phase 1: run counter_sequence (6 directed transactions — corner cases)
//   Phase 2: run counter_random_sequence (20 random transactions — breadth)
//
// This plan verifies corner cases explicitly, then adds random coverage on
// top — a typical industry regression strategy.
//
// VIRTUAL SEQUENCER INTERACTION
// ------------------------------
// A virtual sequence is started on the virtual sequencer:
//   vseq.start(env.vseqr)
//
// Inside body(), m_sequencer is the sequencer the sequence is running on.
// We cast it to counter_virtual_sequencer to access the counter_seqr handle:
//
//   $cast(vseqr, m_sequencer)
//   sub_seq.start(vseqr.counter_seqr)   ← starts on the REAL sequencer
//
// The sub-sequence runs to completion before the next sub-sequence starts.
// They are sequential here; in a multi-agent env they could be forked.
//
// CAST SAFETY
// -----------
// $cast() is used instead of direct assignment because m_sequencer is typed
// as uvm_sequencer_base (base class).  If the wrong sequencer was passed to
// start(), $cast returns 0 and we report an error rather than getting a
// null-pointer crash later.
//=============================================================================
class counter_virtual_sequence extends uvm_sequence #(counter_transaction);
  `uvm_object_utils(counter_virtual_sequence)

  // Standard UVM sequence constructor
  function new(string name = "counter_virtual_sequence");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // body — two-phase stimulus plan executed on the virtual sequencer.
  //--------------------------------------------------------------------------
  virtual task body();
    counter_virtual_sequencer vseqr;
    counter_sequence          dir_seq;
    counter_random_sequence   rnd_seq;

    // ── Step 1: cast m_sequencer to virtual sequencer ─────────────────────
    // m_sequencer is set by the UVM framework when start(env.vseqr) is called.
    // It is typed as uvm_sequencer_base.  We need the counter_virtual_sequencer
    // subclass to access the counter_seqr handle.
    //
    // If $cast fails, the wrong sequencer was passed to start().  This is a
    // testbench configuration error — report it clearly and abort.
    if (!$cast(vseqr, m_sequencer)) begin
      `uvm_fatal("VSEQ",
        "body: $cast to counter_virtual_sequencer failed — check that vseq.start(env.vseqr) was called")
    end

    `uvm_info("VSEQ", "Virtual sequence started on virtual sequencer", UVM_LOW)

    // ── Phase 1: directed sequence ────────────────────────────────────────
    // Run the six directed corner-case transactions first.
    // Sequences are created through the factory so that factory overrides
    // (if any) are respected at the sub-sequence level too.
    dir_seq = counter_sequence::type_id::create("dir_seq");
    `uvm_info("VSEQ", "Phase 1: starting directed counter_sequence", UVM_LOW)
    dir_seq.start(vseqr.counter_seqr);   // start on REAL sequencer
    `uvm_info("VSEQ", "Phase 1: directed sequence complete", UVM_LOW)

    // ── Phase 2: random sequence ──────────────────────────────────────────
    // Follow up with random transactions to broaden stimulus coverage.
    // start() blocks until all transactions in rnd_seq are sent and
    // acknowledged by the driver.
    rnd_seq = counter_random_sequence::type_id::create("rnd_seq");
    `uvm_info("VSEQ", "Phase 2: starting counter_random_sequence", UVM_LOW)
    rnd_seq.start(vseqr.counter_seqr);   // same real sequencer
    `uvm_info("VSEQ", "Phase 2: random sequence complete", UVM_LOW)

    `uvm_info("VSEQ", "Virtual sequence body complete", UVM_LOW)
  endtask

endclass
