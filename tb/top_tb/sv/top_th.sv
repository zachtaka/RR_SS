import util_pkg::*;
module top_th;

  timeunit      1ns;
  timeprecision 1ps;

  logic clock = 0;
  logic reset;

  always #10 clock = ~clock;

  initial
  begin
    reset = 0;         // Active low reset in this example
    #50 reset = 1;
  end

  RR_if  RR_if_0 ();
  assign RR_if_0.clk = clock;
  assign RR_if_0.rst_n = reset;

  renaming #(
    // Change parameters at util_pkg.sv
    .P_REGISTERS (P_REGISTERS),
    .L_REGISTERS (L_REGISTERS),
    .C_NUM       (C_NUM),
    .K           (K),
    .INSTR_COUNT (INSTR_COUNT)
  ) uut (
    .clk         (RR_if_0.clk),
    .rst_n       (RR_if_0.rst_n),
    //L_Reg In Port
    .l_dst       (RR_if_0.l_dst),
    .l_dst_valid (RR_if_0.l_dst_valid),
    .inst_en     (RR_if_0.inst_en),
    .stall       (RR_if_0.stall),
    //IDs In
    .rec_rob_id  (RR_if_0.rec_rob_id),
    .rec_rht_id  (RR_if_0.rec_rht_id),
    //Recovery In
    .rec_en      (RR_if_0.rec_en),
    .rec_busy    (RR_if_0.rec_busy),
    //WriteBack In
    .wb_en       (RR_if_0.wb_en),
    //Alloc Out
    .alloc_rob_id(RR_if_0.alloc_rob_id),
    .alloc_rht_id(RR_if_0.alloc_rht_id),
    .alloc_p_reg (RR_if_0.alloc_p_reg),
    .commit_o_dbg(RR_if_0.commit_o_dbg)
  );

endmodule

