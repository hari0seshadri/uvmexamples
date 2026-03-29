//=============================================================================
// counter_config.sv  (NEW — Lab12)
//
// UVM configuration object for the counter testbench.
//
// PURPOSE
// -------
// In UVM, a config object is a plain uvm_object (not a component) that
// bundles all knobs and settings for a reusable verification environment.
// The test creates a config object, fills in its fields, then deposits it
// into uvm_config_db so that the environment and sequences can retrieve it.
//
// This avoids hard-coding magic numbers scattered across many files and
// makes it trivial to run the same env with different settings from
// different tests or from the command line.
//
// FIELDS
// ------
//   num_transactions  – how many random transactions counter_random_sequence
//                       should generate.  Default = 20.
//   enable_coverage   – when 1, counter_env creates and connects the
//                       counter_coverage collector.  Default = 1.
//   use_random_test   – informational flag; set to 1 in counter_random_test
//                       so components can query which test variant is active.
//
// UVM HOOKS
// ---------
//   do_copy  – UVM calls this when copy() is called on a config object.
//              Must copy all three fields from the rhs object so that a
//              cloned config is a true deep-copy, not a shallow reference.
//   do_print – UVM calls this from print() / sprint().  Registers each field
//              with the printer so the object dumps cleanly in UVM reports.
//=============================================================================
class counter_config extends uvm_object;
  `uvm_object_utils(counter_config)  // register with UVM factory

  //--------------------------------------------------------------------------
  // Configuration knobs — public, readable by all TB components
  //--------------------------------------------------------------------------
  int  num_transactions = 20;   // random sequence length
  bit  enable_coverage  = 1;    // create coverage collector
  bit  use_random_test  = 0;    // informational: set in counter_random_test

  // Standard UVM constructor
  function new(string name = "counter_config");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // do_copy — deep-copy hook (called by uvm_object::copy()).
  //
  // The base class copy() method calls do_copy() after performing type
  // checking.  We cast the rhs argument to counter_config and copy each
  // field manually.  Without this override, copy() would leave our custom
  // fields at their default values.
  //
  // Usage:  counter_config cfg2 = cfg1.clone();
  //         cfg2.copy(cfg1);   // calls do_copy internally
  //--------------------------------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    counter_config other;
    // Always call super first — copies the object name and other base fields
    super.do_copy(rhs);
    // Cast the generic rhs handle to our concrete type; fatal on mismatch
    if (!$cast(other, rhs))
      `uvm_fatal("CFG", "do_copy: rhs is not a counter_config")
    // Copy all custom fields from the source object
    num_transactions = other.num_transactions;
    enable_coverage  = other.enable_coverage;
    use_random_test  = other.use_random_test;
  endfunction

  //--------------------------------------------------------------------------
  // do_print — printer hook (called by uvm_object::print() / sprint()).
  //
  // The base class print() method calls do_print() after printing the object
  // header.  We register each field with the UVM printer so the object
  // appears in simulation logs like:
  //
  //   counter_config
  //     num_transactions  20
  //     enable_coverage    1
  //     use_random_test    0
  //
  // print_field_int(name, value, bit_width) is the correct API for integer
  // and single-bit fields.  The printer handles formatting (decimal, hex,
  // binary) based on its configuration.
  //--------------------------------------------------------------------------
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    // print_field(name, value, size_bits, radix) — UVM 1.1d / 1.2 compatible API
    printer.print_field("num_transactions", num_transactions,
                        $bits(num_transactions), UVM_DEC);
    printer.print_field("enable_coverage",  enable_coverage,  1, UVM_BIN);
    printer.print_field("use_random_test",  use_random_test,  1, UVM_BIN);
  endfunction

endclass
