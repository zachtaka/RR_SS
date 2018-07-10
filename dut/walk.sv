//-------------------------------------------------------------------------------------
//  RHT_ID_WIDTH: # of Ticket Bits for RHT
//  C_ADDR:       # of Bits for Checkpoint Addressing
//  K:            Checkpoint Capture Period
//-------------------------------------------------------------------------------------
module walk 
#(parameter RHT_ID_WIDTH = 8,
  parameter C_ADDR       = 2,
  parameter K            = 32) 

(input logic clk,
 input logic rst_n,
 
 //Input Port
 input   logic                    rec_en,
 input   logic [RHT_ID_WIDTH-1:0] rec_rht_id,
 input   logic [RHT_ID_WIDTH-1:0] rht_id_out,
 
 //Current Walk Status
 output  logic [RHT_ID_WIDTH-1:0] walk_point,
 output  logic                    rec_state,
 output  logic                    in_reclaim,
 
 //RHT reDirect Port
 output  logic                    rht_set_ptr,
 output  logic [RHT_ID_WIDTH-1:0] new_pointer,

 output logic  [C_ADDR-1:0]       new_checkpoint
 );
logic [RHT_ID_WIDTH-1:0] walk_point_plus;
assign walk_point_plus = walk_point + 1;
logic [RHT_ID_WIDTH-1:0] rht_id_out_minus;
assign rht_id_out_minus = rht_id_out -1;
//-------------------------------------------------
//Recovering states
typedef enum logic[1:0] {IDLE, RESTORE, RECLAIM} walk;

logic [RHT_ID_WIDTH-1:0] target_rht_ticket;
walk                     walk_state;

assign rec_state       = ~(walk_state == IDLE);
assign in_reclaim      = (walk_state == RECLAIM);

assign new_checkpoint  = rec_rht_id[RHT_ID_WIDTH-1 : $clog2(K)];     //new checkpoint for RAT
assign new_pointer     = (target_rht_ticket+1);                      //new pointer for RHT after walk is finished
assign rht_set_ptr     = (walk_point == rht_id_out_minus) & rec_state;  //RAT driver signal

// Walk
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) walk_state <= IDLE;
    else begin
        unique case (walk_state)
            IDLE:   if(rec_en) begin
                        target_rht_ticket <= rec_rht_id;
                        walk_point        <= new_checkpoint << $clog2(K);
                        walk_state <= RESTORE;
                    end else
                        walk_state <= IDLE;
            
            RESTORE:begin 
                        walk_point <= walk_point + 1;
                        if(walk_point == target_rht_ticket) 
                            walk_state <= RECLAIM;
                        else
                            walk_state <= RESTORE;
                    end
                    
            RECLAIM:begin
                        walk_point <= walk_point + 1;
                        if(walk_point_plus == rht_id_out) 
                            walk_state <= IDLE;
                        else
                            walk_state <= RECLAIM;
                    end
        endcase
    end
end


endmodule