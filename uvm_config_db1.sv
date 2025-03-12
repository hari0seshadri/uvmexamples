// Interface definition
interface my_if(input logic clk);
  logic [7:0] data;
endinterface

// Top module
module top;
  logic clk;
  my_if vif(clk);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // Setting the virtual interface in uvm_config_db
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top", "vif", vif);
  end
endmodule

// Driver class
class my_driver extends uvm_driver#(my_transaction);
  virtual my_if vif;

  function new(string name = "my_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
      `uvm_fatal("MY_DRIVER", "Virtual interface not set in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      vif.data = req.data; // Driving the interface
      seq_item_port.item_done();
    end
  endtask
endclass
