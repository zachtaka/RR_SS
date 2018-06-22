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

endinterface : RR_if

`endif

