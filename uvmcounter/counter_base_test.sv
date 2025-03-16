//Base testcase
//import counter_pkg::*;
class counter_base_test extends uvm_test;

`uvm_component_utils (counter_base_test)

counter_env_config m_cfg;
counter_env counter_env_h;
 function new (string name = "counter base test", uvm_component parent=null);

super.new (name, parent);
endfunction

function void build_phase (uvm_phase phase);
m_cfg = counter_env_config::type_id::create ("m_cfg");
if (!uvm_config_db # (virtual counter_inf )::get(this,"","vif",m_cfg.vif))
`uvm_fatal (get_type_name," cannot get () interface vif from uvm_config_db");
m_cfg.has_input_agent =1;
m_cfg.has_output_agent =1;

m_cfg.has_scoreboard=1;
m_cfg.output_agent_is_active = UVM_PASSIVE ;
m_cfg.input_agent_is_active = UVM_ACTIVE;
uvm_config_db #(counter_env_config)::set (this, "*","counter_env_config",m_cfg);
counter_env_h = counter_env::type_id::create ("counter_env_h", this);

endfunction
endclass