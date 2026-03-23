class my_subscriber extends uvm_subscriber #(my_transaction);
  `uvm_component_utils(my_subscriber)

  bit cmd;
  int addr;
  int data;

  // Covergroup for bus signals
  covergroup cover_bus;
    coverpoint cmd;
    coverpoint addr {
      bins a[16] = {[0:255]};   // 16 bins covering the address range
    }
    coverpoint data {
      bins d[16] = {[0:255]};   // 16 bins covering the data range
    }
  endgroup: cover_bus

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cover_bus = new;   // Instantiate covergroup
  endfunction: new

  // Called whenever a transaction is written to the subscriber's analysis export
  function void write(my_transaction t);
    `uvm_info("mg", $psprintf("Subscriber received tx %s", t.convert2string()), UVM_NONE)

    cmd  = t.cmd;
    addr = t.addr;
    data = t.data;
    cover_bus.sample();   // Sample coverage

    // Optional scoreboard code could be placed here (commented out example)
    /*
    begin
      my_transaction expected;
      expected = new;
      expected.copy(t);
      if ( !t.compare(expected))
        `uvm_error("mg", "Transaction differs from expected");
    end
    */
  endfunction: write
endclass: my_subscriber
