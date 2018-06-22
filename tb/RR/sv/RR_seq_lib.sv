`ifndef RR_SEQ_LIB_SV
`define RR_SEQ_LIB_SV

class RR_default_seq extends uvm_sequence #(trans);
  `uvm_object_utils(RR_default_seq)

  function new(string name = "");
    super.new(name);
  endfunction : new
  

  task body();
    repeat (TRANS_NUM) begin 
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize()) `uvm_fatal(get_type_name(),"Failed to randomize transaction");
      finish_item(req);
    end
  endtask : body


`ifndef UVM_POST_VERSION_1_1
  // Functions to support UVM 1.2 objection API in UVM 1.1
  function uvm_phase get_starting_phase();
    return starting_phase;
  endfunction: get_starting_phase
  function void set_starting_phase(uvm_phase phase);
    starting_phase = phase;
  endfunction: set_starting_phase
`endif

endclass : RR_default_seq


`endif 

