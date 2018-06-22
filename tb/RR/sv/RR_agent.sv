// You can insert code here by setting file_header_inc in file common.tpl

//=============================================================================
// Project  : generated_tb
//
// File Name: RR_agent.sv
//
//
// Version:   1.0
//
// Code created by Easier UVM Code Generator version 2016-08-11 on Sun Jun 17 14:13:58 2018
//=============================================================================
// Description: Agent for RR
//=============================================================================

`ifndef RR_AGENT_SV
`define RR_AGENT_SV

// You can insert code here by setting agent_inc_before_class in file renaming.tpl

class RR_agent extends uvm_agent;

  `uvm_component_utils(RR_agent)

  uvm_analysis_port #(trans) analysis_port;

  RR_config       m_config;
  RR_sequencer_t  m_sequencer;
  RR_driver       m_driver;
  RR_driver_wb_fl m_driver_wb_fl;
  RR_monitor      m_monitor;

  local int m_is_active = -1;

  extern function new(string name, uvm_component parent);

  // You can remove build/connect_phase and get_is_active by setting agent_generate_methods_inside_class = no in file renaming.tpl

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function uvm_active_passive_enum get_is_active();

  // You can insert code here by setting agent_inc_inside_class in file renaming.tpl

endclass : RR_agent 


function  RR_agent::new(string name, uvm_component parent);
  super.new(name, parent);
  analysis_port = new("analysis_port", this);
endfunction : new


// You can remove build/connect_phase and get_is_active by setting agent_generate_methods_after_class = no in file renaming.tpl

function void RR_agent::build_phase(uvm_phase phase);

  // You can insert code here by setting agent_prepend_to_build_phase in file renaming.tpl

  if (!uvm_config_db #(RR_config)::get(this, "", "config", m_config))
    `uvm_error(get_type_name(), "RR config not found")

  m_monitor = RR_monitor::type_id::create("m_monitor", this);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver       = RR_driver      ::type_id::create("m_driver", this);
    m_driver_wb_fl = RR_driver_wb_fl::type_id::create("m_driver_wb_fl", this);
    m_sequencer    = RR_sequencer_t ::type_id::create("m_sequencer", this);
  end

  // You can insert code here by setting agent_append_to_build_phase in file renaming.tpl

endfunction : build_phase


function void RR_agent::connect_phase(uvm_phase phase);
  if (m_config.vif == null)
    `uvm_warning(get_type_name(), "RR virtual interface is not set!")

  m_monitor.vif = m_config.vif;
  m_monitor.analysis_port.connect(analysis_port);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_driver.vif = m_config.vif;
    m_driver_wb_fl.vif = m_config.vif;
  end

  // You can insert code here by setting agent_append_to_connect_phase in file renaming.tpl

endfunction : connect_phase


function uvm_active_passive_enum RR_agent::get_is_active();
  if (m_is_active == -1)
  begin
    if (uvm_config_db#(uvm_bitstream_t)::get(this, "", "is_active", m_is_active))
    begin
      if (m_is_active != m_config.is_active)
        `uvm_warning(get_type_name(), "is_active field in config_db conflicts with config object")
    end
    else 
      m_is_active = m_config.is_active;
  end
  return uvm_active_passive_enum'(m_is_active);
endfunction : get_is_active


// You can insert code here by setting agent_inc_after_class in file renaming.tpl

`endif // RR_AGENT_SV

