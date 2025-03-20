class my_dut_config extends uvm_object;
  `uvm_object_utils(my_dut_config) // Correct usage of the macro

  virtual dut_if dut_vi; // Virtual interface to the DUT

  // Constructor
  function new(string name = "my_dut_config");
    super.new(name);
  endfunction

  // Optionally add other configuration fields as needed
endclass