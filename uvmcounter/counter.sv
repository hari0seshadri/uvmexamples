// Code your design here
module counter_load(clk,rst,load,data_out,data_in);
  
  input rst,clk,load;
  input [3:0] data_in;
  output [3:0] data_out;
  
  reg [3:0] data_out;
  
  always @(posedge clk or posedge rst)
    begin
      if (rst)
        data_out <= 4'b0;
      else if (load)
        data_out <= data_in;
      else if (data_out == 4'd12)
        data_out <= 0;
      else
        data_out <= data_out+1;
    end
  
  
endmodule
