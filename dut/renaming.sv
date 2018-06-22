//-------------------------------------------------------------------------------------
//  P_REGISTERS:    # of Physical Registers
//  L_REGISTERS:    # of Logical Registers
//  C_NUM:          # of Checkpoints
//  K:              Checkpoint Capture Period
//-------------------------------------------------------------------------------------
module renaming #(
    parameter P_REGISTERS = 128,
    parameter L_REGISTERS = 32 ,
    parameter C_NUM       = 4  ,
    parameter K           = 32 , 
    parameter INSTR_COUNT = 2
) (
    input  logic                                                clk         ,
    input  logic                                                rst_n       ,
    //L_Reg In Port
    input  logic [    INSTR_COUNT-1:0][$clog2(L_REGISTERS)-1:0] l_dst       ,
    input  logic                                                l_dst_valid ,
    input  logic                                                inst_en     ,
    output logic                                                stall       ,
    //IDs In
    input  logic [    INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] rec_rob_id  ,
    input  logic [$clog2(C_NUM*K)-1:0]                          rec_rht_id  ,
    //Recovery In
    input  logic                                                rec_en      ,
    output logic                                                rec_busy    ,
    //WriteBack In
    input  logic [    INSTR_COUNT-1:0]                          wb_en       ,
    //Alloc Out
    output logic [    INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] alloc_rob_id,
    output logic [    INSTR_COUNT-1:0][    $clog2(C_NUM*K)-1:0] alloc_rht_id,
    output logic [    INSTR_COUNT-1:0][$clog2(P_REGISTERS)-1:0] alloc_p_reg
);

localparam P_ADDR_WIDTH = $clog2(P_REGISTERS);
localparam L_ADDR_WIDTH = $clog2(L_REGISTERS);

localparam C_ADDR       = $clog2(C_NUM);
localparam C_SIZE       = L_REGISTERS;

localparam ROB_DEPTH    = (C_NUM-1)*K;
localparam ROB_ID_WIDTH = $clog2(ROB_DEPTH);

localparam RHT_DEPTH    = C_NUM * K;
localparam RHT_ID_WIDTH = $clog2(RHT_DEPTH);

logic [RHT_ID_WIDTH-1:0] walk_point;
logic                    do_alloc  ; // Signals that all conditions to do allocation are met
logic                    rec_state, in_reclaim; // Indicates that the renaming module is in recovery mode


//Free List
logic [INSTR_COUNT-1:0][P_ADDR_WIDTH-1 : 0] fl_push_data;
logic [INSTR_COUNT-1:0]                     fl_push ;
logic                                       fl_valid, fl_ready;

free_list #(
    .DATA_WIDTH (P_ADDR_WIDTH),
    .RAM_DEPTH  (P_REGISTERS ),
    .L_REGISTERS(L_REGISTERS ),
    .INSTR_COUNT(INSTR_COUNT )
) free_list (
    .clk      (clk         ),
    .rst      (~rst_n      ),
    .push_data(fl_push_data),
    .push     (fl_push     ),
    .ready    (fl_ready    ),
    .pop_data (alloc_p_reg ),
    .valid    (fl_valid    ),
    .pop      (do_alloc    )
);

//RAT (Rename Table)
logic [L_ADDR_WIDTH-1:0]    rename_valid;

logic [INSTR_COUNT-1:0][L_ADDR_WIDTH-1:0] rat_write_addr;
logic [INSTR_COUNT-1:0][P_ADDR_WIDTH-1:0] rat_data_out, rob_new_entries;
logic [INSTR_COUNT-1:0][P_ADDR_WIDTH-1:0] rat_write_data;
logic [INSTR_COUNT-1:0]                   rat_write_en, instr_to_checkpoint;

logic [C_ADDR-1:0]          new_checkpoint;
logic                       restore_checkpoint;
logic                       take_checkpoint;

RAT #(
    .P_ADDR_WIDTH(P_ADDR_WIDTH),
    .L_ADDR_WIDTH(L_ADDR_WIDTH),
    .C_NUM       (C_NUM       ),
    .INSTR_COUNT (INSTR_COUNT )
) RAT (
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    
    .write_en           (rat_write_en       ),
    .write_addr         (rat_write_addr     ),
    .write_data         (rat_write_data     ),
    
    .read_addr          (l_dst              ),
    .read_data          (rat_data_out       ),
    
    .take_checkpoint    (take_checkpoint    ),
    .instr_to_checkpoint(instr_to_checkpoint),
    .restore_checkpoint (restore_checkpoint ),
    .new_checkpoint     (new_checkpoint     )
);


