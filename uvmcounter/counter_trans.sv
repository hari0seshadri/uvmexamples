//Transaction Class (Sequence Ieam)
//===============
class counter_trans extends uvm_sequence_item;

`uvm_object_utils (counter_trans)
rand logic rst;
rand logic load;
randc logic [3:0] data_in;
  logic [3:0] data_out;
static int no_of_xtn ;
  constraint VALID_RST {rst dist{ 1:=1,0:=15}; }

constraint VALID_LOAD {load dist{ 1:=1, 0:=15}; }

constraint VALID_DATA {data_in inside {[0:15]};}
function new (string name = " counter_trans");
super.new (name);
endfunction: new


  function bit do_compare (uvm_object rhs,uvm_comparer comparer );

counter_trans rhs_ ;
if (!$cast (rhs_, rhs))
begin
`uvm_fatal (" do_compare","cast of the rhs object failed")

return 0;
end
    return super.do_compare (rhs, comparer) && data_out == rhs_.data_out;
endfunction: do_compare


function void do_print (uvm_printer printer);
super.do_print (printer);
printer.print_field ("rst", this.rst, '1, UVM_DEC);
printer.print_field ("load", this.load, '1, UVM_DEC);
printer.print_field (" data_in", this.data_in, 4, UVM_DEC);
printer.print_field ("data_out", this.data_out, 4, UVM_DEC); 
endfunction: do_print
 
  function void post_randomize();
no_of_xtn++;
    `uvm_info("randomized data", $sformatf("randomized transaction [%d] is %s\n", no_of_xtn, this.sprint()),UVM_MEDIUM)
endfunction: post_randomize
endclass
