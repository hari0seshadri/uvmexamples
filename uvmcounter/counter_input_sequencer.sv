//Input Sequencer
class counter_input_sequencer extends uvm_sequencer # (counter_trans);

`uvm_component_utils (counter_input_sequencer)
function new (string name="counter_input_sequencer", uvm_component parent);

super.new (name,parent );
endfunction
endclass