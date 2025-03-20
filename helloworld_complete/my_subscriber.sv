 class my_subscriber extends uvm_subscriber #(my_transaction);
  
    `uvm_component_utils(my_subscriber)
    
    bit cmd;
    int addr;
    int data;
        
    covergroup cover_bus;
      coverpoint cmd;
      coverpoint addr { 
        bins a[16] = {[0:255]};
      }
      coverpoint data {
        bins d[16] = {[0:255]};
      }
    endgroup: cover_bus
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
      cover_bus = new;  
    endfunction: new

    function void write(my_transaction t);
      `uvm_info("mg", $psprintf("Subscriber received tx %s", t.convert2string()), UVM_NONE);
      
      cmd  = t.cmd;
      addr = t.addr;
      data = t.data;
      cover_bus.sample();
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