//Environment
class counter_env extends uvm_env ;
`uvm_component_utils (counter_env)

counter_input_agent input_agent_h;

counter_output_agent output_agent_h;

counter_scoreboard scoreboard_h ;
counter_env_config m_cfg ;
  function new (string name = "counter_input_agent", uvm_component parent = null);
super.new (name, parent);
endfunction


function void build_phase (uvm_phase phase);
  if(!uvm_config_db # (counter_env_config)::get (this,"*","counter_env_config",m_cfg))
`uvm_fatal (get_type_name, "cannot get from contig db. Have you set () it?")

if (m_cfg.has_input_agent)
input_agent_h = counter_input_agent::type_id::create("input_agent_h", this);

if (m_cfg.has_output_agent)
output_agent_h = counter_output_agent::type_id ::create ("output_agent_h",this);
  if (m_cfg.has_scoreboard)
scoreboard_h = counter_scoreboard::type_id::create (" scoreboard_h", this);

super.build_phase (phase);
endfunction

function void connect_phase (uvm_phase phase);

uvm_top.print_topology();
if(m_cfg.has_input_agent && m_cfg.has_scoreboard)
input_agent_h.monh.monitor_port.connect (scoreboard_h.input_mon_fifo.analysis_export);
if (m_cfg.has_output_agent && m_cfg.has_scoreboard)
output_agent_h.monh.monitor_port.connect (scoreboard_h.output_mon_fifo.analysis_export);
endfunction
endclass