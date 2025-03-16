// Code your testbench here
// or browse Examples
//Top Module
module counter_top ();
import counter_pkg::*;
import uvm_pkg::*;

parameter cycle =10;

reg clk;
counter_inf DUT_INF (clk);
counter_load DUv (.clk (clk),
.rst (DUT_INF.rst),
.load (DUT_INF.load),
.data_out(DUT_INF.data_out),
                  .data_in(DUT_INF.data_in));
initial
begin
  $dumpfile("dump.vcd"); $dumpvars;
uvm_config_db # (virtual counter_inf)::set (null,"*", "vif", DUT_INF);

  run_test("counter_test_1");
end
//Generate the clock
initial
begin
clk=1'b0;
forever
  # (cycle/2) clk=~clk;

end
  
  initial
    #700 $finish; //hari
  
  
endmodule