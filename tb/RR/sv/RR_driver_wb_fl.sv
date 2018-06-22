`ifndef RR_driver_wb_fl_SV
`define RR_driver_wb_fl_SV

import util_pkg::*;
class RR_driver_wb_fl extends uvm_component;
  `uvm_component_utils(RR_driver_wb_fl)

  virtual RR_if vif;
  int rob_id_q[$];
  int wb_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  task reset();
    vif.wb_en <= 0;
  endtask : reset


  task run_phase(uvm_phase phase);

    reset();
    wait(vif.rst_n);
    forever begin 
      // Track renames and record their ROB id's
      if(vif.l_dst_valid && (!vif.stall && !vif.rec_busy)) begin
        for (int i=0; i<INSTR_COUNT; i++) begin
          rob_id_q.push_back(vif.alloc_rob_id[i]);
        end
      end

      // Send writebacks according to writeback rate
      if(($urandom_range(0,99)<WRITEBACK_RATE)&&(rob_id_q.size()>0)) begin
        wb_count = $urandom_range(MIN_WB_PER_CYCLE,MAX_WB_PER_CYCLE);
        if(wb_count > rob_id_q.size()) begin
          // ceil writeback count to the max available Ins for writeback
          wb_count = rob_id_q.size();
        end
        for (int i=0; i<INSTR_COUNT; i++) begin
          vif.wb_en[i] = (i<wb_count);
          if (vif.wb_en[i]) begin
            vif.rec_rob_id[i] = rob_id_q.pop_front();
          end 
        end
      end else begin 
        vif.wb_en = 0;
      end


      vif.rec_rht_id <= 0;
      vif.rec_en <= 0;
      @(posedge vif.clk);
    end
  endtask : run_phase



endclass : RR_driver_wb_fl

`endif