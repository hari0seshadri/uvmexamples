//=============================================================================
// counter_env.sv  (UPDATED — Lab12: adds scoreboard, coverage, vseqr, config)
//
// UVM environment for the counter testbench.
//
// Role in the UVM hierarchy:
//   uvm_test_top → counter_env
//
// The environment is the top-level container for all reusable verification
// components.  A well-designed env is test-independent: it provides all the
// infrastructure (agent, checker, coverage) and only requires external tests
// to supply a configuration object and start sequences.
//
// Lab12 additions vs Lab11:
//   counter_config          – knobs: num_transactions, enable_coverage
//   counter_scoreboard      – automated result checker (always created)
//   counter_coverage        – functional coverage collector (conditional)
//   counter_virtual_sequencer – coordination hub for virtual sequences
//
// COMPONENT CREATION (build_phase):
//   1. Retrieve counter_config from config_db (test deposits it before env).
//      Fatal error if not found — env cannot operate without configuration.
//   2. Create agent (always).
//   3. Create scoreboard (always).
//   4. Create virtual sequencer (always — virtual test needs it).
//   5. Create coverage collector ONLY if cfg.enable_coverage == 1.
//      This allows directed tests to skip coverage for speed.
//
// TLM CONNECTIONS (connect_phase):
//   driver.ap    → sb.stim_imp      analysis path: driver→scoreboard stim
//   monitor.ap   → sb.resp_imp      analysis path: monitor→scoreboard resp
//   driver.ap    → cov.analysis_imp analysis path: driver→coverage (if enabled)
//   vseqr.counter_seqr = agent.sequencer   virtual seqr→real seqr assignment
//
// Why driver.ap → coverage (not monitor.ap)?
//   The coverage collector measures STIMULUS coverage (what scenarios were
//   applied).  The driver's transaction has full stimulus fields (test_type,
//   load_value, start_count, etc.).  The monitor's transaction has only
//   result fields (act_count, ovf, unf), which give less rich coverage.
//=============================================================================
class counter_env extends uvm_env;
  `uvm_component_utils(counter_env)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Sub-component handles
  //--------------------------------------------------------------------------
  counter_agent             agent;        // driver + monitor + sequencer
  counter_scoreboard        sb;           // automated checker
  counter_coverage          cov;          // functional coverage (conditional)
  counter_virtual_sequencer vseqr;        // virtual sequencer hub
  counter_config            cfg;          // configuration object (from config_db)

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    `uvm_info("ENV", "Environment object created", UVM_LOW)
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — create all sub-components based on configuration.
  //
  // ORDER MATTERS:
  //   1. Retrieve cfg first — other creation decisions depend on it.
  //   2. Create agent, sb, vseqr unconditionally.
  //   3. Create cov conditionally based on cfg.enable_coverage.
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // ── Step 1: Retrieve configuration ────────────────────────────────────
    // The test deposits a counter_config into config_db before calling
    // super.build_phase.  If it is absent, we cannot configure the env.
    if (!uvm_config_db#(counter_config)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENV",
        "counter_config not found in config_db — counter_test must set it")

    `uvm_info("ENV", $sformatf(
      "Config: num_tx=%0d enable_cov=%0b use_random=%0b",
      cfg.num_transactions, cfg.enable_coverage, cfg.use_random_test),
      UVM_LOW)

    // ── Step 2: Create fixed components ───────────────────────────────────
    agent = counter_agent::type_id::create("agent", this);
    sb    = counter_scoreboard::type_id::create("sb", this);
    vseqr = counter_virtual_sequencer::type_id::create("vseqr", this);

    // ── Step 3: Conditionally create coverage ─────────────────────────────
    // Creating the covergroup object has a small simulation overhead and
    // generates coverage data files.  Skip it for directed regression runs
    // where coverage is not needed.
    if (cfg.enable_coverage)
      cov = counter_coverage::type_id::create("cov", this);
    else
      `uvm_info("ENV", "Coverage collector disabled by cfg.enable_coverage=0", UVM_LOW)

  endfunction

  //--------------------------------------------------------------------------
  // connect_phase — wire TLM analysis paths between components.
  //
  // Analysis connections follow the data flow:
  //   driver (produces stimulus) → scoreboard stim_imp
  //   monitor (produces response) → scoreboard resp_imp
  //   driver (produces stimulus) → coverage analysis_imp (if enabled)
  //
  // The virtual sequencer gets a reference to the real sequencer so that
  // virtual sequences can start sub-sequences on the real driver path.
  //
  // All connections here use 'connect()', which links an analysis port to
  // an analysis export/imp.  Calling connect() on an analysis port is safe
  // to do multiple times — analysis ports support multiple subscribers (fan-out).
  //--------------------------------------------------------------------------
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // ── Scoreboard connections ─────────────────────────────────────────────
    // Driver → scoreboard: stimulus transactions arrive before DUT executes.
    // Scoreboard compute_expected() is called here to set up golden results.
    agent.driver.ap.connect(sb.stim_imp);

    // Monitor → scoreboard: response transactions arrive after DUT completes.
    // Scoreboard write_resp() pops the golden result and compares.
    agent.monitor.ap.connect(sb.resp_imp);

    // ── Coverage connection (conditional) ─────────────────────────────────
    // Driver → coverage: stimulus transactions carry test_type, load_value,
    // start_count, and cycle counts for rich coverpoint measurement.
    if (cfg.enable_coverage)
      agent.driver.ap.connect(cov.analysis_imp);

    // ── Virtual sequencer wiring ───────────────────────────────────────────
    // Assign the real sequencer handle so virtual sequences can start
    // sub-sequences on the driver-connected agent sequencer.
    // This is a simple handle assignment, NOT a TLM port connection.
    vseqr.counter_seqr = agent.sequencer;

  endfunction

endclass