//RHT
    //The RHT's pointer handling for recovery is done outside of RHT
logic [RHT_ID_WIDTH-1:0] new_pointer;
logic [L_ADDR_WIDTH-1:0] rht_data_out_Ldst;
logic [P_ADDR_WIDTH-1:0] rht_data_out_Pdst;

logic                    rht_set_ptr;

RHT #(
    .RHT_DEPTH   (RHT_DEPTH   ),
    .C_SIZE      (C_SIZE      ),
    .L_ADDR_WIDTH(L_ADDR_WIDTH),
    .P_ADDR_WIDTH(P_ADDR_WIDTH),
    .INSTR_COUNT (INSTR_COUNT )
) RHT (
    .clk           (clk              ),
    .rst_n         (rst_n            ),
    
    .push          (do_alloc         ),
    .id_out        (alloc_rht_id     ),
    
    .push_data_Ldst(l_dst            ),
    .push_data_Pdst(alloc_p_reg      ),
    
    .set_ptr       (rht_set_ptr      ),
    .new_pointer   (new_pointer      ),
    .id_in         (walk_point       ),
    .data_out_Ldst (rht_data_out_Ldst),
    .data_out_Pdst (rht_data_out_Pdst)
);  


//ROB (Re-Order Buffer)	
logic                                     rob_ready;
logic [ROB_ID_WIDTH-1:0]                  rob_id_out, rob_id_in_temp;
logic [INSTR_COUNT-1:0][P_ADDR_WIDTH-1:0] rob_data_out_PPdst;
logic [INSTR_COUNT-1:0]                   commit, rob_valid; // Signals the ROB to pop data
logic [INSTR_COUNT-1:0]                   rob_data_out_exec;

assign rob_id_in_temp = rec_rob_id[0] +1;

ROB #(
    .ROB_DEPTH   (ROB_DEPTH   ),
    .P_ADDR_WIDTH(P_ADDR_WIDTH),
    .INSTR_COUNT (INSTR_COUNT )
) ROB (
    .clk           (clk               ),
    .rst_n         (rst_n             ),
    
    .ready         (rob_ready         ),
    .push          (do_alloc          ),
    .id_out        (alloc_rob_id      ),
    .new_entry     (rob_new_entries   ), //rat_data_out
    
    .wb_en         (wb_en             ),
    .wb_id         (rec_rob_id        ),
    
    .rec_en        (rec_en            ),
    .rec_id        (rob_id_in_temp    ),
    
    .pop_data_exec (rob_data_out_exec ),
    .pop_data_PPdst(rob_data_out_PPdst),
    .pop           (commit            ),
    .valid         (rob_valid         )
);


//Walk Module
walk #(.RHT_ID_WIDTH  (RHT_ID_WIDTH),
       .K             (K),
       .C_ADDR        (C_ADDR)) 

walk  (.clk            (clk),
       .rst_n          (rst_n),

       .rec_en         (rec_en),
       .rec_rht_id     (rec_rht_id),
       .rht_id_out     (alloc_rht_id[0]),

       .walk_point     (walk_point),
       .rec_state      (rec_state),
       .in_reclaim     (in_reclaim),

       .rht_set_ptr    (rht_set_ptr),
       .new_pointer    (new_pointer),
       .new_checkpoint (new_checkpoint));

//Create the ROB new_entry vector with the PPregs
logic [INSTR_COUNT-1:0][INSTR_COUNT-1:0]         match, final_match;
logic [INSTR_COUNT-1:0]                          one_found;
logic [INSTR_COUNT-1:0][$clog2(P_REGISTERS)-1:0] rob_data_picked;

// assign rob_new_entries[0] = rat_data_out[0];
// generate
//     genvar k, j;
//     assign match[0] = 'b0;
//     // Find for any matching lregs
//     for (k = 1; k < INSTR_COUNT; k++) begin
//         for (j = 0; j < k; j++) begin
//             assign match[k][j] = (l_dst[k] == l_dst[j]);
//         end
//         for (j = k; j < INSTR_COUNT; j++) begin
//             assign match[k][j] = 1'b0;
//         end
//     end
//     // The newest matching instruction will provide 
//     	// its preg as the new ppreg -> arbiter to keep only 1 match 
//     assign rob_data_picked[1] = alloc_p_reg[0];
//     if(INSTR_COUNT > 2) begin
//         for (k = 2; k < INSTR_COUNT; k++) begin
//             // Keep the first valid position
//             assign final_match[k] = (~match[k] + 1) & match[k]; //FPA
//             assign one_found[k]   = match[k];
//             and_or_multiplexer #(
//                 .INPUTS    (INSTR_COUNT ),
//                 .DATA_WIDTH(P_ADDR_WIDTH)
//             ) and_or_multiplexer (
//                 .data_in (alloc_p_reg       ),
//                 .sel     (final_match[k]    ),
//                 .data_out(rob_data_picked[k])
//             );
//         end
//     end
//     for (k = 1; k < INSTR_COUNT; k++) begin
//         assign rob_new_entries[k] = one_found[k] ? rob_data_picked[k] : rat_data_out[k];
//     end
// endgenerate

