`ifndef RR_COVERAGE_SV
`define RR_COVERAGE_SV

import util_pkg::*;

// 1) When declaring array of covergroup, covergroup  should be outside of coverage classs.
// from LRM: One cannot declare an array of an embedded covergroup inside class because the covergroup
// declared inside a class is an anonymous type and the covergroup name becomes the instance variable.
// 2) One need to use ref argument to access variable declared inside coverage class.
covergroup cg_port(string name_ , int port_num, ref monitor_trans m_item);
  option.per_instance = 1;
  option.name = name_;     // gives different name to each instance
  type_option.comment = "This instance covers only one Instruction port";
  coverpoint m_item.l_dst[port_num] 
  {
    bins cover_input_ldst_[] = {[L_REGISTERS:1]};
    illegal_bins cover_ldst_range_outofrange = default;
  }
endgroup

covergroup cg_common(ref int common_ldests, ref monitor_trans m_item);
  option.per_instance = 1;

  // How many ldest are equal in the same Ins packet
  ldest_depence_num : coverpoint common_ldests {
    bins common_ldest_num[] = {[INSTR_COUNT:0]};
  }

  // Cover flush id
  cp_flush_id: coverpoint m_item.rec_rob_id[0] iff(m_item.rec_en) {
    bins flush_to_rob_id[] = {[(C_NUM-1)*K-1:0]};
    illegal_bins misc_rob_id = default;
  }

endgroup : cg_common



class RR_coverage extends uvm_subscriber #(monitor_trans);
  `uvm_component_utils(RR_coverage)

  monitor_trans     m_item;
  int common_ldests;
  

  cg_port cg_port[INSTR_COUNT-1:0];
  cg_common cg_common;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    foreach (cg_port[i]) cg_port[i] = new($sformatf("cg_port_%0d",i),i,m_item);
    cg_common = new(common_ldests,m_item);
  endfunction : new


  function void write(input monitor_trans t);
    m_item = t;
    for (int i = 0; i < INSTR_COUNT; i++) begin
      cg_port[i].sample();
    end

    common_ldests = 0;
    for (int i = 0; i < (INSTR_COUNT-1) ; i++) begin
      if (m_item.l_dst[i] == m_item.l_dst[INSTR_COUNT-1]) begin 
        common_ldests++;
      end
    end
    cg_common.sample();

  endfunction : write


endclass : RR_coverage 

`endif 

