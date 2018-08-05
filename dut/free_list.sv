module free_list #(
    parameter int DATA_WIDTH  = 7  ,
    parameter int RAM_DEPTH   = 128,
    parameter int L_REGISTERS = 32 ,
    parameter int INSTR_COUNT = 2
) (
    input  logic                                   clk      ,
    input  logic                                   rst      ,
    // input channel
    input  logic [INSTR_COUNT-1:0][DATA_WIDTH-1:0] push_data,
    input  logic [INSTR_COUNT-1:0]                 push     ,
    output logic                                   ready    ,
    // output channel
    output logic [INSTR_COUNT-1:0][DATA_WIDTH-1:0] pop_data ,
    output logic                                   valid    ,
    input  logic                                   pop
);

logic[RAM_DEPTH-1:0][DATA_WIDTH-1:0]  mem;
logic[RAM_DEPTH-1:0]                  pop_pnt, push_pnt, pop_pnt_new;
logic[RAM_DEPTH-1:0]                  push_pnt_new;
logic[INSTR_COUNT-1:0][RAM_DEPTH-1:0] pop_pnt_adj, push_pnt_adj;
logic[RAM_DEPTH  :0]                  status_cnt;
logic [$clog2(INSTR_COUNT+1)-1:0]       push_count;

// assign valid = ~status_cnt[0];
always_comb begin : ValidOut
    valid = ~status_cnt[0];
    for (int i = 1; i < INSTR_COUNT; i++) begin
        valid = valid & ~status_cnt[i];
    end
end
assign ready = ~status_cnt[RAM_DEPTH];

//Count the Pushes (one's counter)
always_comb begin : CountPush
    push_count = 0;
    for (int i = 0; i < INSTR_COUNT; i++) begin
        if (push[i]) push_count = push_count +1;
    end
end

// Shift push-pointer 
barrel_shifter
#(.DW        (RAM_DEPTH),
  .MAX_SHIFT (INSTR_COUNT))
push_ptr_shft
(
 .data_i   (push_pnt),
 .sft_wb_i (push_count),  //Shift magnitude in weighted binary
 .data_o   (push_pnt_new)
);

assign pop_pnt_new = {pop_pnt[RAM_DEPTH-INSTR_COUNT-1:0], pop_pnt[RAM_DEPTH-1 : RAM_DEPTH-INSTR_COUNT]};

//Pointer update (one-hot shifting pointers)
always_ff @ (posedge clk, posedge rst) begin: pnts
    if (rst) begin
        push_pnt <= 1 << RAM_DEPTH-L_REGISTERS;
        pop_pnt  <= 1;
    end else begin
        // push pointer
        push_pnt <= push_pnt_new;
        // pop pointer
        if (pop)  pop_pnt <= pop_pnt_new;
    end
end
    
// Status Counter (occupied slots)
always_ff @ (posedge clk, posedge rst) begin: st_cnt
    if (rst)
        status_cnt <= 1 << (RAM_DEPTH-L_REGISTERS); // status counter onehot coded
    else if (|push & (!pop) )
        // shift left status counter (increment)
        // status_cnt <= { status_cnt[RAM_DEPTH-1:0],1'b0 } ;
        status_cnt <= status_cnt << push_count;
    else if (!(|push) & pop ) 
        // shift right status counter (decrement)
        // status_cnt <= {1'b0, status_cnt[RAM_DEPTH:1] };
        status_cnt <= status_cnt >> INSTR_COUNT;
    else begin
        if(!push[INSTR_COUNT-1] & pop) begin
            status_cnt <= status_cnt >> (INSTR_COUNT - push_count);
        end
    end
end
 
// data write (push) 
// address decoding needed for onehot push pointer
always_ff @(posedge clk) begin
    if(rst) begin
        for (int i = L_REGISTERS; i < RAM_DEPTH; i++) begin
            mem[i-L_REGISTERS] <= i;
        end
    end else begin
        for (int i = 0; i < RAM_DEPTH; i++) begin
            for (int k = 0; k < INSTR_COUNT; k++) begin
                if(push[k] & push_pnt_adj[k][i]) begin
                    mem[i] <= push_data[k];
                end
            end
        end
    end
end

generate
    genvar i;
    for (i = 0; i < INSTR_COUNT; i++) begin

        //Push/Pop Pointers Adjustment for next cell positions
        // assign pop_pnt_adj[i] = pop_pnt << i;
        // assign push_pnt_adj[i] = push_pnt << i;

		barrel_shifter #(
			.DW       (RAM_DEPTH),
			.MAX_SHIFT(i        )
		) adj_push_pnt (
			.data_i  (push_pnt       ),
			.sft_wb_i(i              ), //Shift magnitude in weighted binary
			.data_o  (push_pnt_adj[i])
		);

		barrel_shifter #(
			.DW       (RAM_DEPTH),
			.MAX_SHIFT(i        )
		) adj_pop_pnt (
			.data_i  (pop_pnt       ),
			.sft_wb_i(i             ), //Shift magnitude in weighted binary
			.data_o  (pop_pnt_adj[i])
		);
    
        and_or_multiplexer #(
            .INPUTS    (RAM_DEPTH ),
            .DATA_WIDTH(DATA_WIDTH)
        ) mux_out (
            .data_in (mem           ),
            .sel     (pop_pnt_adj[i]),
            .data_out(pop_data[i]   )
        );
    end
endgenerate
    
assert property (@(posedge clk) disable iff(rst) |push |-> ready) else $fatal(1, "Pushing on full!");
assert property (@(posedge clk) disable iff(rst) |pop |-> valid) else $fatal(1, "Popping on empty!");
assert property (@(posedge clk) disable iff(rst) 1'b1 |-> (INSTR_COUNT>1)) else $fatal(1, "Code not verified/written for this Instr Count");
endmodule
