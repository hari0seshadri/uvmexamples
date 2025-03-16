//Output Agent
class counter_output_agent extends uvm_agent;

`uvm_component_utils (counter_output_agent)
counter_env_config m_cfg ;

counter_output_monitor monh ;
function new (string name = "counter_output_agent", uvm_component parent =null);
super.new (name, parent);
endfunction


function void build_phase (uvm_phase phase);

super.build_phase (phase);
if (!uvm_config_db #(counter_env_config)::get(this,"","counter_env_config",m_cfg))
  `uvm_fatal ("CONIG","cannot get () m_cfg from uvm_config_db. Have you set ()?")


if(m_cfg.output_agent_is_active==UVM_PASSIVE)
monh=counter_output_monitor::type_id::create("monh", this);
endfunction
endclass: counter_output_agent