`ifndef Checker_sv
`define Checker_sv
`uvm_analysis_imp_decl(_wb) 
`uvm_analysis_imp_decl(_commit) 

import util_pkg::*;
class Checker extends uvm_subscriber #(trans);
  `uvm_component_utils(Checker)

  uvm_analysis_imp_wb #(writeback_s, Checker) wb; 
  uvm_analysis_imp_commit #(commit_s, Checker) commit; 

  virtual RR_if    vif;

  checker_utils utils;

  trans m_trans, trans_q[$];

/*-----------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------*/
  

  function void write(input trans t);
    trans_q.push_back(t);
  endfunction : write

  // Push freed reg from writeback
  int wb_id_q[$];
  function void write_wb(input writeback_s t);
    for (int i = 0; i < INSTR_COUNT; i++) begin
      if(t.wb_en[i]) begin
        wb_id_q.push_back(t.rob_id[i]);
      end
    end
  endfunction : write_wb

  // Push freed reg from commit
  int retire_rob_id;
  function void write_commit(input commit_s t);
    for (int i = 0; i < INSTR_COUNT; i++) begin
      if(t.valid_commit[i]) begin
        assert(wb_id_q.size()>0) else $fatal("No available rob id to commit");
        retire_rob_id = wb_id_q.pop_front();
        utils.release_reg_2(retire_rob_id);
      end
    end
    // utils.release_reg_2(t);
  endfunction : write_commit

/*-----------------------------------------------------------------------------
-- Tasks
-----------------------------------------------------------------------------*/
  ///
  int trans_pointer;
  bit [INSTR_COUNT-1:0][$clog2(P_REGISTERS)-1:0] dest_o_GR;
  result_array_entry_s [(TRANS_NUM*INSTR_COUNT)-1:0] GR_array;
  rename_record_entry_s rename_entry;
  flush_array_entry_s [(TRANS_NUM*INSTR_COUNT)-1:0] flush_array;
  task RR_Golden_Ref();
    forever begin 
      if(trans_q.size()>0) begin
        m_trans = trans_q.pop_front();
        
        /*--------------------------------------------------------------------- 
              Instruction rename golden ref
        ----------------------------------------------------------------------*/
        wait(flush_array[trans_pointer].valid_entry);
        if(flush_array[trans_pointer].renamed) begin
          // Instruction dest rename calculation
          for (int ins_i = 0; ins_i < INSTR_COUNT; ins_i++) begin
            while(utils.free_reg_counter()==0) begin 
              @(negedge vif.clk);
            end
            dest_o_GR[ins_i] = utils.get_free_reg();
          end
          
          for (int i = 0; i < INSTR_COUNT; i++) begin
            // Save results to Golden Reference array
            GR_array[trans_pointer].dest[i] = dest_o_GR[i];
            GR_array[trans_pointer].rob_id[i]  = utils.alloc_rob_id; // ToDo Fix it
            GR_array[trans_pointer].rht_id[i]  = utils.alloc_rht_id; // ToDo Fix it
            GR_array[trans_pointer].valid_entry = 1;

            // Update checker components
            // Keep track of renames and rob, rht id
            rename_entry.lreg = m_trans.dest[i];
            rename_entry.preg = dest_o_GR[i];
            rename_entry.ppreg = utils.get_id_from_RAT(m_trans.dest[i]);
            utils.new_rename(rename_entry);
            // Update RAT table with new dest renames
            utils.update_RAT(.id(m_trans.dest[i]), .new_id(dest_o_GR[i]));
            // For each rename checkpoint RAT
            utils.checkpoint_RAT();
          end
          $display("@ %0tps dest_o_0=%0d dest_o_1=%0d",$time(),dest_o_GR[0],dest_o_GR[1]);
          for (int i = 0; i < INSTR_COUNT; i++) begin
            if(GR_array[trans_pointer].dest[i] != DUT_array[trans_pointer].dest[i]) begin
              `uvm_fatal(get_type_name(),$sformatf("[ERROR] @ %0tps Expected GR_array[%0d].dest[%0d] = %p,\t but found %p",DUT_array[trans_pointer].sim_time,trans_pointer,i,GR_array[trans_pointer].dest[i], DUT_array[trans_pointer].dest[i] ))
            end
          end
        end

        // First, recover RAT
        if(flush_array[trans_pointer].flushed) begin
          // $display("Flushed trans: %0d",trans_pointer);
          utils.mark_flushed_Ins(flush_array[trans_pointer].flush_to_rob_id);
          utils.recover_RAT(flush_array[trans_pointer].flush_to_rob_id);
        end
        // Second, reverse all renames after flush to recover FreeList




        trans_pointer++;
      end // if (queue.size>0)

      @(negedge vif.clk);
    end


  endtask : RR_Golden_Ref


  int trans_pointer_2;
  result_array_entry_s [(TRANS_NUM*INSTR_COUNT)-1:0] DUT_array;
  task monitor_DUT_out();
    forever begin 
      if(vif.l_dst_valid && (!vif.stall || vif.rec_en)) begin
        for (int i = 0; i < INSTR_COUNT; i++) begin
          DUT_array[trans_pointer_2].dest[i] = vif.alloc_p_reg[i];
          DUT_array[trans_pointer_2].rob_id[i] = vif.alloc_rob_id[i];
          DUT_array[trans_pointer_2].rht_id[i] = vif.alloc_rht_id[i];
          DUT_array[trans_pointer_2].sim_time  = $time();
          DUT_array[trans_pointer_2].valid_entry = 1;
        end

        flush_array[trans_pointer_2].flushed = vif.rec_en;
        flush_array[trans_pointer_2].renamed = ~vif.stall;
        flush_array[trans_pointer_2].flush_to_rob_id = vif.rec_rob_id[0];
        flush_array[trans_pointer_2].valid_entry = 1;
        // $display("flush_array[%0d]=%p",trans_pointer_2,flush_array[trans_pointer_2]);
        trans_pointer_2++;
      end
      @(negedge vif.clk);
    end

  endtask : monitor_DUT_out




  task run_phase(uvm_phase phase);
    fork 
      RR_Golden_Ref();
      monitor_DUT_out();
    join_none
  endtask : run_phase

  int checked_trans = 0;
  int wrong_dests = 0;
  int correct_dests = 0;
  int correct_rob_id = 0;
  int correct_rht_id = 0;
  int wrong_rob_id = 0;
  int wrong_rht_id = 0;
  function void report_phase(uvm_phase phase);
    // Compare results
    for (int trans_i = 0; trans_i < trans_pointer; trans_i++) begin
      // skip checking for flushed transactions
      if(!flush_array[trans_i].flushed) begin
        // Check renamed instructions
        for (int i = 0; i < INSTR_COUNT; i++) begin
          if(GR_array[trans_i].dest[i] != DUT_array[trans_i].dest[i]) begin
            `uvm_error(get_type_name(),$sformatf("[ERROR] @ %0tps Expected GR_array[%0d].dest[%0d] = %p,\t but found %p",DUT_array[trans_i].sim_time,trans_i,i,GR_array[trans_i].dest[i], DUT_array[trans_i].dest[i] ))
            wrong_dests++;
          end else begin 
            correct_dests++;
          end

          if(GR_array[trans_i].rob_id[i] != DUT_array[trans_i].rob_id[i]) begin
            `uvm_error(get_type_name(),$sformatf("[ERROR] @ %0tps Expected GR_array[%0d].rob_id[%0d] = %p,\t but found %p",DUT_array[trans_i].sim_time,trans_i,i,GR_array[trans_i].rob_id[i], DUT_array[trans_i].rob_id[i] ))
            wrong_rob_id++;
          end else begin 
            correct_rob_id++;
          end


          if(GR_array[trans_i].rht_id[i] != DUT_array[trans_i].rht_id[i]) begin
            `uvm_error(get_type_name(),$sformatf("[ERROR] @ %0tps Expected GR_array[%0d].rht_id[%0d] = %p,\t but found %p",DUT_array[trans_i].sim_time,trans_i,i,GR_array[trans_i].rht_id[i], DUT_array[trans_i].rht_id[i] ))
            wrong_rht_id++;
          end else begin 
            correct_rht_id++;
          end
        end
      end
      checked_trans++;
    end
    $display("checked_trans=%0d",checked_trans);
    $display("correct_dests=%0d",correct_dests);
    $display("wrong_dests=%0d"  ,wrong_dests);
    $display("correct_rob_id=%0d",correct_rob_id);
    $display("wrong_rob_id=%0d"  ,wrong_rob_id);
    $display("correct_rht_id=%0d",correct_rht_id);
    $display("wrong_rht_id=%0d"  ,wrong_rht_id);
  endfunction : report_phase

  function void start_of_simulation_phase( uvm_phase phase );
    UVM_FILE RR_checker_file;
    RR_checker_file = $fopen("RR_checker.txt","w");
    set_report_severity_action(UVM_INFO,UVM_LOG);
    set_report_severity_action(UVM_ERROR,UVM_LOG);
    set_report_default_file( RR_checker_file );
  endfunction: start_of_simulation_phase

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);

    trans_pointer = 0;

    utils = new();
    wb = new("wb",this);
    commit = new("commit",this);
  endfunction : new



endclass : Checker

`endif