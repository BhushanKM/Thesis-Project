class rs_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rs_scoreboard)
    
    uvm_analysis_imp #(rs_item, rs_scoreboard) item_collected_export;
    
    // Internal queue to store expected results
    logic [15:0] expected_queue[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    // This is where you compare RTL output vs Expected
    virtual function void write(rs_item item);
        // 1. Calculate Expected Parity (Reference Model)
        // 2. Compare with item.parity from Monitor
        if (item.data_out != expected_val)
            `uvm_error("SCB", "Mismatch detected!")
        else
            `uvm_info("SCB", "Match successful", UVM_LOW)
    endfunction
endclass