`ifndef RR_MONITOR_SV
`define RR_MONITOR_SV


class RR_monitor extends uvm_monitor;
  `uvm_component_utils(RR_monitor)

  virtual RR_if vif;

  uvm_analysis_port #(monitor_trans) analysis_port;
  uvm_analysis_port #(writeback_s) wb_port;
  writeback_s wb_trans;
  monitor_trans m_trans;


  function new(string name, uvm_component parent);
	  super.new(name, parent);
	  analysis_port = new("analysis_port", this);
	  wb_port = new("wb_port", this);
	endfunction : new

  task run_phase(uvm_phase phase);
    forever begin 

      wb_trans.wb_en  = vif.wb_en;
      wb_trans.rob_id = vif.rec_rob_id;
      wb_port.write(wb_trans);

      m_trans.l_dst        = vif.l_dst;        
      m_trans.l_dst_valid  = vif.l_dst_valid;  
      m_trans.inst_en      = vif.inst_en;      
      m_trans.stall        = vif.stall;        
      m_trans.rec_rob_id   = vif.rec_rob_id;   
      m_trans.rec_rht_id   = vif.rec_rht_id;   
      m_trans.rec_en       = vif.rec_en;       
      m_trans.rec_busy     = vif.rec_busy;     
      m_trans.wb_en        = vif.wb_en;        
      m_trans.alloc_rob_id = vif.alloc_rob_id; 
      m_trans.alloc_rht_id = vif.alloc_rht_id; 
      m_trans.alloc_p_reg  = vif.alloc_p_reg; 
      if((vif.rst_n)&&(vif.l_dst_valid && (!vif.stall || vif.rec_en))) begin 
        analysis_port.write(m_trans);
      end

      @(negedge vif.clk);
    end
  endtask : run_phase


endclass : RR_monitor 



`endif 

