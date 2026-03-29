//=============================================================================
// counter_monitor.sv  (unchanged from Lab11)
//
// UVM monitor for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env → counter_agent → counter_monitor
//
// Responsibilities:
//   - Passively observes the DUT outputs through the virtual interface.
//     It NEVER drives any signals — it only reads.
//   - Detects when a counter operation has completed by watching for the
//     mode signal transitioning FROM an active mode TO MODE_HOLD.  At that
//     instant the count/overflow/underflow outputs are stable and valid.
//   - Creates a counter_transaction with the observed result values and
//     broadcasts it on the analysis port (ap) so that any connected
//     subscriber (scoreboard resp_imp, logger) receives it automatically.
//
// Detection strategy — mode → HOLD edge:
//   The driver always returns the interface to MODE_HOLD after every
//   operation.  The monitor tracks prev_mode and fires when:
//     current mode == MODE_HOLD  AND  prev_mode != MODE_HOLD
//   This edge detects exactly one capture event per driver operation.
//
//   Timing:
//     The DUT registers the overflow/underflow flags on the same clock edge
//     that performs the last counting step.  When mode goes to HOLD on the
//     following cycle, the registered flags are still visible.  The monitor
//     therefore captures the correct final state at the mode→HOLD transition.
//
// Analysis port connectivity (Lab12):
//   counter_monitor.ap → counter_scoreboard.resp_imp  (check results)
//
// Interface access:
//   Uses plain 'virtual counter_if' (not a modport) to access both the
//   clocking block sampled outputs (tb_cb.count, etc.) and the raw
//   combinational mode signal needed for edge detection.
//=============================================================================
class counter_monitor extends uvm_monitor;
  `uvm_component_utils(counter_monitor)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Ports and state
  //--------------------------------------------------------------------------

  // Handle to the physical interface — set via config_db in build_phase
  virtual counter_if vif;

  // Analysis port — broadcasts observed response transactions to subscribers.
  // In Lab12 this connects to counter_scoreboard.resp_imp.
  uvm_analysis_port #(counter_transaction) ap;

  // Remembers the mode seen in the previous clock cycle for edge detection
  counter_mode_t prev_mode;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("MONITOR", "Monitor object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — retrieve virtual interface and create the analysis port.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif))
      `uvm_fatal("MONITOR", "Could not get vif from config_db — check counter_tb_top")
    // Create the analysis port under this component
    ap = new("ap", this);
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — observation loop.
  //
  // Samples the mode signal on every rising clock edge.  When mode transitions
  // to HOLD (marking the end of a driver operation), captures the stable DUT
  // output signals and broadcasts a response transaction.
  //
  // The observed transaction carries ONLY the result fields (act_count,
  // act_ovf, act_unf).  The scoreboard receives the stimulus separately
  // through the driver's analysis port and correlates them via a FIFO queue.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    prev_mode = MODE_HOLD;   // assume idle at simulation start

    forever begin
      @(posedge vif.tb_cb);   // wait for next rising clock edge

      // Detect falling edge of "active mode" — one operation just completed.
      // vif.mode is sampled directly (not through clocking block) because it
      // is a combinational wire driven by the interface task 1ns after the
      // clock edge, before the next edge where we check it.
      if (vif.mode == MODE_HOLD && prev_mode != MODE_HOLD) begin

        // Create a fresh observed transaction and fill in result fields.
        // type_id::create() goes through the factory so the type can be
        // overridden in tests if needed.
        counter_transaction obs = counter_transaction::type_id::create("obs");

        // Sample DUT outputs via the clocking block (input #1ns skew gives
        // a stable, glitch-free view of the registered DUT outputs).
        obs.act_count = vif.tb_cb.count;       // observed count value
        obs.act_ovf   = vif.tb_cb.overflow;    // observed overflow flag
        obs.act_unf   = vif.tb_cb.underflow;   // observed underflow flag

        `uvm_info("MONITOR",
          $sformatf("Observed: count=%0d ovf=%0b unf=%0b",
                    obs.act_count, obs.act_ovf, obs.act_unf), UVM_MEDIUM)

        // Broadcast to all connected analysis port subscribers.
        // Each subscriber's write() method is called synchronously.
        ap.write(obs);
      end

      prev_mode = vif.mode;   // update for next cycle's edge detection
    end
  endtask

endclass
