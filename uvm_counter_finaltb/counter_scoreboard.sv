//=============================================================================
// counter_scoreboard.sv  (NEW — Lab12)
//
// UVM scoreboard for the counter testbench.
//
// PURPOSE
// -------
// A scoreboard automatically checks that the DUT produces the correct output
// for every input applied.  Without a scoreboard, the engineer must inspect
// waveforms manually — which is error-prone and does not scale.
//
// DUAL ANALYSIS-IMP PATTERN
// --------------------------
// The scoreboard receives transactions from TWO sources:
//   1. counter_driver.ap (stimulus)  → write_stim()
//   2. counter_monitor.ap (response) → write_resp()
//
// A UVM component can only have ONE write() method by default.  To add a
// second, we use the `uvm_analysis_imp_decl macro, which generates a
// specialised analysis-imp class with a suffixed write method:
//
//   `uvm_analysis_imp_decl(_stim)   → class uvm_analysis_imp_stim
//                                      calls write_stim() on the parent
//   `uvm_analysis_imp_decl(_resp)   → class uvm_analysis_imp_resp
//                                      calls write_resp() on the parent
//
// IMPORTANT: these macros must be placed OUTSIDE the class declaration and
// at package scope so they expand into unique class definitions.  In this
// testbench they appear in counter_scoreboard.sv before the class, and
// since that file is `include`d inside counter_pkg, they compile at package
// scope automatically.
//
// OPERATION FLOW
// --------------
//   Time 0 (before DUT execution):
//     driver calls ap.write(tr)  → write_stim(tr) fires
//     write_stim computes the GOLDEN result for tr and pushes it to exp_q
//
//   Time N (after DUT finishes):
//     monitor calls ap.write(obs) → write_resp(obs) fires
//     write_resp pops the oldest expected result from exp_q and compares
//     act_count / act_ovf / act_unf against the golden values
//
//   The FIFO queue exp_q keeps stimulus and response in order because the
//   driver always publishes before the monitor (driver publishes at time 0,
//   monitor fires N cycles later after mode→HOLD).
//
// EXPECTED RESULT COMPUTATION
// ---------------------------
//   compute_expected() is a pure function that maps stimulus fields to
//   expected output using counter arithmetic.  It is the "golden model".
//
//   Overflow / underflow detection:
//     The DUT registers overflow = 1 when the LAST counting step crosses
//     the wrap boundary.  For count_up: overflow fires on the cycle that
//     takes the counter from 255 to 0.  Mathematically:
//
//       exp_ovf = ((start_count + up_cycles) % 256 == 0)
//
//     This works for single and multiple wraps because it asks "does the
//     final count land exactly on 0?" — which is true iff the last cycle
//     was a 255→0 transition.
//
//     Similarly for underflow:
//       exp_unf = ((start_count - down_cycles + 1) % 256 == 0)
//     This asks "was the counter at 0 just before the last decrement?"
//=============================================================================

// ──────────────────────────────────────────────────────────────────────────────
// Dual analysis-imp declarations — MUST be at package scope (outside class).
// `uvm_analysis_imp_decl(_stim) generates:
//   class uvm_analysis_imp_stim #(type T, type IMP) extends uvm_port_base
//   whose write() method calls imp.write_stim(t)
// `uvm_analysis_imp_decl(_resp) similarly generates write_resp dispatch.
// ──────────────────────────────────────────────────────────────────────────────
`uvm_analysis_imp_decl(_stim)   // creates uvm_analysis_imp_stim class
`uvm_analysis_imp_decl(_resp)   // creates uvm_analysis_imp_resp class

