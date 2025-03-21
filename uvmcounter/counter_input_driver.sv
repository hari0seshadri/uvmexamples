//Input Driver
//===============
class counter_input_driver extends uvm_driver # (counter_trans);

`uvm_component_utils (counter_input_driver)
virtual counter_inf.DRIVER drv_inf;
counter_trans data2duv_pkt ;

  uvm_analysis_port# (counter_trans) driver_port;
  
counter_env_config m_cfg;
function new (string name="counter_input_driver", uvm_component parent);

super.new (name,parent);
endfunction


function void build_phase (uvm_phase phase);
super.build_phase (phase);
  if (!uvm_config_db # (counter_env_config)::get (this, "", "counter_env_config",m_cfg))
`uvm_fatal ("CONFIG", "cannot get () m_cfg from uvm_config_db. Have you set () it?")
if (! m_cfg.has_input_monitor)    
    driver_port = new("driver_port", this);
endfunction


function void connect_phase (uvm_phase phase );
drv_inf=m_cfg.vif;
endfunction


task run_phase (uvm_phase phase);
forever
begin
  seq_item_port.get_next_item(req); //hari - removed =
send_to_dut(req);
  if (! m_cfg.has_input_monitor)
          driver_port.write(req);
seq_item_port.item_done();
end
endtask


  virtual task send_to_dut (counter_trans data2duv_pkt);

@(drv_inf.driver_cb);
drv_inf.driver_cb.data_in<=data2duv_pkt.data_in;
drv_inf.driver_cb.rst<=data2duv_pkt.rst;
drv_inf.driver_cb.load<=data2duv_pkt.load;
endtask
endclass