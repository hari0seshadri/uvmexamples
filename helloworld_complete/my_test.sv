class my_test extends uvm_test;
  
    `uvm_component_utils(my_test)
    
     my_dut_config dut_config_0;
    
     my_env my_env_h;   
   
     function new(string name, uvm_component parent);
	super.new(name, parent);
     endfunction: new
    
     function void build_phase(uvm_phase phase);
	dut_config_0 = new();

	if(!uvm_config_db #(virtual dut_if)::get( this, "", "dut_vi", 
						  dut_config_0.dut_vi))
          `uvm_fatal("NOVIF", "No virtual interface set")
	// other DUT configuration settings
	uvm_config_db #(my_dut_config)::set(this, "*", "dut_config", 
					    dut_config_0);
	my_env_h = my_env::type_id::create("my_env_h", this);
     endfunction: build_phase
     
  endclass // my_test

  class test1 extends my_test;
   `uvm_component_utils(test1)

     function new(string name, uvm_component parent);
	super.new(name, parent);
     endfunction: new
    
     task run_phase(uvm_phase phase);
	read_modify_write seq;
	seq = read_modify_write::type_id::create("seq");
	phase.raise_objection(this);
	seq.start(my_env_h.my_agent_h.my_sequencer_h);
	phase.drop_objection(this);
     endtask // run_phase
  endclass: test1
   
  class test2 extends my_test;
     `uvm_component_utils(test2)
	
     function new(string name, uvm_component parent);
	super.new(name, parent);
     endfunction: new
    
     task run_phase(uvm_phase phase);
	seq_of_commands seq;
	seq = seq_of_commands::type_id::create("seq");
	assert( seq.randomize() );
	phase.raise_objection(this);
	seq.start( my_env_h.my_agent_h.my_sequencer_h );
	phase.drop_objection(this);
     endtask: run_phase
     
  endclass: test2
   
  class test3 extends my_test;
     `uvm_component_utils(test3)
	
     function new(string name, uvm_component parent);
	super.new(name, parent);
     endfunction: new
    
     task run_phase(uvm_phase phase);
	seq_of_commands seq;
	seq = seq_of_commands::type_id::create("seq");
	seq.how_many.constraint_mode(0);
	assert( seq.randomize() with {seq.n > 10 && seq.n < 20;});
	phase.raise_objection(this);
	seq.start( my_env_h.my_agent_h.my_sequencer_h );
	phase.drop_objection(this);
     endtask: run_phase
     
  endclass: test3
  