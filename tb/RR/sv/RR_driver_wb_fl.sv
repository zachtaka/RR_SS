`ifndef RR_driver_wb_fl_SV
`define RR_driver_wb_fl_SV

import util_pkg::*;
class RR_driver_wb_fl extends uvm_component;
  `uvm_component_utils(RR_driver_wb_fl)

  virtual RR_if vif;
  // rob_rht_id_s rob_rht_id_q[$], q_entry;
  int wb_count;

  rob_rht_id_entry_s [(TRANS_NUM*INSTR_COUNT)-1:0] Ins_array;
  int Ins_commit_pointer, Ins_retire_pointer, uncommited_Ins;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    Ins_commit_pointer = 0;
    Ins_retire_pointer = 0;
  endfunction : new

  task reset();
    vif.wb_en <= 0;
  endtask : reset
  bit bp_flush = 0;
  int last_rec_rob_id;
  int rob_id_count = 0;
  task run_phase(uvm_phase phase);

    reset();
    wait(vif.rst_n);
    forever begin 
      // Track rob and rht id for each Ins rename
      if(vif.l_dst_valid && (!vif.stall && !vif.rec_busy && !vif.rec_en)) begin
        for (int i=0; i<INSTR_COUNT; i++) begin
          Ins_array[Ins_commit_pointer].rob_id = vif.alloc_rob_id[i];
          Ins_array[Ins_commit_pointer].rht_id = vif.alloc_rht_id[i];
          Ins_array[Ins_commit_pointer].flushed = 0;
          Ins_array[Ins_commit_pointer].valid_entry = 1;
          // $display("NEW entry to Ins_array[%0d]: %p",Ins_commit_pointer,Ins_array[Ins_commit_pointer]);
          Ins_commit_pointer++;
        end
      end

      uncommited_Ins = Ins_commit_pointer - Ins_retire_pointer;
      if((!vif.rec_busy && !vif.rec_en) && (uncommited_Ins>0)) begin
        if(($urandom_range(0,99)<FLUSH_RATE)) begin
          // Flush to Ins_retire_pointer
          // dont recover to the same rob id two consecutive times
          if(last_rec_rob_id!=Ins_array[Ins_retire_pointer].rob_id) begin
            vif.rec_rob_id[0] <= Ins_array[Ins_retire_pointer].rob_id;
            vif.rec_rht_id <= Ins_array[Ins_retire_pointer].rht_id;
            vif.rec_en <= 1;
            vif.wb_en  <= 0;
            last_rec_rob_id = Ins_array[Ins_retire_pointer].rob_id;
            for (int i = (Ins_retire_pointer+1); i < Ins_commit_pointer; i++) begin
              Ins_array[i].flushed = 1;
            end
          end
        end else if($urandom_range(0,99)<WRITEBACK_RATE) begin
          // Send writebacks according to writeback rate
          // skip all flushed instructions
          while (Ins_array[Ins_retire_pointer].flushed) begin 
            Ins_retire_pointer++;
          end

          // ceil writeback count to the max available Ins for writeback
          wb_count = $urandom_range(MIN_WB_PER_CYCLE,MAX_WB_PER_CYCLE);
          if(wb_count > uncommited_Ins) begin
            wb_count = uncommited_Ins;
          end

          for (int i=0; i<INSTR_COUNT; i++) begin
            vif.wb_en[i] <= (i<wb_count);
            if (i<wb_count) begin
              vif.rec_rob_id[i] <= Ins_array[Ins_retire_pointer].rob_id;
              // $display("after flush: Ins_retire_pointer=%0d and rob_id=%0d",Ins_retire_pointer,Ins_array[Ins_retire_pointer].rob_id);
              // if (bp_flush) $stop;
              Ins_retire_pointer++;
            end 
          end
          vif.rec_en <= 0;
        end else begin 
          vif.wb_en  <= 0;
          vif.rec_en <= 0;
        end
      end else begin 
        vif.wb_en  <= 0;
        vif.rec_en <= 0;
      end
      @(posedge vif.clk);
    end
  endtask : run_phase



endclass : RR_driver_wb_fl

`endif