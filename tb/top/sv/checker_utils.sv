import util_pkg::*;
class checker_utils;
  localparam P_ADDR_WIDTH = $clog2(P_REGISTERS);
  localparam L_ADDR_WIDTH = $clog2(L_REGISTERS);
  localparam L_REGS = 2 ** L_ADDR_WIDTH;

  // RAT
  bit [L_REGS-1:0][P_ADDR_WIDTH-1:0] rat_table;
  bit [(SIM_RUNS*TRANS_NUM*INSTR_COUNT)-1:0][L_REGS-1:0][P_ADDR_WIDTH-1:0] saved_RAT;
  bit [$clog2(SIM_RUNS*TRANS_NUM*INSTR_COUNT)-1:0] rat_rename_pointer;
  // FreeList
  int free_list[$];
  int saved_FL[SIM_RUNS*TRANS_NUM*INSTR_COUNT-1:0][$];
  rename_record_entry_s [SIM_RUNS*TRANS_NUM*INSTR_COUNT-1:0] rename_record;
  int rename_ins_pointer, alloc_rob_id, alloc_rht_id;
  int last_valid_idx, index;
  bit valid_idx, valid;

  // ------------------------     General      --------------------------------

  // Search at Rename Record array for last rename with matching rob id
  // returns index of rename 
  function int search_last_rename(input int rob_id);
    valid = 0;
    for (int i = 0; i < rename_ins_pointer; i++) begin
      if(rename_record[i].rob_id==rob_id) begin
        index = i;
        valid = 1;
      end 
    end

    if(!valid) $fatal("Didnt found rename entry with that rob id:%0d?!",rob_id);
    return index;
  endfunction : search_last_rename

  function void recover_Checker(input int rob_id);
    // search for last rename with matching rob id and return index at Rename Record array
    index = search_last_rename(rob_id);
    // Recover RAT to last valid Ins rename
    rat_table = saved_RAT[index];
    // Recover FreeList
    // $display("FreeList before recover:%p",free_list);
    for (int i = (index+1); i < rename_ins_pointer; i++) begin
      free_list.push_back(rename_record[i].preg);
      // $display("Reclaimed reg:%0d",rename_record[i].preg);
    end
    // $display("FreeList after recover:%p",free_list);
    // Recover rob and rht id
    alloc_rob_id = rename_record[index+1].rob_id;
    alloc_rht_id = rename_record[index+1].rht_id;
  endfunction : recover_Checker

  // ------------------------     RAT      --------------------------------

  // Update RAT with new rename
  function void update_RAT(input int id, input int new_id);
    rat_table[id] = new_id;
  endfunction : update_RAT

  // Get reg assign to lreg from RAT
  function int get_id_from_RAT(input int id);
    return rat_table[id];
  endfunction : get_id_from_RAT

  // For each rename checkpoint RAT
  function void checkpoint_RAT();
    saved_RAT[rat_rename_pointer] = rat_table;
    rat_rename_pointer++;
  endfunction : checkpoint_RAT

  // ------------------------   FreeList   --------------------------------
  
  // Get a free reg from free list
  function int get_free_reg();
    assert (free_list.size()>0) else $fatal("Popping on empty free list");
    return free_list.pop_front();
  endfunction : get_free_reg

  // Release a reg from commit
  function release_reg(input int retire_rob_id);
    // search for last rename with matching rob id and return index at Rename Record array
    index = search_last_rename(retire_rob_id);
    // $display("[Release reg=%2d from commit with rob_id=%3d]",rename_record[index].ppreg,retire_rob_id);
    free_list.push_back(rename_record[index].ppreg);
  endfunction : release_reg

  // Get number of free regs
  function int free_reg_counter();
    return free_list.size();
  endfunction : free_reg_counter

  // ------------------------   Rename record   --------------------------------
  
  // Rename Record array keeps track of each rename
  function new_rename(input rename_record_entry_s new_rename_entry);
    rename_record[rename_ins_pointer].lreg = new_rename_entry.lreg;
    rename_record[rename_ins_pointer].preg = new_rename_entry.preg;
    rename_record[rename_ins_pointer].ppreg = new_rename_entry.ppreg;
    rename_record[rename_ins_pointer].rob_id = alloc_rob_id;
    rename_record[rename_ins_pointer].rht_id = alloc_rht_id;
    rename_record[rename_ins_pointer].valid_entry = 1;    
    // $display("@ %0tps new rename[%0d]: {lreg:%2d, preg:%2d, ppreg:%2d, rob_id:%2d, rht_id:%2d, flushed:%2d, retired:%2d, valid_entry:%2d}",$time(),rename_ins_pointer,rename_record[rename_ins_pointer].lreg,rename_record[rename_ins_pointer].preg,rename_record[rename_ins_pointer].ppreg,rename_record[rename_ins_pointer].rob_id,rename_record[rename_ins_pointer].rht_id,rename_record[rename_ins_pointer].flushed,rename_record[rename_ins_pointer].retired,rename_record[rename_ins_pointer].valid_entry);
    
    rename_ins_pointer++;
    alloc_rob_id++;
    alloc_rht_id++;
    if(alloc_rob_id==((C_NUM-1)*K)) alloc_rob_id = 0;
    if(alloc_rht_id==(C_NUM*K))     alloc_rht_id = 0;
  endfunction : new_rename





  // Initialize Checker components
  function new();
    rat_rename_pointer = 0;
    rename_ins_pointer = 0;
    alloc_rob_id = 0;
    alloc_rht_id = 0;

    // Initialize RAT table
    for (int i=0; i<L_REGISTERS; i++) begin
      rat_table[i] = i;
    end

    // Initialize FreeList with free regs
    for (int i = L_REGISTERS; i < P_REGISTERS; i++) begin
      free_list.push_back(i);
    end
  endfunction : new

endclass : checker_utils