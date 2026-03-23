// Transaction (sequence item) representing a single bus operation.
class my_transaction extends uvm_sequence_item;
  `uvm_object_utils(my_transaction)

  rand bit cmd;      // Command field (0/1)
  rand int addr;     // Address (constrained to 0-255)
  rand int data;     // Data (constrained to 0-255)

  constraint c_addr { addr >= 0; addr < 256; }
  constraint c_data { data >= 0; data < 256; }

  function new (string name = "");
    super.new(name);
  endfunction: new

  // Convert transaction to string for display
  function string convert2string;
    return $psprintf("cmd=%b, addr=%0d, data=%0d", cmd, addr, data);
  endfunction: convert2string

  // Optional copy and compare methods are commented out; they could be uncommented if needed.
  /*
  function void do_copy(uvm_object rhs);
    my_transaction rhs_;
    super.do_copy(rhs);
    $cast(rhs_, rhs);
    cmd  = rhs_.cmd;
    addr = rhs_.addr;
    data = rhs_.data;
  endfunction: do_copy

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    my_transaction rhs_;
    bit status = 1;
    status &= super.do_compare(rhs, comparer);
    $cast(rhs_, rhs);
    status &= comparer.compare_field("cmd",  cmd,  rhs_.cmd,  $bits(cmd));
    status &= comparer.compare_field("addr", addr, rhs_.addr, $bits(addr));
    status &= comparer.compare_field("data", data, rhs_.data, $bits(data));
    return(status);
  endfunction: do_compare
  */
endclass: my_transaction


// Sequence that performs a read-modify-write operation:
// first writes a random address with cmd=1 and random data,
// then writes the same address with data incremented by 1.
class read_modify_write extends uvm_sequence #(my_transaction);
  `uvm_object_utils(read_modify_write)

  function new (string name = "");
    super.new(name);
  endfunction: new

  task body;
    my_transaction tx;
    int a;
    int d;

    // First transaction: write with cmd=1, random address and data
    tx = my_transaction::type_id::create("tx");
    start_item(tx);
    assert( tx.randomize() );
    tx.cmd = 0;   // Read operation
    finish_item(tx);
    // Record the address and data
    a = tx.addr;      
    d = tx.data;
    ++d;            // Increment data

    // Second transaction: write the same address with incremented data
    tx = my_transaction::type_id::create("tx");
    start_item(tx);
    tx.cmd = 1;
    tx.addr = a;
    tx.data = d;
    finish_item(tx);
  endtask: body
endclass: read_modify_write


// Sequence that generates a random number (n) of read_modify_write sequences.
class seq_of_commands extends uvm_sequence #(my_transaction);
  `uvm_object_utils(seq_of_commands)
  `uvm_declare_p_sequencer(uvm_sequencer#(my_transaction))   // Declare p_sequencer type

  rand int n;               // Number of sub-sequences to execute
  constraint how_many { n inside {[2:4]}; }   // Default: 2 to 4

  function new (string name = "");
    super.new(name);
  endfunction: new

  task body;
    repeat(n) begin
      read_modify_write seq;
      seq = read_modify_write::type_id::create("seq");
      assert( seq.randomize() );
      seq.start(p_sequencer);   // Start the sub-sequence on the parent sequencer
    end
  endtask: body
endclass: seq_of_commands
