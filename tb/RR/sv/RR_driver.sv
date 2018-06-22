`ifndef RR_DRIVER_SV
`define RR_DRIVER_SV


class RR_driver extends uvm_driver #(trans);

  `uvm_component_utils(RR_driver)

  virtual RR_if vif;
  uvm_analysis_port #(trans) trans_port;
  trans req;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    trans_port = new("trans_port",this);
  endfunction : new

  task reset();
    vif.l_dst_valid <= 0;  
    vif.inst_en     <= 0;  
  endtask : reset



  task run_phase(uvm_phase phase);

    reset();
    wait(vif.rst_n);
    forever begin 
      seq_item_port.get_next_item(req);
      trans_port.write(req);

      vif.l_dst       <= req.dest;  
      vif.l_dst_valid <= 1;  
      vif.inst_en     <= 1;  
      @(posedge vif.clk);

      while (vif.stall) begin 
        @(posedge vif.clk);
      end

      seq_item_port.item_done();
      reset();
    end 
  
  endtask : run_phase

endclass : RR_driver 





`endif

