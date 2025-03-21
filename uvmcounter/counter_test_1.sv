//Derived testcase
class counter_test_1 extends counter_base_test;

`uvm_component_utils (counter_test_1)
counter_seq counter_seq_h ;
function new (string name = "counter_test_1", uvm_component parent = null);

super.new (name, parent);
endfunction


function void build_phase (uvm_phase phase);
super.build_phase (phase);
  m_cfg.has_input_monitor=0;
  m_cfg.has_output_agent =0;
endfunction


task run_phase (uvm_phase phase );
phase.raise_objection (this);
  
  //reset seq
  //assert(req.randomize () with {rst==1;});
  //repeat (number_of_transactions) begin
counter_seq_h=counter_seq::type_id::create ("counter_seq_h");

counter_seq_h.start(counter_env_h.input_agent_h.seqrh);
#30;
  //end
phase.drop_objection(this);
endtask
endclass