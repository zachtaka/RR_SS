onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /top_tb/th/uut/clk
add wave -noupdate -radix unsigned /top_tb/th/uut/rst_n
add wave -noupdate -divider -height 20 {Instruction interface}
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/l_dst[1]} -radix unsigned} {{/top_tb/th/uut/l_dst[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/l_dst[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/l_dst[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/l_dst
add wave -noupdate -radix unsigned /top_tb/th/uut/l_dst_valid
add wave -noupdate -radix unsigned /top_tb/th/uut/inst_en
add wave -noupdate -radix unsigned /top_tb/th/uut/stall
add wave -noupdate -divider -height 20 Output
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/alloc_rob_id[1]} -radix unsigned} {{/top_tb/th/uut/alloc_rob_id[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/alloc_rob_id[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/alloc_rob_id[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/alloc_rob_id
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/alloc_rht_id[1]} -radix unsigned} {{/top_tb/th/uut/alloc_rht_id[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/alloc_rht_id[1]} {-radix unsigned} {/top_tb/th/uut/alloc_rht_id[0]} {-radix unsigned}} /top_tb/th/uut/alloc_rht_id
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/alloc_p_reg[1]} -radix unsigned} {{/top_tb/th/uut/alloc_p_reg[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/alloc_p_reg[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/alloc_p_reg[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/alloc_p_reg
add wave -noupdate -divider -height 20 {Flush interface}
add wave -noupdate -radix unsigned /top_tb/th/uut/rec_rht_id
add wave -noupdate -radix unsigned /top_tb/th/uut/rec_en
add wave -noupdate -radix unsigned /top_tb/th/uut/rec_busy
add wave -noupdate -divider -height 20 {Writeback interface}
add wave -noupdate -radix unsigned {/top_tb/th/uut/rec_rob_id[0]}
add wave -noupdate -radix unsigned {/top_tb/th/uut/wb_en[0]}
add wave -noupdate -radix unsigned {/top_tb/th/uut/rec_rob_id[1]}
add wave -noupdate -radix unsigned {/top_tb/th/uut/wb_en[1]}
add wave -noupdate -divider -height 20 RAT
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/RAT/CurrentRAT[31]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[30]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[29]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[28]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[27]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[26]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[25]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[24]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[23]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[22]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[21]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[20]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[19]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[18]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[17]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[16]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[15]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[14]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[13]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[12]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[11]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[10]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[9]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[8]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[7]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[6]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[5]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[4]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[3]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[2]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[1]} -radix unsigned} {{/top_tb/th/uut/RAT/CurrentRAT[0]} -radix unsigned}} -subitemconfig {{/top_tb/th/uut/RAT/CurrentRAT[31]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[30]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[29]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[28]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[27]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[26]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[25]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[24]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[23]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[22]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[21]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[20]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[19]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[18]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[17]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[16]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[15]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[14]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[13]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[12]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[11]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[10]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[9]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[8]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[7]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[6]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[5]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[4]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[3]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[2]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/RAT/CurrentRAT[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/RAT/CurrentRAT
add wave -noupdate -divider {Recover port}
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/rec_en
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/rec_id
add wave -noupdate -divider -height 20 FreeList
add wave -noupdate -radix unsigned /top_tb/th/uut/free_list/valid
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/free_list/push_data[1]} -radix unsigned} {{/top_tb/th/uut/free_list/push_data[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/free_list/push_data[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/free_list/push_data[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/free_list/push_data
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/free_list/push[1]} -radix unsigned} {{/top_tb/th/uut/free_list/push[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/free_list/push[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/free_list/push[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/free_list/push
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/free_list/pop_data[1]} -radix unsigned} {{/top_tb/th/uut/free_list/pop_data[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/free_list/pop_data[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/free_list/pop_data[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/free_list/pop_data
add wave -noupdate -radix unsigned /top_tb/th/uut/free_list/pop
add wave -noupdate -divider -height 20 ROB
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/ready
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/push
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/head
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/rob_memory_exec
add wave -noupdate -radix unsigned -childformat {{{/top_tb/th/uut/ROB/valid[1]} -radix unsigned} {{/top_tb/th/uut/ROB/valid[0]} -radix unsigned}} -expand -subitemconfig {{/top_tb/th/uut/ROB/valid[1]} {-height 15 -radix unsigned} {/top_tb/th/uut/ROB/valid[0]} {-height 15 -radix unsigned}} /top_tb/th/uut/ROB/valid
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/tail
add wave -noupdate -radix unsigned /top_tb/th/uut/ROB/head
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {540291 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 221
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {374640 ps} {665360 ps}
