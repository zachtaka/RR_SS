import util_pkg::*;
class checker_utils;
  localparam P_ADDR_WIDTH = $clog2(P_REGISTERS);
  localparam L_ADDR_WIDTH = $clog2(L_REGISTERS);
  localparam L_REGS = 2 ** L_ADDR_WIDTH;


  // ------------------------     RAT implementetion     --------------------------------
  bit [L_REGS-1:0][P_ADDR_WIDTH-1:0] rat_table;
  bit [(TRANS_NUM*INSTR_COUNT)-1:0][L_REGS-1:0][P_ADDR_WIDTH-1:0] saved_RAT;
  bit [$clog2(TRANS_NUM*INSTR_COUNT)-1:0] rat_rename_pointer;

  // Update RAT with new rename
  function void update_RAT(input int id, input int new_id);
    rat_table[id] = new_id;
  endfunction : update_RAT

  // Get reg assign to lreg from RAT
  function int get_id_from_RAT(input int id);
    return rat_table[id];
  endfunction : get_id_from_RAT

  // If branch then checkpoint RAT
  // function void checkpoint_RAT();
  //   saved_RAT[rat_rename_pointer] = rat_table;
  //   // $display("@%0tps Saved rat_table[%0d]:%p",$time(),rat_rename_pointer,rat_table);
  //   rat_rename_pointer++;
  // endfunction : checkpoint_RAT

  // Recover RAT to flush id
  // function void recover_RAT(input int rename_pointer);
  //   rat_table = saved_RAT[rename_pointer];
  //   // $display("@%0tps Recovered rat_table[%0d]:%p",$time(),id,rat_table);
  // endfunction : recover_RAT
  
  // ------------------------     RAT implementetion     --------------------------------

  // ------------------------   FreeList implementetion  --------------------------------
  int free_list[$];
  int saved_FL[TRANS_NUM*INSTR_COUNT-1:0][$] ;
  rename_record_entry_s [TRANS_NUM*INSTR_COUNT-1:0] rename_record;
  int rename_ins_pointer, alloc_rob_id, alloc_rht_id;
  int last_valid_idx;
  bit valid_idx;
  // Get a free reg from free list
  function int get_free_reg();
    assert (free_list.size()>0) else $fatal("Popping on empty free list");
    return free_list.pop_front();
  endfunction : get_free_reg

  // Push freed reg from commit to free list
  function void release_reg(input writeback_s wb_i);
    for (int i = 0; i < INSTR_COUNT; i++) begin
      if(wb_i.wb_en[i]) begin
        // Search at Rename record array for the last entry with that rob id
        valid_idx = 0;
        for (int j = 0; j < rename_ins_pointer; j++) begin
          if(rename_record[j].rob_id==wb_i.rob_id[i]) begin
            last_valid_idx = j;
            valid_idx = 1;
          end 
        end
        if(valid_idx) begin
          free_list.push_back(rename_record[last_valid_idx].ppreg);
          $display("Writeback(from rob_id=%0d) from rename_entry[%0d]: released reg:%0d",wb_i.rob_id,last_valid_idx,rename_record[last_valid_idx].ppreg);
        end else begin 
          $fatal("Didnt found rename entry with that rob id:%0d?!",wb_i.rob_id[i]);
        end
      end
    end
    // ToDo enable assertion when bug is fixed
    // assert (free_list.size()<=(P_REGISTERS-L_REGISTERS)) else $fatal("Pushing on full free list");
  endfunction : release_reg

  int Ins_retire_pointer;
  function release_reg_2(input int retire_rob_id);
    // for (int i = 0; i < INSTR_COUNT; i++) begin
    //   while (rename_record[Ins_retire_pointer].flushed) begin 
    //     Ins_retire_pointer++;
    //   end
    //   if(commit.valid_commit[i]) begin
    //     rename_record[Ins_retire_pointer].retired = 1;
    //     free_list.push_back(rename_record[Ins_retire_pointer].ppreg);
    //     $display("",);
    //     $display("@ %0tps released reg:%0d from rename_pointer[%0d]=%p",$time(),rename_record[Ins_retire_pointer].ppreg,Ins_retire_pointer,rename_record[Ins_retire_pointer]);
    //     Ins_retire_pointer++;
    //   end
    // end

    // Search at Rename record array for the last entry with that rob id
    valid_idx = 0;
    for (int j = 0; j < rename_ins_pointer; j++) begin
      if(rename_record[j].rob_id==retire_rob_id) begin
        last_valid_idx = j;
        valid_idx = 1;
      end 
    end
    if(valid_idx) begin
      free_list.push_back(rename_record[last_valid_idx].ppreg);
      $display("Writeback(rob_id=%0d) from rename_entry[%0d]:%p released reg:%0d",retire_rob_id,last_valid_idx,rename_record[last_valid_idx],rename_record[last_valid_idx].ppreg);
    end else begin 
      $fatal("Didnt found rename entry with that rob id:%0d?!",retire_rob_id);
    end
  endfunction : release_reg_2

  // Get number of free regs
  function int free_reg_counter();
    return free_list.size();
  endfunction : free_reg_counter

  
  // ------------------------   FreeList implementetion  --------------------------------

  function void checkpoint_RAT();
    saved_RAT[rat_rename_pointer] = rat_table;
    // $display("FL to checkpoint: free_list[%0d]:%p",rat_rename_pointer,free_list);
    // saved_FL[rat_rename_pointer] = free_list;
    // $display("Saved free list[%0d]:%p",rat_rename_pointer,saved_FL[rat_rename_pointer]);
    rat_rename_pointer++;
  endfunction : checkpoint_RAT

  int rename_pointer;
  function void recover_RAT(input int rob_id);
    // Searching at rename_record array for the last rename with that rob_id 
    // to get the rename pointer of that instruction
    valid_idx = 0;
    for (int i = 0; i < rename_ins_pointer; i++) begin
      if(rename_record[i].rob_id==rob_id) begin
        rename_pointer = i;
        valid_idx = 1;
      end 
    end
    if(valid_idx) begin
      rat_table = saved_RAT[rename_pointer];
      $display("@%0tps Recovered rat_table:%p",$time(),rat_table);
      // free_list = saved_FL[rename_pointer];
      $display("@%0tps FreeList before recover:%p",$time(),free_list);
      for (int i = (rename_pointer+1); i < rename_ins_pointer; i++) begin
        free_list.push_back(rename_record[i].preg);
        $display("Reclaimed reg:%0d",rename_record[i].preg);
      end
      $display("FreeList after recover:%p",free_list);
      alloc_rob_id = rename_record[rename_pointer+1].rob_id;
      alloc_rht_id = rename_record[rename_pointer+1].rht_id;
    end else begin 
      $fatal("Didnt found rename entry with that rob id");
    end

    

  endfunction : recover_RAT

  // ------------------------   Rename record implementetion  --------------------------------
  
  
  function new_rename(input rename_record_entry_s new_rename_entry);
    rename_record[rename_ins_pointer].lreg = new_rename_entry.lreg;
    rename_record[rename_ins_pointer].preg = new_rename_entry.preg;
    rename_record[rename_ins_pointer].ppreg = new_rename_entry.ppreg;
    rename_record[rename_ins_pointer].rob_id = alloc_rob_id;
    rename_record[rename_ins_pointer].rht_id = alloc_rht_id;
    rename_record[rename_ins_pointer].valid_entry = 1;
    $display("@ %0tps new rename[%0d]: %p",$time(),rename_ins_pointer,rename_record[rename_ins_pointer]);
    // $display("FreeList after rename:%p",free_list);
    rename_ins_pointer++;
    alloc_rob_id++;
    alloc_rht_id++;
    if(alloc_rob_id==((C_NUM-1)*K)) alloc_rob_id = 0;
    if(alloc_rht_id==(C_NUM*K))     alloc_rht_id = 0;
  endfunction : new_rename

  function mark_flushed_Ins(input int flush_rob_id);
    for (int i = (Ins_retire_pointer+1); i < rename_ins_pointer; i++) begin
      rename_record[i].flushed = 1;
    end
  endfunction : mark_flushed_Ins

  // ------------------------   Rename record implementetion  --------------------------------

  // Constructor
  function new();
    rat_rename_pointer = 0;
    rename_ins_pointer = 0;
    Ins_retire_pointer = 0;
    alloc_rob_id = 0;
    alloc_rht_id = 0;

    for (int i=0; i<L_REGISTERS; i++) begin
      // Initialize RAT table
      rat_table[i] = i;
    end

    for (int i = L_REGISTERS; i < P_REGISTERS; i++) begin
      // Initialize FreeList with free regs
      free_list.push_back(i);
    end
  endfunction : new

endclass : checker_utils