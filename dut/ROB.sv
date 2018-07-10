//-------------------------------------------------------------------------------------
//  ROB_DEPTH: # of ROB Entries
//-------------------------------------------------------------------------------------
module ROB #(
    parameter ROB_DEPTH    = 128,
    parameter P_ADDR_WIDTH = 7  ,
    parameter INSTR_COUNT  = 2
) (
    input  logic                                                clk           ,
    input  logic                                                rst_n         ,
    //New entry write port
    output logic                                                ready         ,
    input  logic                                                push          ,
    input  logic [      INSTR_COUNT-1:0][     P_ADDR_WIDTH-1:0] new_entry     ,
    output logic [      INSTR_COUNT-1:0][$clog2(ROB_DEPTH)-1:0] id_out        , //The pushed entry's id (tail + i)
    //Writeback write port
    input  logic [      INSTR_COUNT-1:0]                        wb_en         ,
    input  logic [      INSTR_COUNT-1:0][$clog2(ROB_DEPTH)-1:0] wb_id         ,
    //Read port
    input  logic [      INSTR_COUNT-1:0]                        pop           ,
    output logic [      INSTR_COUNT-1:0]                        valid         ,
    output logic [      INSTR_COUNT-1:0]                        pop_data_exec ,
    output logic [      INSTR_COUNT-1:0][     P_ADDR_WIDTH-1:0] pop_data_PPdst,
    //Recover port
    input  logic                                                rec_en        ,
    input  logic [$clog2(ROB_DEPTH)-1:0]                        rec_id
);


logic [INSTR_COUNT-1:0][$clog2(ROB_DEPTH)-1:0] head_adj, tail_adj;
logic [$clog2(ROB_DEPTH)-1:0] tail, head;
logic [        ROB_DEPTH-1:0] rob_memory_exec;
logic [ROB_DEPTH-1:0][P_ADDR_WIDTH-1:0]        rob_memory_PPdst;
logic [INSTR_COUNT-1:0][ROB_DEPTH-1:0]         tail_oh;
logic [INSTR_COUNT-1:0][ROB_DEPTH-1:0]         wb_id_oh;//One-hot
logic last_push;



always_comb begin    
    tail_adj[0] = tail;
    head_adj[0] = head;
    for (int i = 1; i < INSTR_COUNT; i++) begin
        tail_adj[i] = ((tail + i) > ROB_DEPTH-1) ? (tail + i - ROB_DEPTH) 
                                                 : (tail + i);
        head_adj[i] = ((head + i) > ROB_DEPTH-1) ? (head + i - ROB_DEPTH) 
                                                 : (head + i);
    end
    for (int i = 0; i < INSTR_COUNT; i++) begin
        wb_id_oh[i] = (1 << wb_id[i]);
    end
end

generate
    genvar t;
    assign tail_oh[0]  = (1 << tail);
    for (t = 1; t < INSTR_COUNT; t++) begin
        barrel_shifter #(
            .DW       (ROB_DEPTH  ),
            .MAX_SHIFT(INSTR_COUNT)
        ) push_ptr_shft (
            .data_i  (tail_oh[0]),
            .sft_wb_i(t         ), //Shift magnitude in weighted binary
            .data_o  (tail_oh[t])
        );
    end
endgenerate


always_ff @(posedge clk, negedge rst_n) begin : readyManagement
  if(!rst_n) ready <= 1'b1;
  else begin
    if(push) begin
      ready <= (tail>=head) ? ((tail-head) <  (ROB_DEPTH-(INSTR_COUNT*2)))  // Occupied <  ()
                            : ((head-tail) >= (INSTR_COUNT*2));             // Free     >= ()
    end else if (!ready) begin
      ready <= (tail>=head) ? ((tail-head) <  (ROB_DEPTH-INSTR_COUNT))      // Occupied <  ()
                            : ((head-tail) >= INSTR_COUNT);                 // Free     >= ()
    end
  end
end

always_ff @(posedge clk or negedge rst_n) begin : lastPush
    if(~rst_n) begin
        last_push <= 0;
    end else begin
        if(push && !pop[INSTR_COUNT-1]) begin
            last_push <= 1;
        end else if (!push && |pop) begin
            last_push <= 0;
        end
    end
end

always_comb begin : validOut
    if(tail > head) begin
        valid = ((1 << (tail-head)) - 1);
    end else if(tail < head) begin
        valid = ((1 << (ROB_DEPTH - (head-tail))) - 1);
    end else begin
        valid = {INSTR_COUNT{last_push}};
    end
end
// assign valid = (tail >= head) ? ((1 << (tail-head)) - 1)                   //Occupied to thermometer
                             // : ((1 << (ROB_DEPTH - (head-tail))) - 1);    //All - Free to thermometer

always_ff @(posedge clk or negedge rst_n) begin : TailManagement
    if(!rst_n)      tail <= 0;
    else if(rec_en) begin
        // tail <= rec_id;
        if (rec_id > ROB_DEPTH-1) tail <= rec_id - ROB_DEPTH;
        else tail <= rec_id;
    end else if(push) begin
        //- In case of ROB_DEPTH == 2**n, the limit check may be omitted.
        if (tail + INSTR_COUNT > ROB_DEPTH-1) tail <= tail + INSTR_COUNT - ROB_DEPTH;
        else tail <= tail + INSTR_COUNT;
    end
end

always_ff @(posedge clk or negedge rst_n) begin : HeadManagement
    if(!rst_n)   head <= 0;
    else begin
        for (int i = 0; i < INSTR_COUNT; i++) begin
            //- In case of ROB_DEPTH == 2**n, the limit check may be omitted.
            if(pop[i]) begin
                if (head + i+1 > ROB_DEPTH-1) head <= head + i+1 - ROB_DEPTH;
                else head <= head + i+1;
            end
        end
    end
end

// Dual port write
always_ff @(posedge clk) begin : execHandler
  for (int i=0; i<ROB_DEPTH; i++) begin
    for (int k = 0; k < INSTR_COUNT; k++) begin
      if      (push && tail_oh[k][i])   rob_memory_exec[i] <= 1'b0;
      else if (wb_en[k] && wb_id_oh[k][i]) rob_memory_exec[i] <= 1'b1;
    end            
  end
end

always_ff @(posedge clk) begin : MemoryManagement_2
  if(push) begin
    for (int i = 0; i < INSTR_COUNT; i++)
      rob_memory_PPdst[tail_adj[i]] <= new_entry[i];
  end
end

//Push Data Out
always_comb begin : DataOut
    for (int i = 0; i < INSTR_COUNT; i++) begin
        pop_data_exec[i]  = rob_memory_exec[head_adj[i]];
        pop_data_PPdst[i] = rob_memory_PPdst[head_adj[i]];
    end
end

//Create the IDs out
// assign id_out = tail;
logic [INSTR_COUNT-1:0][$clog2(ROB_DEPTH)-1:0] id_out_interm;
generate
    genvar i;
    for (i = 0; i < INSTR_COUNT; i++) begin
        assign id_out_interm[i] = tail +i;
        assign id_out[i] = (id_out_interm[i] > ROB_DEPTH-1) ? (id_out_interm[i]-ROB_DEPTH) : id_out_interm[i];
    end
endgenerate

endmodule

