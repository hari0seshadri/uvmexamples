//Interface
interface counter_inf (input bit clock);
logic [3:0] data_in;
logic [3:0] data_out;
logic load;
logic rst;
//Driver Clocking Block
clocking driver_cb @ (posedge clock);
default input #1 output #1;
output rst;
output data_in;
output load;
endclocking
// output monitor clocking block
clocking output_mon_cb @ (posedge clock); default input #1 output #1 ;
input data_out;
endclocking
//input monitor clocking block
clocking input_mon_cb @ (posedge clock);
default input #1 output #1;
input load;
input rst;
input data_in;
endclocking
//driver modport
modport DRIVER (clocking driver_cb);
//input Monitor modport
modport INPUT_MON (clocking input_mon_cb);
//Output monitor
modport OUTPUT_MON (clocking output_mon_cb );

endinterface