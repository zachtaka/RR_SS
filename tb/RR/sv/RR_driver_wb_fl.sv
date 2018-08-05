`ifndef RR_driver_wb_fl_SV
`define RR_driver_wb_fl_SV

import util_pkg::*;
class RR_driver_wb_fl extends uvm_component;
  `uvm_component_utils(RR_driver_wb_fl)

  virtual RR_if vif;
  // Parameters
  int FLUSH_RATE_ = FLUSH_RATE;
  int WRITEBACK_RATE_ = WRITEBACK_RATE;
  int MIN_WB_PER_CYCLE_ = MIN_WB_PER_CYCLE;
  int MAX_WB_PER_CYCLE_ = MAX_WB_PER_CYCLE; 
  //
  int credits, rob_counter, rht_counter, wb_count;
  bit disable_recover;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    credits = 0;
    rob_counter = 0;
    rht_counter = 0;
  endfunction : new

  task reset();
    vif.wb_en  <= 0;
    vif.rec_en <= 0;
  endtask : reset



  task run_phase(uvm_phase phase);

    reset();
    wait(vif.rst_n);
    forever begin 

      if((credits>0)&&(!vif.rec_busy && !vif.rec_en)) begin
        
        if(($urandom_range(0,99)<FLUSH_RATE_)&&(!disable_recover)) begin
          vif.rec_rob_id[0] <= rob_counter;
          vif.rec_rht_id <= rht_counter;
          vif.rec_en <= 1;
          vif.wb_en  <= 0;
          disable_recover = 1;
        end else if($urandom_range(0,99)<WRITEBACK_RATE_) begin
          // ceil writeback count to the max available credits for writeback
          wb_count = $urandom_range(MIN_WB_PER_CYCLE_,MAX_WB_PER_CYCLE_);
          if(wb_count > credits) wb_count = credits;

          for (int i=0; i<INSTR_COUNT; i++) begin
            if (i<wb_count) begin
              vif.wb_en[i] = 1;
              vif.rec_rob_id[i] <= rob_counter;
              rob_counter++;
              rht_counter++; 
              if(rob_counter==((C_NUM-1)*K)) rob_counter = 0;
              if(rht_counter==(C_NUM*K))     rht_counter = 0;
              disable_recover = 0;
            end else begin 
              vif.wb_en[i] = 0;
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

      if(vif.rec_en) begin
        // Give one credit after recover to writeback rec rob id
        credits = 1;
      end else if(vif.l_dst_valid && !vif.stall) begin
        credits = credits + INSTR_COUNT;
      end

      @(posedge vif.clk);
    end
  endtask : run_phase



endclass : RR_driver_wb_fl

`endif