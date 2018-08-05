`ifndef RR_SEQ_LIB_SV
`define RR_SEQ_LIB_SV
import util_pkg::*;

covergroup cg_sim_params(ref Parameters param);
  option.per_instance = 1;

  flush_rate_cov:  coverpoint param.FLUSH_RATE_R {
    bins low_flush_rate       = {[0:2]};
    bins medium_flush_rate    = {[3:7]};
    bins high_flush_rate      = {[8:10]};
    illegal_bins others      = default;
  }

  wb_rate_cov:  coverpoint param.WRITEBACK_RATE_R {
    bins low_wb_rate       = {[0:25]};
    bins medium_wb_rate    = {[26:75]};
    bins high_wb_rate      = {[76:100]};
    illegal_bins others      = default;
  }

  min_wb_rate_cov:  coverpoint param.MIN_WB_PER_CYCLE_R {
    bins low_min_wb_rate       = {[0:INSTR_COUNT/4]};
    bins medium_min_wb_rate    = {[INSTR_COUNT/4+1:INSTR_COUNT-2]};
    bins high_min_wb_rate      = {[INSTR_COUNT-1:INSTR_COUNT]};
    illegal_bins others      = default;
  }

  max_wb_rate_cov:  coverpoint param.MAX_WB_PER_CYCLE_R {
    bins low_max_wb_rate       = {[1:INSTR_COUNT/4]};
    bins medium_max_wb_rate    = {[INSTR_COUNT/4+1:INSTR_COUNT-2]};
    bins high_max_wb_rate      = {[INSTR_COUNT-1:INSTR_COUNT]};
    illegal_bins others      = default;
  }

  simulation_parameters_coverage: cross flush_rate_cov, wb_rate_cov, min_wb_rate_cov, max_wb_rate_cov;
endgroup : cg_sim_params


class RR_default_seq extends uvm_sequence #(trans);
  `uvm_object_utils(RR_default_seq)

  RR_agent m_RR_agent;
  Parameters param;
  cg_sim_params cg_sim_params;

  function new(string name = "");
    super.new(name);
    param = new();
    cg_sim_params = new(param);
  endfunction : new


  function void sample_sim_params();
    
  endfunction : sample_sim_params

  function update_driver_parameters();
    if (!param.randomize()) `uvm_fatal(get_type_name(),"Failed to randomize simulation parameters");
    $display("param=%p",param);
    m_RR_agent.m_driver_wb_fl.FLUSH_RATE_ = param.FLUSH_RATE_R;
    m_RR_agent.m_driver_wb_fl.WRITEBACK_RATE_ = param.WRITEBACK_RATE_R;
    m_RR_agent.m_driver_wb_fl.MIN_WB_PER_CYCLE_ = param.MIN_WB_PER_CYCLE_R;
    m_RR_agent.m_driver_wb_fl.MAX_WB_PER_CYCLE_ = param.MAX_WB_PER_CYCLE_R;
    cg_sim_params.sample();
  endfunction : update_driver_parameters
  

  task body();
    repeat(SIM_RUNS) begin
      if(RANDOM_PARAMETERS_ACTIVE) update_driver_parameters(); 
      repeat (TRANS_NUM) begin 
        req = trans::type_id::create("req");
        start_item(req);
        if (!req.randomize()) `uvm_fatal(get_type_name(),"Failed to randomize transaction");
        finish_item(req);
      end
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

