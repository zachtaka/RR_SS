module barrel_shifter
#(
  parameter int DW        = 8,
  parameter int MAX_SHIFT = DW-1    // The maximum Shifting available (reduces stages)
)(
  input  logic[DW-1:0]                data_i,
  input  logic[$clog2(MAX_SHIFT+1)-1:0] sft_wb_i,  //Shift magnitude in weighted binary
  
  output logic[DW-1:0]                data_o
);

localparam STAGES = $clog2(MAX_SHIFT+1);   //STAGES refer to Mux stages

logic[STAGES:0][DW-1:0] stage_bits;        //0th stage_bits is directly the input (1Inp + STAGES)

always_comb begin : ShiftStages
  stage_bits[0] = data_i;
  for(int s=0; s<STAGES; ++s) begin
    for(int b=0; b<DW; ++b) begin
      stage_bits[s+1][b] = (sft_wb_i[s]) ? stage_bits[s][(b+DW-(2**s))%DW] : stage_bits[s][b];
    end
  end
end

assign data_o = stage_bits[STAGES];

initial assert (MAX_SHIFT<DW) else $fatal(1, "Why you need shift more than Data Width?");

endmodule