//-------------------------------------------------------------------------------------
//  RHT_DEPTH: # of RHT Entries
//  C_SIZE:    # Size of Checkpoint
//-------------------------------------------------------------------------------------
module RHT #(
  parameter RHT_DEPTH    = 128,
  parameter C_SIZE       = 32 ,
  parameter L_ADDR_WIDTH = 5  ,
  parameter P_ADDR_WIDTH = 8  ,
  parameter INSTR_COUNT  = 2
) (
  input  logic                                                clk           ,
  input  logic                                                rst_n         ,
  // Write Port
  input  logic                                                push          ,
  input  logic [      INSTR_COUNT-1:0][     L_ADDR_WIDTH-1:0] push_data_Ldst,
  input  logic [      INSTR_COUNT-1:0][     P_ADDR_WIDTH-1:0] push_data_Pdst,
  output logic [      INSTR_COUNT-1:0][$clog2(RHT_DEPTH)-1:0] id_out        ,
  //Redirection Port
  input  logic                                                set_ptr       ,
  input  logic [$clog2(RHT_DEPTH)-1:0]                        new_pointer   ,
  //Read Port
  input  logic [$clog2(RHT_DEPTH)-1:0]                        id_in         ,
  output logic [     L_ADDR_WIDTH-1:0]                        data_out_Ldst ,
  output logic [     P_ADDR_WIDTH-1:0]                        data_out_Pdst
);

  
    localparam RHT_TICKET = $clog2(RHT_DEPTH);

    logic [RHT_DEPTH-1:0][P_ADDR_WIDTH-1:0] rht_memory_Pdst;
    logic [RHT_DEPTH-1:0][L_ADDR_WIDTH-1:0] rht_memory_Ldst;
    logic [INSTR_COUNT-1:0][RHT_TICKET-1:0] tail_adj;
    logic [RHT_TICKET-1:0] tail;
  
    //Push Data out
    assign data_out_Ldst = rht_memory_Ldst[id_in];
    assign data_out_Pdst = rht_memory_Pdst[id_in];
    assign id_out        = tail_adj;


    //Create New Tail Pointers
    always_comb begin : TailAdj
        for (int k = 0; k < INSTR_COUNT; k++) begin
            if (tail + k > RHT_DEPTH-1) begin
                tail_adj[k] = tail + k - RHT_DEPTH;
            end else begin
                tail_adj[k] = tail +k;
            end
        end
    end
    //Store new Push
    always_ff @(posedge clk) begin : RHT_Management
        for (int i = 0; i < INSTR_COUNT; i++) begin
            if(push) begin
                rht_memory_Pdst[tail_adj[i]] <= push_data_Pdst[i];
                rht_memory_Ldst[tail_adj[i]] <= push_data_Ldst[i];
            end
        end
    end

    //Tail Management
    always_ff @(posedge clk or negedge rst_n) begin : Tail_Management
        if(~rst_n) tail <= 0;
        else begin
            if(set_ptr)
                tail <= new_pointer;
            else if(push)
                // tail <= (tail == RHT_DEPTH-1) ? 0 : tail+1;
                if (tail + INSTR_COUNT > RHT_DEPTH-1) tail <= tail + INSTR_COUNT - RHT_DEPTH;
                else tail <= tail + INSTR_COUNT;
        end
    end
endmodule



