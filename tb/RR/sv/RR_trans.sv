`ifndef RR_SEQ_ITEM_SV
`define RR_SEQ_ITEM_SV

import util_pkg::*;
class trans extends uvm_sequence_item; 
  `uvm_object_utils(trans)


  rand bit [INSTR_COUNT-1:0][$clog2(L_REGISTERS)-1:0] dest;
  function new(string name = "");
    super.new(name);
  endfunction : new


  constraint dest_zero {
    foreach(dest[i]) dest[i] inside {[1:L_REGISTERS]};
  }

  function void post_randomize();
    
    for (int i=0; i<(INSTR_COUNT-1); i++) begin
      if($urandom_range(0,99)<DEPENDENCE_RATE) begin
        dest[i] = dest[INSTR_COUNT-1];
      end
    end
  
  endfunction : post_randomize




endclass : trans 

`endif

