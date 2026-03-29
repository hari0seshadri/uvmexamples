//=============================================================================
// counter_random_test.sv  (NEW — Lab12)
//
// UVM test that replaces the directed sequence with a constrained-random
// sequence using the UVM factory type-override mechanism.
//
// Run with: +UVM_TESTNAME=counter_random_test
//
// PURPOSE
// -------
// The UVM factory allows you to globally replace one class with another
// without modifying the code that creates the original class.  This is the
// "open/closed principle" applied to verification:
//   - Open for extension (new test types via subclassing)
//   - Closed for modification (base classes unchanged)
//
// HOW THE OVERRIDE WORKS
// ----------------------
// counter_test::run_phase creates the stimulus sequence like this:
//
//   seq = counter_sequence::type_id::create("seq")
//
// type_id::create() goes through the UVM factory.  If a type override is
// registered, the factory returns the OVERRIDE type instead of the original.
//
// In this test's build_phase we call:
//
//   counter_sequence::type_id::set_type_override(
//       counter_random_sequence::get_type())
//
// This registers a GLOBAL type override: every request for counter_sequence
// anywhere in the testbench now returns counter_random_sequence instead.
//
// After calling super.build_phase (which runs counter_test::build_phase and
// then counter_env::build_phase), the environment is fully built.
// When run_phase calls create("seq"), the factory silently returns a
// counter_random_sequence — the base test code is completely unchanged.
//
// IMPORTANT: the override must be registered BEFORE super.build_phase().
// If registered after, the environment is already built and the override
// would have no effect on factory calls that already completed.
//
// INSTANCE OVERRIDE (alternative, not used here):
//   counter_sequence::type_id::set_inst_override(
//       counter_random_sequence::get_type(),
//       "uvm_test_top.env.agent.*")
// This replaces only factory calls made from components matching the path
// wildcard, leaving other uses of counter_sequence unchanged.
//=============================================================================
class counter_random_test extends counter_test;
  `uvm_component_utils(counter_random_test)

  // Standard UVM constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  //--------------------------------------------------------------------------
  // build_phase — register factory type override, then build the environment.
  //
  // The override is registered HERE, before super.build_phase(), because:
  //   - super.build_phase() calls counter_test::build_phase which creates the env
  //   - The env's build_phase may also use the factory for agent sub-components
  //   - All factory lookups that happen during and after super.build_phase()
  //     will see the override
  //--------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);

    // Register global type override:
    //   From: counter_sequence (the directed stimulus sequence)
    //   To:   counter_random_sequence (the constrained-random sequence)
    //
    // Effect: counter_sequence::type_id::create("any_name") now returns
    //         a counter_random_sequence object instead.
    counter_sequence::type_id::set_type_override(
        counter_random_sequence::get_type());

    `uvm_info("RNDTEST",
      "Factory override registered: counter_sequence → counter_random_sequence",
      UVM_LOW)

    // Build the rest of the testbench (config, env, agent, etc.)
    // counter_test::build_phase also sets cfg.use_random_test if we modify it.
    super.build_phase(phase);

    // Mark the config so other components can query which test mode is active
    cfg.use_random_test = 1;

  endfunction

endclass