//Should create equivalent to the above circuit (eq_check + arbiter + selection)
// (a tree like description may help the tool to create a more optimized net -> tree-like)
always_comb begin
    for (int i=0; i<INSTR_COUNT; i++) begin
        rob_new_entries[i] = rat_data_out[i];

        for (int j=0; j<i; j++) begin
            if (l_dst[i] == l_dst[j])
                rob_new_entries[i] = alloc_p_reg[j];
        end
    end
end

//Checkpoint Capture
// assign take_checkpoint    = do_alloc & ~|(alloc_rht_id[$clog2(K)-1 : 0]);
always_comb begin : proc_TakeChk
    for (int i = 0; i < INSTR_COUNT; i++) begin
        instr_to_checkpoint[i] = do_alloc & ~|(alloc_rht_id[i][$clog2(K)-1 : 0]); 
    end
end
assign take_checkpoint = |instr_to_checkpoint;
//Restore Checkpoint (RAT driver signal)
assign restore_checkpoint = rec_en;     

//Ready_Valid assignments
    //Because RHT has only one pointer, there is no full condition (It's implicit to ROB)
assign stall    = ~(fl_valid & rob_ready) | rec_state;
assign rec_busy = rec_state;

//New Issue
assign do_alloc = (inst_en & l_dst_valid) & ~stall;

//RAT
always_comb begin : RATwrite
  rat_write_addr[0] = rec_state ?  rht_data_out_Ldst : l_dst[0];
  rat_write_en[0]   = rec_state ? ~in_reclaim        : do_alloc;
  rat_write_data[0] = rec_state ?  rht_data_out_Pdst : alloc_p_reg[0];
  
  for (int i = 1; i < INSTR_COUNT; i++) begin
    rat_write_en[i]   = rec_state ? 1'b0 : do_alloc;
    rat_write_addr[i] = l_dst[i];
    rat_write_data[i] = alloc_p_reg[i];
  end
end

// assign commit = rob_valid & rob_data_out_exec & 
                // ~rec_en & ~rec_state;
always_comb begin : InstrCommit
    for (int i = 0; i < INSTR_COUNT; i++) begin
        commit[i] = rob_valid[i] & rob_data_out_exec[i] & 
                    ~rec_en & ~rec_state;
    end
end
//FreeList
always_comb begin : FLpushData
    fl_push[0]      = rec_state ? in_reclaim : commit[0];                       
    fl_push_data[0] = rec_state ? rht_data_out_Pdst : rob_data_out_PPdst[0];
    for (int i = 1; i < INSTR_COUNT; i++) begin
        fl_push[i]      = rec_state ? 1'b0 : commit[i];                       
        fl_push_data[i] = rob_data_out_PPdst[i];
    end
end



// Remember that the ID (tail) of the data structures point to a slot that is
// empty (if not full) and where the next push will take place.
assert property (@(posedge clk) disable iff(!rst_n) commit |-> rob_valid) else $error("WriteBack on empty ROB!!");

// We assume that the given rob and rht ids are aligned and point to the last valid instruction.
assert property (@(posedge clk) disable iff(!rst_n) rec_en |-> ((rec_rht_id % K) == (rec_rob_id[0] % K)))
else $fatal(1, "The given ROB and RHT IDs are not aligned!(pointing to different instruction)");

//Writeback while recovering is dropped
assert property (@(posedge clk) disable iff(!rst_n) (rec_en || rec_state) |-> !wb_en)
else $warning("Writeback while recovery dropped.");

//A writeback should never happen to ROB entry that is push in the same time
// assert property (@(posedge clk) disable iff(!rst_n) (do_alloc && wb_en) |-> (rec_rob_id[0] != rob_id_out))
// else $fatal(1, "Writeback at the address currenlty allocating.");

assert property (@(posedge clk) disable iff(!rst_n) 1'b1 |-> (INSTR_COUNT>1)) 
else $fatal(1, "Code not verified/written for this Instr Count");


endmodule