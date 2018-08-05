import util_pkg::*;
class Parameters;

	rand int FLUSH_RATE_R, WRITEBACK_RATE_R, MIN_WB_PER_CYCLE_R, MAX_WB_PER_CYCLE_R;


  constraint min_max_wb_c {
    MAX_WB_PER_CYCLE_R inside {[1:INSTR_COUNT]};
    MIN_WB_PER_CYCLE_R inside {[0:MAX_WB_PER_CYCLE_R]};
  }

  constraint c2 {
    FLUSH_RATE_R inside {[0:10]};
    WRITEBACK_RATE_R inside {[1:100]};
  }

  function new();
  
  endfunction : new


endclass : Parameters