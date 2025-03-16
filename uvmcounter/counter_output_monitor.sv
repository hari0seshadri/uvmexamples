//Output Monitor
class counter_output_monitor extends uvm_monitor;

`uvm_component_utils (counter_output_monitor)
virtual counter_inf.OUTPUT_MON rdmon_inf;

counter_trans output_mon_pkt ;
counter_env_config m_cfg;
uvm_analysis_port# (counter_trans) monitor_port;
  function new (string name="counter_input_monitor", uvm_component parent );

super.new (name,parent);

endfunction

function void build_phase (uvm_phase phase);
super.build_phase (phase);
  if (!uvm_config_db #(counter_env_config)::get(this,"*", "counter_env_config",m_cfg))
`uvm_fatal(get_type_name,"cannot get () m_cfg ") 
  monitor_port=new("monitor_port", this);
endfunction


function void connect_phase (uvm_phase phase);

rdmon_inf = m_cfg.vif;
endfunction
  
  task run_phase (uvm_phase phase);
repeat (2)
@ (rdmon_inf.output_mon_cb);
forever
monitor();
endtask


task monitor ();
  output_mon_pkt = counter_trans::type_id::create("output_mon_pkt");
@(rdmon_inf.output_mon_cb);
output_mon_pkt.data_out = rdmon_inf.output_mon_cb.data_out ;
`uvm_info(get_type_name, $sformatf("output monitor has captured below transaction \n%s", output_mon_pkt.sprint()), UVM_MEDIUM)

monitor_port.write(output_mon_pkt);
endtask

endclass