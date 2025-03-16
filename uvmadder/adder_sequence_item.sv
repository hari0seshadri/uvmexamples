//Object class


class adder_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(adder_sequence_item)

  //--------------------------------------------------------
  //Instantiation
  //--------------------------------------------------------
  rand logic reset;
  rand logic [7:0] input_1, input_2;
  
  logic [15:0] output_3; //output

  
  //--------------------------------------------------------
  //Constructor
  //--------------------------------------------------------
  function new(string name = "adder_sequence_item");
    super.new(name);

  endfunction: new

endclass: adder_sequence_item