//=============================================================================
// counter_scoreboard — the checker component
//=============================================================================
class counter_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(counter_scoreboard)

  //--------------------------------------------------------------------------
  // Analysis imps — two input ports, each dispatching to a different method.
  //
  // stim_imp: connected to counter_driver.ap in counter_env::connect_phase.
  //           Any transaction written here calls this.write_stim().
  // resp_imp: connected to counter_monitor.ap in counter_env::connect_phase.
  //           Any transaction written here calls this.write_resp().
  //--------------------------------------------------------------------------
  uvm_analysis_imp_stim #(counter_transaction, counter_scoreboard) stim_imp;
  uvm_analysis_imp_resp #(counter_transaction, counter_scoreboard) resp_imp;

  //--------------------------------------------------------------------------
  // Expected-result FIFO queue.
  //
  // Each write_stim() pushes a transaction carrying the golden (expected)
  // result fields.  Each write_resp() pops the oldest entry and compares.
  // Using a queue (SystemVerilog dynamic array FIFO) gives O(1) push/pop
  // and preserves transaction ordering automatically.
  //--------------------------------------------------------------------------
  counter_transaction exp_q[$];   // queue of expected (golden) transactions

  //--------------------------------------------------------------------------
  // Pass/fail counters — printed at the end of simulation
  //--------------------------------------------------------------------------
  int pass_count = 0;
  int fail_count = 0;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — create both analysis imps.
  //
  // The second argument to the constructor is the parent (this scoreboard).
  // The imp stores this reference so that when write() is called on the imp,
  // it can call this.write_stim() or this.write_resp() on the scoreboard.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    stim_imp = new("stim_imp", this);   // receives stimulus from driver
    resp_imp = new("resp_imp", this);   // receives response from monitor
  endfunction

  //--------------------------------------------------------------------------
  // write_stim — called when the driver publishes a stimulus transaction.
  //
  // Steps:
  //   1. Create a new expected transaction object
  //   2. Call compute_expected() to fill in the golden result fields
  //   3. Push onto exp_q for later comparison in write_resp()
  //
  // Note: tr is the original stimulus item from the driver.  We create a
  // separate exp_tr to hold just the expected result, keeping concerns
  // separated and avoiding aliasing the driver's item.
  //--------------------------------------------------------------------------
  virtual function void write_stim(counter_transaction tr);
    counter_transaction exp_tr;

    // TEST_RESET: the driver calls apply_reset() which leaves mode=HOLD.
    // Because mode starts at HOLD and never transitions FROM a non-HOLD mode
    // back TO HOLD, the monitor never fires for a reset transaction.
    // Pushing an expected entry here would permanently stall the queue.
    if (tr.test_type == TEST_RESET) begin
      `uvm_info("SB_STIM", "TEST_RESET: no monitor event expected — skipping queue push",
                UVM_MEDIUM)
      return;
    end

    exp_tr = counter_transaction::type_id::create("exp_tr");

    // Compute expected output fields for this stimulus
    compute_expected(tr, exp_tr.act_count, exp_tr.act_ovf, exp_tr.act_unf);

    // Enqueue the expected result for matching with the response
    exp_q.push_back(exp_tr);

    `uvm_info("SB_STIM", $sformatf(
      "Stim received: %s | expected count=%0d ovf=%0b unf=%0b",
      tr.convert2string(), exp_tr.act_count, exp_tr.act_ovf, exp_tr.act_unf),
      UVM_HIGH)
  endfunction

  //--------------------------------------------------------------------------
  // write_resp — called when the monitor publishes an observed transaction.
  //
  // Steps:
  //   1. Check that the expected queue is not empty (protocol error otherwise)
  //   2. Pop the oldest expected result from the FIFO queue
  //   3. Compare each result field; print PASS or FAIL accordingly
  //   4. Increment pass_count or fail_count for the final tally
  //--------------------------------------------------------------------------
  virtual function void write_resp(counter_transaction obs);
    counter_transaction exp_tr;

    // Guard: the stimulus must have arrived before the response.
    // If the queue is empty, there is a stimulus-response ordering bug.
    if (exp_q.size() == 0) begin
      `uvm_error("SB_RESP", "Response received but expected queue is empty!")
      return;
    end

    // Pop the oldest expected result (FIFO order matches driver sequence)
    exp_tr = exp_q.pop_front();

    // Compare count value
    if (obs.act_count === exp_tr.act_count) begin
      `uvm_info("SB_PASS",
        $sformatf("PASS count: got %0d, expected %0d",
                  obs.act_count, exp_tr.act_count), UVM_MEDIUM)
      pass_count++;
    end else begin
      `uvm_error("SB_FAIL",
        $sformatf("FAIL count: got %0d, expected %0d",
                  obs.act_count, exp_tr.act_count))
      fail_count++;
    end

    // Compare overflow flag
    if (obs.act_ovf === exp_tr.act_ovf) begin
      `uvm_info("SB_PASS",
        $sformatf("PASS ovf: got %0b, expected %0b",
                  obs.act_ovf, exp_tr.act_ovf), UVM_MEDIUM)
    end else begin
      `uvm_error("SB_FAIL",
        $sformatf("FAIL ovf: got %0b, expected %0b",
                  obs.act_ovf, exp_tr.act_ovf))
      fail_count++;
    end

    // Compare underflow flag
    if (obs.act_unf === exp_tr.act_unf) begin
      `uvm_info("SB_PASS",
        $sformatf("PASS unf: got %0b, expected %0b",
                  obs.act_unf, exp_tr.act_unf), UVM_MEDIUM)
    end else begin
      `uvm_error("SB_FAIL",
        $sformatf("FAIL unf: got %0b, expected %0b",
                  obs.act_unf, exp_tr.act_unf))
      fail_count++;
    end
  endfunction

  //--------------------------------------------------------------------------
  // compute_expected — golden reference model for the counter DUT.
  //
  // Given the stimulus transaction tr, fills in exp_count, exp_ovf, exp_unf
  // with the values that a correct counter implementation must produce.
  //
  // Uses modular arithmetic:
  //   For COUNT_UP:
  //     final_count = (start_count + up_cycles) % 256
  //     overflow    = 1 iff last step was 255→0
  //                 = ((start_count + up_cycles) % 256 == 0)
  //   For COUNT_DOWN:
  //     final_count = (start_count - down_cycles + 256*N) % 256
  //     underflow   = 1 iff last step was 0→255
  //                 = ((start_count - down_cycles + 1) % 256 == 0)
  //--------------------------------------------------------------------------
  virtual function void compute_expected(
    counter_transaction tr,
    output logic [COUNTER_WIDTH-1:0] exp_count,
    output logic exp_ovf,
    output logic exp_unf);

    int sum;   // signed integer for intermediate arithmetic

    // Default: no flags
    exp_ovf = 0;
    exp_unf = 0;

    case (tr.test_type)

      TEST_RESET: begin
        // Reset drives the counter and all flags to 0
        exp_count = 0;
      end

      TEST_LOAD: begin
        // Parallel load: final count equals load_value, no flags
        exp_count = tr.load_value;
      end

      TEST_COUNT_UP: begin
        // start_count guaranteed > 0 by constraint; load always happens.
        sum       = int'(tr.start_count) + tr.up_cycles;
        exp_count = sum % 256;
        // Overflow fires on last step iff that step was 255→0,
        // which happens when (start + N) is a multiple of 256.
        exp_ovf   = (sum % 256 == 0) ? 1'b1 : 1'b0;
      end

      TEST_COUNT_DOWN: begin
        // start_count guaranteed > 0 by constraint; load always happens.
        sum       = int'(tr.start_count) - tr.down_cycles;
        // Convert to unsigned modular result using % and correction for negatives
        exp_count = (sum % 256 + 256) % 256;
        // Underflow fires on last step iff that step was 0→255,
        // which happens when (start - N + 1) ≡ 0 (mod 256),
        // i.e., (start - N + 1 + 256*K) % 256 == 0 for some K.
        begin
          int last_pre_dec = (int'(tr.start_count) - tr.down_cycles + 1);
          exp_unf = ((last_pre_dec % 256 + 256) % 256 == 0) ? 1'b1 : 1'b0;
        end
      end

      TEST_OVERFLOW: begin
        // start_count == COUNTER_MAX (255) by constraint; count_up(1)
        // → 255 + 1 = 0 (mod 256), overflow fires on that last step
        exp_count = 8'h00;
        exp_ovf   = 1'b1;
      end

      TEST_UNDERFLOW: begin
        // start_count == 0 by constraint; count_down(1)
        // → 0 - 1 = 255 (mod 256), underflow fires on that last step
        exp_count = COUNTER_MAX;
        exp_unf   = 1'b1;
      end

    endcase
  endfunction

  //--------------------------------------------------------------------------
  // report_phase — print a pass/fail summary at the end of simulation.
  //
  // report_phase runs after run_phase completes (all objections dropped).
  // It gives a clean top-level summary in the simulation log, which is
  // easier to grep for than individual UVM_INFO/UVM_ERROR messages.
  //--------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD",
      $sformatf("=== Scoreboard Summary: %0d PASS, %0d FAIL ===",
                pass_count, fail_count),
      UVM_NONE)
    if (fail_count > 0)
      `uvm_error("SCOREBOARD", "One or more scoreboard checks FAILED")
  endfunction

endclass
