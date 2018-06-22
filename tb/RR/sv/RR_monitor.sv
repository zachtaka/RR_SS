`ifndef RR_MONITOR_SV
`define RR_MONITOR_SV


class RR_monitor extends uvm_monitor;
  `uvm_component_utils(RR_monitor)

  virtual RR_if vif;

  uvm_analysis_port #(trans) analysis_port;
  uvm_analysis_port #(writeback_s) wb_port;
  writeback_s wb_trans;


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
      @(negedge vif.clk);
    end
  endtask : run_phase


endclass : RR_monitor 



`endif 

