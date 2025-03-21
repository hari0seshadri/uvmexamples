//Configuration Class
class counter_env_config extends uvm_object;

`uvm_object_utils (counter_env_config)
bit has_input_agent;

bit has_output_agent ;
bit has_scoreboard ;
bit has_input_monitor;
uvm_active_passive_enum input_agent_is_active;
uvm_active_passive_enum output_agent_is_active;
virtual counter_inf vif;
function new (string name = "counter_env_config");
super.new (name);
endfunction
endclass