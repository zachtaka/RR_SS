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
  function void checkpoint_RAT();
    saved_RAT[rat_rename_pointer] = rat_table;
    // $display("@%0tps Saved rat_table[%0d]:%p",$time(),rat_rename_pointer,rat_table);
    rat_rename_pointer++;
  endfunction : checkpoint_RAT

  // Recover RAT to flush id
  function void recover_RAT(input int id);
    rat_table = saved_RAT[id];
    // $display("@%0tps Recovered rat_table[%0d]:%p",$time(),id,rat_table);
  endfunction : recover_RAT
  
  // ------------------------     RAT implementetion     --------------------------------

  // ------------------------   FreeList implementetion  --------------------------------
  int free_list[$];
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
        end else begin 
          $fatal("Didnt found rename entry with that rob id?!");
        end
      end
    end
    assert (free_list.size()<=(P_REGISTERS-L_REGISTERS)) else $fatal("Pushing on full free list");
  endfunction : release_reg

  // Get number of free regs
  function int free_reg_counter();
    return free_list.size();
  endfunction : free_reg_counter
  
  // ------------------------   FreeList implementetion  --------------------------------


  // ------------------------   Rename record implementetion  --------------------------------
  
  
  function new_rename(input rename_record_entry_s new_rename_entry);
    rename_record[rename_ins_pointer] = new_rename_entry;
    rename_record[rename_ins_pointer].rob_id = alloc_rob_id;
    rename_record[rename_ins_pointer].rht_id = alloc_rht_id;
    rename_record[rename_ins_pointer].valid_entry = 1;
    // $display("@ %0tps new rename: %p",$time(),rename_record[rename_ins_pointer]);
    rename_ins_pointer++;
    alloc_rob_id++;
    alloc_rht_id++;
    if(alloc_rob_id==((C_NUM-1)*K)) alloc_rob_id = 0;
    if(alloc_rht_id==(C_NUM*K)) alloc_rht_id = 0;
  endfunction : new_rename

  // ------------------------   Rename record implementetion  --------------------------------

  // Constructor
  function new();
    rat_rename_pointer = 0;
    rename_ins_pointer = 0;
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