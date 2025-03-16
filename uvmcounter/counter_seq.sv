//Sequence
class counter_seq extends uvm_sequence # (counter_trans );

`uvm_object_utils(counter_seq)
int xtn_num =1;
function new (string name = "counter_seq");
super.new (name);
endfunction


task body ();
repeat (number_of_transactions) begin
req=counter_trans::type_id::create("req");
start_item (req);
if (xtn_num ==1)
begin
assert(req.randomize () with {rst==1;});
xtn_num++;
end
else
assert (req.randomize ());
finish_item(req);
end
endtask

endclass