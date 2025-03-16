//Input Monitor
class counter_input_monitor extends uvm_monitor ;

`uvm_component_utils (counter_input_monitor)
virtual counter_inf.INPUT_MON mon_if;
counter_trans drv2mon_pkt;

counter_env_config m_cfg ;
uvm_analysis_port# (counter_trans) monitor_port;


function new (string name="counter_input_monitor", uvm_component parent);
super.new (name, parent);
endfunction


function void build_phase (uvm_phase phase);

super.build_phase (phase);
  if (!uvm_config_db # (counter_env_config)::get(this,"","counter_env_config",m_cfg ))
`uvm_fatal (get_type_name, "cannot get () m_cfg")

monitor_port = new("monitor_port", this);

endfunction

function void connect_phase (uvm_phase phase);

mon_if=m_cfg.vif;
endfunction


task run_phase (uvm_phase phase);
@ (mon_if.input_mon_cb);
forever
monitor();
endtask


task monitor();
begin
  @ (mon_if.input_mon_cb);
drv2mon_pkt = counter_trans::type_id::create("drv2mon_pkt");

drv2mon_pkt.load=mon_if.input_mon_cb.load;
drv2mon_pkt.rst = mon_if.input_mon_cb.rst;
drv2mon_pkt.data_in=mon_if.input_mon_cb.data_in;
`uvm_info(get_type_name, $sformatf("input monitor has captured below transaction \n%s", drv2mon_pkt.sprint ()), UVM_MEDIUM)

monitor_port.write (drv2mon_pkt);
end
endtask

endclass