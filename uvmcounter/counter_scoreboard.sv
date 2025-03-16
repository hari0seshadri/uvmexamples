class counter_scoreboard extends uvm_scoreboard;

`uvm_component_utils (counter_scoreboard)
uvm_tlm_analysis_fifo #(counter_trans) input_mon_fifo;

uvm_tlm_analysis_fifo #(counter_trans) output_mon_fifo ;
counter_trans input_mon_pkt;

counter_trans output_mon_pkt;

counter_trans expected_output_pkt;

counter_trans cov_data_pkt;
int data_verified =0;
int input_mon_pkt_count =0;

int output_mon_pkt_count =0;
covergroup counter_coverage;

option.per_instance= 1;
LOAD_DATA: coverpoint cov_data_pkt.data_in {
bins ZERO = {0};
bins LOW1 = {[1:2]};
bins LOW2 = {[3:4]};
bins MID_LOW = {[5:6]};
bins MID={[7:8]};
bins MID_HIGH ={[9:10]};
bins HIGH1 ={[11:12]};
bins HIGH2 ={[13:14]};
bins MAX ={15};
}
  
  RESET_CMD : coverpoint cov_data_pkt.rst{ bins cmd_rst ={1};
}
LOAD_CMD : coverpoint cov_data_pkt.load{ bins load_dut = {1};
}
READxWRITE: cross LOAD_CMD, LOAD_DATA;
endgroup

function new (string name, uvm_component parent);

  super.new (name,parent);
input_mon_fifo=new("input_mon_fifo", this);
output_mon_fifo= new(" output_mon_fifo", this);
expected_output_pkt=counter_trans::type_id::create (" expected_output_pkt");
;
counter_coverage=new;
endfunction


  task run_phase (uvm_phase phase);
forever
begin
input_mon_fifo.get(input_mon_pkt);
input_mon_pkt_count++;
  `uvm_info (get_type_name,$sformatf ("sb has got below packet from input monitor \n%s", input_mon_pkt.sprint()), UVM_MEDIUM)
  
  output_mon_fifo.get(output_mon_pkt );
output_mon_pkt_count++;
`uvm_info (get_type_name, $sformatf ("sb has got below packet from output monitor \n%s", output_mon_pkt.sprint()), UVM_MEDIUM)
ref_model_logic();
validate_output();
end
endtask


task ref_model_logic();
begin
  if (input_mon_pkt.rst || (input_mon_pkt.load&input_mon_pkt.data_in >=13))

   expected_output_pkt.data_out = 4'b0;
  else if(input_mon_pkt.load)
expected_output_pkt.data_out = input_mon_pkt.data_in ;
else if (expected_output_pkt.data_out >=13)
expected_output_pkt.data_out = 4'b0;
else
expected_output_pkt.data_out=expected_output_pkt.data_out + 1'b1;
end
endtask
  
  virtual task validate_output ();
if (!expected_output_pkt.compare(output_mon_pkt))
begin: failed_compare
`uvm_info(get_type_name, $sformatf (" expected packet is below \n%s ",expected_output_pkt.sprint()), UVM_MEDIUM)
//`uvm_info(get_type_name, $sformatf (" dut output packet is below \n%s ",expected_mon_pkt.sprint()), UVM_MEDIUM)
  //hari to check
  `uvm_info(get_type_name, $sformatf (" dut output packet is below \n%s ",output_mon_pkt.sprint()), UVM_MEDIUM)
//$finish;
end: failed_compare
else
begin
`uvm_info (get_type_name (), $sformatf ("Data Match successful "), UVM_MEDIUM)
data_verified++;
end
cov_data_pkt=input_mon_pkt;
counter_coverage.sample();
endtask


function void report_phase (uvm_phase phase);
$display ("\n----Scoreboard----\n");
$display (" input mon pkt count = 0d, output mon pkt count = %0d, no of successful comparisions = %d\n", input_mon_pkt_count, output_mon_pkt_count ,data_verified);
$display ("-----------------------\n");
  $display("load_data coverage: %f",counter_coverage.LOAD_DATA.get_coverage());
  $display("load_cmd coverage: %f",counter_coverage.LOAD_CMD.get_coverage());
endfunction
endclass