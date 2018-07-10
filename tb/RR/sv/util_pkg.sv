package util_pkg;

// DUT parameters
parameter P_REGISTERS = 64;
parameter L_REGISTERS = 32; 
parameter C_NUM       = 4;  
parameter K           = 32;  
parameter INSTR_COUNT = 2;


// TB parameters
parameter int TRANS_NUM = 20000; // Transaction (or Instruction packets) that will be sent to the DUT
parameter int DEPENDENCE_RATE = 0; // rate=100 -> dest[0]==dest[1]==...==dest[INSTR_COUNT-1]
parameter int WRITEBACK_RATE = 100;
parameter int MIN_WB_PER_CYCLE = 0; // min writebacks per cycle: [1  ...INSTR_COUNT] this rate will be ceiled according to the available Ins for writeback
parameter int MAX_WB_PER_CYCLE = 1; // max writebacks per cycle: [MIN...INSTR_COUNT] this rate will be ceiled according to the available Ins for writeback
parameter int FLUSH_RATE = 1;

typedef struct {
  bit [INSTR_COUNT-1:0] wb_en;
  bit [INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] rob_id;
} writeback_s;

typedef struct {
  bit [INSTR_COUNT-1:0] valid_commit;
} commit_s;

typedef struct packed {
  bit [$clog2((C_NUM-1)*K)-1:0] rob_id;
  bit [$clog2(C_NUM*K)-1:0] rht_id;
  bit flushed;
  bit valid_entry;
} rob_rht_id_entry_s;

typedef struct packed { 
  bit [$clog2(L_REGISTERS)-1:0] lreg;
  bit [$clog2(P_REGISTERS)-1:0] preg;
  bit [$clog2(P_REGISTERS)-1:0] ppreg;
  bit [$clog2((C_NUM-1)*K)-1:0] rob_id;
  bit [$clog2(C_NUM*K)-1:0] rht_id;
  bit flushed;
  bit retired;
  bit valid_entry;
} rename_record_entry_s;

typedef struct packed {
  bit [INSTR_COUNT-1:0][$clog2(P_REGISTERS)-1:0] dest;
  bit [INSTR_COUNT-1:0][$clog2((C_NUM-1)*K)-1:0] rob_id;
  bit [INSTR_COUNT-1:0][$clog2(C_NUM*K)-1:0] rht_id;
  bit valid_entry;
  longint sim_time;
} result_array_entry_s;


typedef struct packed {
  bit [$clog2((C_NUM-1)*K)-1:0] flush_to_rob_id;
  bit flushed;
  bit renamed;
  bit valid_entry;
} flush_array_entry_s;


typedef struct packed {
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
} monitor_trans;

endpackage