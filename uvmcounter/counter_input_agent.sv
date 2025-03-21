//Input Agent
class counter_input_agent extends uvm_agent;

`uvm_component_utils (counter_input_agent)
counter_env_config m_cfg ;
counter_input_monitor monh;
counter_input_sequencer seqrh;
counter_input_driver drvh;
 counter_output_monitor outmonh; 
  
function new (string name = "counter_input_agent", uvm_component parent = null);
super.new (name, parent);
endfunction


function void build_phase (uvm_phase phase);
super.build_phase (phase);
if (!uvm_config_db # (counter_env_config) ::get
(this,"","counter_env_config",m_cfg))
`uvm_fatal ("CONFIG","CANNOT GET () m_cfg from uvm_config_db. Have YOU set () it")
  if (m_cfg.has_input_monitor)
monh=counter_input_monitor::type_id::create("monh", this);
  if (m_cfg.input_agent_is_active==UVM_ACTIVE)
begin
drvh=counter_input_driver::type_id::create(" drvh", this);

seqrh=counter_input_sequencer::type_id::create("seqrh", this);
end
  
  if(! m_cfg.has_output_agent && !m_cfg.has_input_monitor)
    outmonh=counter_output_monitor::type_id::create("outmonh", this);

endfunction


function void connect_phase (uvm_phase phase);
if (m_cfg.input_agent_is_active==UVM_ACTIVE)
begin
drvh.seq_item_port.connect(seqrh.seq_item_export);
end
endfunction
endclass : counter_input_agent