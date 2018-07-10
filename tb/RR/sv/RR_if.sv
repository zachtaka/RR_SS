`ifndef RR_IF_SV
`define RR_IF_SV
import util_pkg::*;
interface RR_if(); 

  timeunit      1ns;
  timeprecision 1ps;

  import RR_pkg::*;

  logic clk;
  logic rst_n;
  //L_Reg In Port
  logic [    INSTR_COUNT-1:0][$clog2(L_REGISTERS)-1:0] l_dst       ;
  logic                                                l_dst_valid ;
  logic                                                inst_en     ;
  logic                                                stall       ;
  //IDs In
  logic [    INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] rec_rob_id  ;
  logic [$clog2(C_NUM*K)-1:0]                          rec_rht_id  ;
  //Recovery In
  logic                                                rec_en      ;
  logic                                                rec_busy    ;
  //WriteBack In
  logic [    INSTR_COUNT-1:0]                          wb_en       ;
  //Alloc Out
  logic [    INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] alloc_rob_id;
  logic [    INSTR_COUNT-1:0][    $clog2(C_NUM*K)-1:0] alloc_rht_id;
  logic [    INSTR_COUNT-1:0][$clog2(P_REGISTERS)-1:0] alloc_p_reg;

  logic [    INSTR_COUNT-1:0] commit_o_dbg;


// For a reason there are two valid signals (both should do the same job)
assert property(@(negedge clk) disable iff(!rst_n) l_dst_valid |-> inst_en) 
else $fatal("The signals l_dst_valid, inst_en must be equal");

// No writebacks should be issued while a recovery is issued or the DUT is in recovery state
assert property(@(negedge clk) disable iff(!rst_n) wb_en |-> (!rec_en && !rec_busy)) 
else $fatal("Writeback and recover at the same cycle");

// Check that no recovery is issued while DUT is already in recovery state
assert property(@(negedge clk) disable iff(!rst_n) rec_en |-> (!rec_busy)) 
else $fatal("Issuing recovery when DUT is in recovery state");

generate 
  for (genvar i = 0; i < INSTR_COUNT; i++) begin
    // Each allocated rob id should be in range [0,(C_NUM-1)*K)-1]
    assert property (@(negedge clk) disable iff(!rst_n) (l_dst_valid && !stall) |-> (alloc_rob_id[i]>=0)&&(alloc_rob_id[i]<((C_NUM-1)*K)))
    else $fatal("Allocated rob id out of range, alloc_rob_id[%0d]=%0d and valid range is [%0d,%0d]",i,alloc_rob_id[i],0,((C_NUM-1)*K)-1);
    // Each allocated rht id should be in range [0,(C_NUM*K)-1]
    assert property (@(negedge clk) disable iff(!rst_n) (l_dst_valid && !stall) |-> (alloc_rht_id[i]>=0)&&(alloc_rht_id[i]<(C_NUM*K))) 
    else $fatal("Allocated rht id out of range, alloc_rht_id[%0d]=%0d and valid range is [%0d,%0d]",i,alloc_rht_id[i],0,((C_NUM*K)-1));
    // Each writeback rob id should be in range [0,(C_NUM-1)*K)-1]
    assert property (@(negedge clk) disable iff(!rst_n) (wb_en[i]) |-> (rec_rob_id[i]>=0)&&(rec_rob_id[i]<((C_NUM-1)*K)))
    else $fatal("Writeback rob id out of range, rec_rob_id[%0d]=%0d and valid range is [%0d,%0d]",i,rec_rob_id[i],0,((C_NUM-1)*K)-1);
  end
endgenerate

// Recover rob id should be in range [0,(C_NUM-1)*K)-1]
assert property (@(negedge clk) disable iff(!rst_n) (rec_en) |-> (rec_rob_id[0]>=0)&&(rec_rob_id[0]<((C_NUM-1)*K)))
else $fatal("Recover to rob id out of range, rec_rob_id[0]=%0d and valid range is [%0d,%0d]",rec_rob_id[0],0,((C_NUM-1)*K)-1);
// Recover rht id should be in range [0,(C_NUM*K)-1]
assert property (@(negedge clk) disable iff(!rst_n) (rec_en) |-> (rec_rht_id>=0)&&(rec_rht_id<(C_NUM*K))) 
else $fatal("Allocated rht id out of range, rec_rht_id=%0d and valid range is [%0d,%0d]",rec_rht_id,0,((C_NUM*K)-1));


// L_dest stay valid till DUT accepts them (valid stall protocol check)
assert property(@(negedge clk) disable iff(!rst_n) (l_dst_valid && stall && !rec_en) |=> $stable(l_dst)) 
else $fatal("L_dest changed while valid && stall, violation of valid stall protocol");

// Check for X's in signals
generate 
  for (genvar i = 0; i < INSTR_COUNT; i++) begin
    assert property (@(negedge clk) disable iff(!rst_n)  l_dst_valid |-> (!$isunknown(l_dst[i]))) 
    else $fatal("X's in L_dst[%0d]=%0d",i,l_dst[i]);
    assert property (@(negedge clk) disable iff(!rst_n)  (l_dst_valid && !stall) |-> (!$isunknown(alloc_rob_id[i]))) 
    else $fatal("X's at DUT out alloc_rob_id[%0d]=%0d",i,alloc_rob_id[i]);
    assert property (@(negedge clk) disable iff(!rst_n)  (l_dst_valid && !stall) |-> (!$isunknown(alloc_rht_id[i]))) 
    else $fatal("X's at DUT out alloc_rht_id[%0d]=%0d",i,alloc_rht_id[i]);
    assert property (@(negedge clk) disable iff(!rst_n)  (wb_en[i]) |-> (!$isunknown(rec_rob_id[i]))) 
    else $fatal("X's at rec_rob_id[%0d]=%0d while issuing writeback",i,rec_rob_id[i]);
  end
endgenerate
assert property (@(negedge clk) disable iff(!rst_n)  (rec_en) |-> (!$isunknown(rec_rob_id[0]))) 
else $fatal("X's at rec_rob_id[0]=%0d while issuing recovery",rec_rob_id[0]);
assert property (@(negedge clk) disable iff(!rst_n)  (rec_en) |-> (!$isunknown(rec_rht_id))) 
else $fatal("X's at rec_rht_id=%0d while issuing recovery",rec_rht_id);


endinterface : RR_if

`endif

