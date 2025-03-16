// Code your design here

module adder(
  input clock,
  input reset,
  input [7:0] input_1,input_2,                 
  output reg [15:0] output_3
);


  
  always @(posedge clock or posedge reset) begin
    if(reset) begin
      output_3  <= 16'd0;
    end
    else begin
      output_3 <= input_1 + input_2;
    end
  end

endmodule
