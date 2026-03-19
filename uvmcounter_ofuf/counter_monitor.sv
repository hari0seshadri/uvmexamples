//=============================================================================
// counter_monitor.sv
//
// UVM monitor for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env → counter_agent → counter_monitor
//
// Responsibilities:
//   - Passively observes the DUT outputs through the virtual interface.
//     It never drives any signals.
//   - Detects when a counter operation has completed by watching for the
//     mode signal transitioning FROM an active mode TO MODE_HOLD.  At that
//     instant the count/overflow/underflow outputs are stable and ready to
//     be captured.
//   - Creates a counter_transaction with the observed values and broadcasts
//     it on the analysis port (ap) so that any connected subscriber
//     (scoreboard, coverage collector, logger) receives it automatically.
//
// Detection strategy — mode → HOLD edge:
//   The driver always returns the interface to MODE_HOLD after every
//   operation.  The monitor tracks prev_mode and fires when:
//     current mode == MODE_HOLD  AND  prev_mode != MODE_HOLD
//   This edge detects exactly one capture event per driver operation.
//
// Interface access:
//   Uses plain 'virtual counter_if' (not a modport) to access both the
//   clocking block sampled outputs (tb_cb.count, etc.) and the raw
//   combinational mode signal needed for edge detection.
//=============================================================================
class counter_monitor extends uvm_monitor;
  `uvm_component_utils(counter_monitor)  // register with UVM factory

  // Handle to the physical interface — set via config_db in build_phase
  virtual counter_if vif;

  // Analysis port — broadcasts observed transactions to subscribers
  // (scoreboard, functional coverage, etc.)
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
    if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MONITOR", "Could not get vif from config_db — check counter_tb_top")
    end
    ap = new("ap", this);   // create analysis port under this component
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — observation loop.
  // Samples DUT outputs on every rising clock edge.  When mode transitions
  // to HOLD (end of an operation), captures the stable outputs and broadcasts
  // a transaction on the analysis port.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    prev_mode = MODE_HOLD;   // initialise: assume idle at time 0

    forever begin
      @(posedge vif.tb_cb);   // wait for next rising clock edge

      // Detect falling edge of "active mode" — operation just completed
      if (vif.mode == MODE_HOLD && prev_mode != MODE_HOLD) begin
        // Capture DUT outputs sampled through the clocking block
        counter_transaction obs = counter_transaction::type_id::create("obs");
        obs.act_count = vif.tb_cb.count;       // sampled count value
        obs.act_ovf   = vif.tb_cb.overflow;    // sampled overflow flag
        obs.act_unf   = vif.tb_cb.underflow;   // sampled underflow flag

        `uvm_info("MONITOR",
          $sformatf("Captured: count=%0d ovf=%0b unf=%0b",
                    obs.act_count, obs.act_ovf, obs.act_unf), UVM_LOW)

        ap.write(obs);   // broadcast to all analysis port subscribers
      end

      prev_mode = vif.mode;   // update for next cycle's edge detection
    end
  endtask

endclass
