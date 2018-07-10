//-------------------------------------------------------------------------------------
//  P_ADDR_WIDTH: # of Data Bits
//  L_ADDR_WIDTH: # of Address Bits
//  L_REGS:       # of Entries in the Register File
//  C_NUM:        # of Checkpoints
//-------------------------------------------------------------------------------------
module RAT #(
    P_ADDR_WIDTH = 7,
    L_ADDR_WIDTH = 5,
    C_NUM        = 4,
    INSTR_COUNT  = 2
) (
    input  logic                                       clk                ,
    input  logic                                       rst_n              ,
    //Write Port
    input  logic [  INSTR_COUNT-1:0][L_ADDR_WIDTH-1:0] write_addr         ,
    input  logic [  INSTR_COUNT-1:0][P_ADDR_WIDTH-1:0] write_data         ,
    input  logic [  INSTR_COUNT-1:0]                   write_en           ,
    //Read Port
    input  logic [  INSTR_COUNT-1:0][L_ADDR_WIDTH-1:0] read_addr          ,
    output logic [  INSTR_COUNT-1:0][P_ADDR_WIDTH-1:0] read_data          ,
    //Checkpoint
    input  logic [$clog2(C_NUM)-1:0]                   new_checkpoint     ,
    input  logic                                       restore_checkpoint ,
    input  logic                                       take_checkpoint    ,
    input  logic [  INSTR_COUNT-1:0]                   instr_to_checkpoint
);


    localparam L_REGS = 2 ** L_ADDR_WIDTH;

    logic [C_NUM-1:0][L_REGS-1:0][P_ADDR_WIDTH-1 : 0]   CheckpointedRAT;
    logic [L_REGS-1:0][P_ADDR_WIDTH-1 : 0]              CurrentRAT;
    logic [$clog2(C_NUM)-1 : 0] head             ;
    logic [    INSTR_COUNT-1:0] therm_instr_check, masked_wr_en;

    //Current RAT Management
    always_ff @(posedge clk or negedge rst_n) begin : Curr_RAT
        if(~rst_n) begin
            //Initialize with 1-1 Paired Registers
            for (int i = 0; i < L_REGS; i++) begin
                CurrentRAT[i] <= i;
            end
        end else begin
            if(restore_checkpoint) begin
                CurrentRAT <= CheckpointedRAT[new_checkpoint];
            end else begin
                for (int i = 0; i < INSTR_COUNT; i++) begin
                    if (write_en[i]) begin
                        CurrentRAT[write_addr[i]] <= write_data[i];
                    end
                end
            end
        end
    end

    assign therm_instr_check = (instr_to_checkpoint) -1;
    //assign therm_instr_check = instr_to_checkpoint -1;
    assign masked_wr_en      = therm_instr_check & write_en;
    //Checkpoint Storing
    always_ff @(posedge clk) begin : StoreCheckpoints
        if(take_checkpoint) begin
            CheckpointedRAT[head] <= CurrentRAT;
            for (int i = 0; i < INSTR_COUNT; i++) begin
                if (masked_wr_en[i]) CheckpointedRAT[head][write_addr[i]] <= write_data[i];
            end
        end
    end
    
    //Head Management
    always_ff @(posedge clk or negedge rst_n) begin : HeadManagement
        if(~rst_n) head <= 0;
        else begin
            //Move Head after the taken checkpoint
            if(restore_checkpoint)   head <= new_checkpoint+1;
            else if(take_checkpoint) head <= head+1;
        end
    end

    //Push Data Out
    // assign read_data = CurrentRAT[read_addr];
    always_comb begin : DataOut
        for (int i = 0; i < INSTR_COUNT; i++) begin
            read_data[i] = CurrentRAT[read_addr[i]];
        end
    end
    
endmodule
