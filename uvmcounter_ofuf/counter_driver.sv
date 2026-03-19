//=============================================================================
// counter_driver.sv
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
//   - Uses a plain 'virtual counter_if' handle (not a modport) so that both
//     the clocking-block outputs (tb_cb.*) and the bare interface tasks are
//     accessible from a single handle.
//   - Virtual interface handle is retrieved from uvm_config_db in build_phase
//     (set by counter_tb_top before run_test() is called).
//=============================================================================
class counter_driver extends uvm_driver #(counter_transaction);
  `uvm_component_utils(counter_driver)  // register with UVM factory

  // Handle to the physical interface — set via config_db in build_phase
  virtual counter_if vif;

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("DRIVER", "Driver object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — retrieve the virtual interface from the config database.
  // counter_tb_top sets this before run_test(), making it available to all
  // components that ask for "vif" anywhere under the UVM hierarchy.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRIVER", "Could not get vif from config_db — check counter_tb_top")
    end
  endfunction

  //--------------------------------------------------------------------------
  // run_phase — main stimulus loop.
  // Continuously fetches the next transaction from the sequencer and drives
  // it onto the DUT via drive_transaction().  item_done() signals the
  // sequencer that the driver is ready for the next item.
  //--------------------------------------------------------------------------
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);  // blocking get from sequencer
      drive_transaction(req);
      seq_item_port.item_done();         // release sequencer for next item
    end
  endtask

  //--------------------------------------------------------------------------
  // drive_transaction — translates a transaction into interface task calls.
  //
  // Each test_type maps to one or more interface tasks:
  //   TEST_RESET      → apply_reset(1)        — assert/release reset
  //   TEST_LOAD       → load_counter(value)   — parallel-load
  //   TEST_COUNT_UP   → load_counter + count_up(N)
  //   TEST_COUNT_DOWN → load_counter + count_down(N)
  //   TEST_OVERFLOW   → load_counter(MAX) + count_up(1)
  //   TEST_UNDERFLOW  → load_counter(0)   + count_down(1)
  //
  // ovf_flag / unf_flag are local captures of the overflow/underflow signals
  // seen during counting; they satisfy the task's output ports but are not
  // used further here (the monitor observes them independently).
  //--------------------------------------------------------------------------
  virtual task drive_transaction(counter_transaction tr);
    logic ovf_flag, unf_flag;  // local captures for interface task outputs
    `uvm_info("DRIVER", $sformatf("Driving: %s", tr.convert2string()), UVM_LOW)

    case (tr.test_type)
      TEST_RESET: begin
        // Assert reset for 1 clock cycle then release
        vif.apply_reset(1);
        @(vif.tb_cb);   // idle cycle after reset
      end

      TEST_LOAD: begin
        // Parallel-load the specified value into the counter
        vif.load_counter(tr.load_value);
      end

      TEST_COUNT_UP: begin
        // Pre-load start value (skip if 0 to avoid unnecessary LOAD cycle)
        if (tr.start_count != 0)
          vif.load_counter(tr.start_count);
        // Count up for the requested number of cycles
        vif.count_up(tr.up_cycles, ovf_flag, unf_flag);
        @(vif.tb_cb);
      end

      TEST_COUNT_DOWN: begin
        if (tr.start_count != 0)
          vif.load_counter(tr.start_count);
        vif.count_down(tr.down_cycles, ovf_flag, unf_flag);
        @(vif.tb_cb);
      end

      TEST_OVERFLOW: begin
        // Load MAX value then count up once → overflow flag should assert
        vif.load_counter(tr.start_count);
        vif.count_up(1, ovf_flag, unf_flag);
        @(vif.tb_cb);
      end

      TEST_UNDERFLOW: begin
        // Load 0 then count down once → underflow flag should assert
        vif.load_counter(tr.start_count);
        vif.count_down(1, ovf_flag, unf_flag);
        @(vif.tb_cb);
      end
    endcase
  endtask

endclass
