//=============================================================================
// counter_driver.sv  (UPDATED — Lab12: adds analysis port for scoreboard)
//
// UVM driver for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env → counter_agent → counter_driver
//
// Responsibilities:
//   - Pulls counter_transaction items from the sequencer via seq_item_port.
//   - Translates each transaction's test_type into low-level interface task
//     calls (apply_reset, load_counter, count_up, count_down) defined in
//     counter_if.  This keeps timing details out of the driver.
//   - [Lab12 NEW] Publishes each transaction on an analysis port BEFORE
//     driving the DUT.  The scoreboard listens on this port to compute the
//     expected result while the DUT is still executing the stimulus.
//   - Uses a plain 'virtual counter_if' handle (not a modport) so that both
//     the clocking-block outputs (tb_cb.*) and the bare interface tasks are
//     accessible from a single handle.
//
// Lab12 Analysis Port
// -------------------
// The driver now owns an analysis port:
//
//   uvm_analysis_port #(counter_transaction) ap;
//
// It calls ap.write(req) after get_next_item() but BEFORE drive_transaction().
// This ordering matters:
//   T=0 : ap.write(req)         → scoreboard computes expected result
//   T=0+: drive_transaction()   → DUT begins executing the operation
//   T=N : monitor fires         → scoreboard gets actual result to compare
//
// The analysis port is connected in counter_env::connect_phase to the
// scoreboard's stim_imp (and optionally the coverage's analysis_imp).
//
// Virtual interface:
//   Retrieved from uvm_config_db in build_phase (set by counter_tb_top).
//=============================================================================
class counter_driver extends uvm_driver #(counter_transaction);
  `uvm_component_utils(counter_driver)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Ports and handles
  //--------------------------------------------------------------------------

  // Handle to the physical interface — set via config_db in build_phase
  virtual counter_if vif;

  // [Lab12] Analysis port — broadcasts each stimulus transaction to all
  // connected subscribers (scoreboard stim_imp, coverage analysis_imp).
  // Parameterised on counter_transaction so write() accepts our item type.
  uvm_analysis_port #(counter_transaction) ap;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("DRIVER", "Driver object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — retrieve virtual interface and create the analysis port.
  //
  // Both constructions happen in build_phase because that is the earliest
  // phase in which it is safe to create child TLM objects.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve the virtual interface handle from the configuration database.
    // counter_tb_top calls uvm_config_db::set before run_test(), publishing
    // the interface handle under the wildcard path "*".
    if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRIVER", "Could not get vif from config_db — check counter_tb_top")

    // [Lab12] Create the analysis port under this component.
    // "ap" becomes the port's instance name in the UVM hierarchy.
    ap = new("ap", this);
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — main stimulus loop.
  //
  // Continuously fetches transactions from the sequencer:
  //   1. get_next_item()  → blocks until the sequence provides a transaction
  //   2. ap.write(req)    → [Lab12] publish BEFORE driving so scoreboard
  //                         receives the stimulus item and can compute its
  //                         golden (expected) result
  //   3. drive_transaction(req) → translate to interface task calls
  //   4. item_done()      → signal sequencer that the driver is ready for
  //                         the next item (releases arbitration)
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);   // pull next transaction from sequencer

      // [Lab12] Publish stimulus BEFORE driving so that the scoreboard
      // has the transaction fields ready to compute expected results.
      // ap.write() is a zero-time function call — it distributes req to all
      // connected analysis imps immediately, before the first clock edge.
      ap.write(req);

      drive_transaction(req);             // execute the operation on the DUT
      seq_item_port.item_done();          // release sequencer for next item
    end
  endtask

  //--------------------------------------------------------------------------
  // drive_transaction — translates a transaction into interface task calls.
  //
  // Each test_type maps to one or more interface tasks:
  //   TEST_RESET      → apply_reset(1)          — assert/release reset
  //   TEST_LOAD       → load_counter(value)      — parallel-load
  //   TEST_COUNT_UP   → load_counter + count_up  — preload then count
  //   TEST_COUNT_DOWN → load_counter + count_down
  //   TEST_OVERFLOW   → load_counter(MAX) + count_up(1)
  //   TEST_UNDERFLOW  → load_counter(0)   + count_down(1)
  //
  // ovf_flag / unf_flag are local captures required by the interface task
  // API; the scoreboard and coverage use the monitor's observed values.
  //--------------------------------------------------------------------------
  virtual task drive_transaction(counter_transaction tr);
    logic ovf_flag, unf_flag;  // task output ports (not used further here)
    `uvm_info("DRIVER", $sformatf("Driving: %s", tr.convert2string()), UVM_MEDIUM)

    case (tr.test_type)
      TEST_RESET: begin
        // Assert reset for 1 clock cycle then release; idle one extra cycle
        vif.apply_reset(1);
        @(vif.tb_cb);
      end

      TEST_LOAD: begin
        // Parallel-load the specified value into the counter
        vif.load_counter(tr.load_value);
      end

      TEST_COUNT_UP: begin
        // Inline pre-load: set MODE_LOAD for one cycle, then immediately
        // call count_up().  This avoids load_counter()'s explicit LOAD→HOLD
        // transition which would generate a spurious monitor event and
        // misalign the scoreboard's expected-result queue.
        // Mode sequence:  HOLD → LOAD → [LOAD idle] → COUNT_UP×N → HOLD
        //                                                             ↑ one monitor event
        vif.tb_cb.mode      <= MODE_LOAD;
        vif.tb_cb.load_data <= tr.start_count;
        @(vif.tb_cb);   // DUT latches start_count; count_up's first @(tb_cb) wastes one LOAD cycle (harmless)
        vif.count_up(tr.up_cycles, ovf_flag, unf_flag);
      end

      TEST_COUNT_DOWN: begin
        // Same inline pre-load pattern as TEST_COUNT_UP.
        // Mode sequence:  HOLD → LOAD → [LOAD idle] → COUNT_DN×N → HOLD
        vif.tb_cb.mode      <= MODE_LOAD;
        vif.tb_cb.load_data <= tr.start_count;
        @(vif.tb_cb);
        vif.count_down(tr.down_cycles, ovf_flag, unf_flag);
      end

      TEST_OVERFLOW: begin
        // Inline pre-load of COUNTER_MAX (255) then count up once.
        // Mode sequence:  HOLD → LOAD → [LOAD idle] → COUNT_UP×1 → HOLD
        vif.tb_cb.mode      <= MODE_LOAD;
        vif.tb_cb.load_data <= tr.start_count;   // 255 by constraint
        @(vif.tb_cb);
        vif.count_up(1, ovf_flag, unf_flag);
      end

      TEST_UNDERFLOW: begin
        // Inline pre-load of 0 then count down once.
        // Mode sequence:  HOLD → LOAD → [LOAD idle] → COUNT_DN×1 → HOLD
        vif.tb_cb.mode      <= MODE_LOAD;
        vif.tb_cb.load_data <= tr.start_count;   // 0 by constraint
        @(vif.tb_cb);
        vif.count_down(1, ovf_flag, unf_flag);
      end
    endcase
  endtask

endclass
