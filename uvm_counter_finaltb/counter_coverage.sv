//=============================================================================
// counter_coverage.sv  (NEW — Lab12)
//
// UVM functional coverage collector for the counter testbench.
//
// PURPOSE
// -------
// Code coverage (line/branch/toggle) tells you which RTL statements were
// exercised.  Functional coverage tells you which STIMULUS SCENARIOS were
// applied.  You can have 100% code coverage with a single directed test yet
// miss important corner cases.  Functional coverage closes that gap.
//
// This collector measures:
//   - Which test types were exercised (all 6 should be covered)
//   - The distribution of load_value / start_count (zero, small, mid, large)
//   - The distribution of cycle counts for count_up and count_down
//   - Cross coverage: test_type × value_range (are all combinations tried?)
//
// CONNECTIVITY
// ------------
// The coverage collector extends uvm_component and declares its own
// uvm_analysis_imp to receive stimulus transactions from the driver.
// In counter_env::connect_phase:
//
//   counter_driver.ap → counter_coverage.analysis_imp
//
// The driver's stimulus transactions carry the full test_type, load_value,
// start_count, up_cycles, and down_cycles fields needed for rich coverage.
//
// NOTE: We extend uvm_component (not uvm_subscriber) and declare the
// analysis_imp explicitly.  uvm_subscriber is a thin wrapper that requires
// the write() argument to be named 't' (matching the base class signature).
// Extending uvm_component directly avoids that naming constraint and is
// the pattern used consistently in this testbench's reference design.
//
// CONDITIONAL CREATION
// --------------------
// counter_env creates this component only when cfg.enable_coverage == 1.
//
// COVERGROUP DESIGN
// -----------------
// cp_test_type: 6 explicit bins, one per test_type_t value.
// cp_value:     4 value-range bins for load_value / start_count.
// cp_cycles:    3 bins for up_cycles / down_cycles.
// cx_type_val:  cross cp_test_type × cp_value → 6×4 = 24 bins.
//=============================================================================

// analysis_imp declaration for the single write() port on coverage.
// This macro is placed OUTSIDE the class at package scope.
// It generates class uvm_analysis_imp_cov that calls parent.write_cov(t).
`uvm_analysis_imp_decl(_cov)

class counter_coverage extends uvm_component;
  `uvm_component_utils(counter_coverage)

  //--------------------------------------------------------------------------
  // Analysis imp — receives stimulus transactions from the driver's ap.
  // Connected in counter_env::connect_phase:
  //   agent.driver.ap.connect(cov.analysis_imp)
  //--------------------------------------------------------------------------
  uvm_analysis_imp_cov #(counter_transaction, counter_coverage) analysis_imp;

  //--------------------------------------------------------------------------
  // Sample variables — updated by write_cov() before calling sample().
  //
  // A covergroup samples its coverpoints at the moment sample() is called.
  // The coverpoints reference these class variables, so we copy transaction
  // fields into them first, then call sample().
  //--------------------------------------------------------------------------
  test_type_t                cv_test_type;    // current test type
  logic [COUNTER_WIDTH-1:0]  cv_value;        // load_value or start_count
  int                        cv_cycles;       // up_cycles or down_cycles

  //--------------------------------------------------------------------------
  // Covergroup definition
  //
  // Declared inline as a class member.  Instantiated in new() using
  // counter_cg = new().
  //--------------------------------------------------------------------------
  covergroup counter_cg;

    //-- Which test scenario was applied? ------------------------------------
    cp_test_type: coverpoint cv_test_type {
      bins reset     = {TEST_RESET};       // reset scenario
      bins load      = {TEST_LOAD};        // parallel load
      bins count_up  = {TEST_COUNT_UP};    // normal count-up
      bins count_dn  = {TEST_COUNT_DOWN};  // normal count-down
      bins overflow  = {TEST_OVERFLOW};    // wrap-around up
      bins underflow = {TEST_UNDERFLOW};   // wrap-around down
    }

    //-- Was the value range exercised for load/count start? ----------------
    cp_value: coverpoint cv_value {
      bins zero = {0};           // boundary: zero value
      bins low  = {[1:63]};      // lower quarter of range
      bins mid  = {[64:191]};    // middle half of range
      bins high = {[192:255]};   // upper quarter of range
    }

    //-- How many cycles were counted? (count tests only) -------------------
    cp_cycles: coverpoint cv_cycles {
      bins one  = {1};        // single-step count
      bins few  = {[2:4]};    // short count sequence
      bins many = {[5:10]};   // longer count sequence
      ignore_bins zero_cycles = {0};  // not a counting operation
    }

    //-- Cross: every test type applied across the full value range ----------
    cx_type_val: cross cp_test_type, cp_value;

  endgroup : counter_cg

  // Standard UVM constructor — also instantiates the covergroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    // Covergroups must be instantiated in new() — they cannot be created
    // in build_phase because they are not UVM objects.
    counter_cg = new();
    `uvm_info("COV", "Coverage collector created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — create the analysis imp.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_imp = new("analysis_imp", this);
  endfunction

  //--------------------------------------------------------------------------
  // write_cov — called automatically when a transaction is written to
  // this component's analysis_imp (via the _cov suffix dispatch).
  //
  // Steps:
  //   1. Copy relevant fields into the sample variables
  //   2. Call counter_cg.sample() to record coverage at this instant
  //--------------------------------------------------------------------------
  virtual function void write_cov(counter_transaction tr);
    // Copy test_type for the cp_test_type coverpoint
    cv_test_type = tr.test_type;

    // Choose the most meaningful value field based on test type
    case (tr.test_type)
      TEST_LOAD:                      cv_value = tr.load_value;
      TEST_COUNT_UP, TEST_COUNT_DOWN,
      TEST_OVERFLOW, TEST_UNDERFLOW:  cv_value = tr.start_count;
      default:                        cv_value = 0;
    endcase

    // Choose the most meaningful cycle count based on test type
    case (tr.test_type)
      TEST_COUNT_UP:   cv_cycles = tr.up_cycles;
      TEST_COUNT_DOWN: cv_cycles = tr.down_cycles;
      TEST_OVERFLOW:   cv_cycles = 1;
      TEST_UNDERFLOW:  cv_cycles = 1;
      default:         cv_cycles = 0;
    endcase

    // Sample the covergroup — records which bins were hit
    counter_cg.sample();

    `uvm_info("COV",
      $sformatf("Sampled: type=%s val=%0d cycles=%0d  coverage=%.1f%%",
                tr.test_type.name(), cv_value, cv_cycles,
                counter_cg.get_coverage()),
      UVM_HIGH)
  endfunction

  //--------------------------------------------------------------------------
  // report_phase — print functional coverage summary at end of simulation.
  //--------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("COV",
      $sformatf("=== Functional Coverage: %.1f%% ===", counter_cg.get_coverage()),
      UVM_NONE)
  endfunction

endclass
