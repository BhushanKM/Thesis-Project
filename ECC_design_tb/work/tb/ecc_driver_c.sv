//////////////////////////////////////////////////////////////////////////////////
// ECC Driver - Drives Transactions to DUT
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_driver_c extends uvm_driver #(ecc_transaction);

    `uvm_component_utils(ecc_driver_c)

    virtual ecc_interface vif;

    // Analysis port to send transactions to scoreboard
    uvm_analysis_port #(ecc_transaction) drv_ap;

    // Reference model for encoding
    bit [15:0] T_VALUES[19] = '{
        `T0, `T1, `T2, `T3, `T4, `T5, `T6, `T7, `T8, `T9,
        `T10, `T11, `T12, `T13, `T14, `T15, `T16, `T17, `T18
    };

    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv_ap = new("drv_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ecc_interface)::get(this, "", "ecc_vif", vif))
            `uvm_fatal("NO_VIF", {"Virtual interface not set for ", get_full_name(), ".ecc_vif"})
    endfunction

    task run_phase(uvm_phase phase);
        reset_signals();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        `uvm_info(get_type_name(), "Resetting interface signals", UVM_MEDIUM)
        // Initialize signals immediately
        @(posedge vif.clk);
        vif.drv_cb.test_mode_en <= 1'b0;
        vif.drv_cb.cw_sel       <= 1'b0;
        vif.drv_cb.wr_valid     <= 1'b0;
        vif.drv_cb.wr_data      <= '0;
        vif.drv_cb.rd_valid     <= 1'b0;
        vif.drv_cb.rd_codeword  <= '0;
        vif.drv_cb.burst_start  <= 1'b0;
        // Wait for reset to deassert
        wait(vif.rst_n === 1'b1);
        repeat(2) @(posedge vif.clk);
        `uvm_info(get_type_name(), "Reset complete, ready to drive", UVM_MEDIUM)
    endtask

    task drive_transaction(ecc_transaction txn);
        bit [`CODEWORD_WIDTH-1:0] encoded_cw;
        bit [`CODEWORD_WIDTH-1:0] corrupted_cw;

        `uvm_info(get_type_name(), $sformatf("Driving transaction: error_type=%s", txn.error_type.name()), UVM_HIGH)

        // Send transaction to scoreboard BEFORE driving to DUT
        drv_ap.write(txn);

        // Apply delay
        repeat(txn.delay) @(posedge vif.clk);

        // Set control signals
        vif.drv_cb.test_mode_en <= txn.test_mode;
        vif.drv_cb.cw_sel       <= txn.cw_sel;

        // Phase 1: Encode the data (write path)
        @(posedge vif.clk);
        vif.drv_cb.wr_valid <= 1'b1;
        vif.drv_cb.wr_data  <= txn.data;

        @(posedge vif.clk);
        vif.drv_cb.wr_valid <= 1'b0;

        // Wait for encoder output
        @(posedge vif.clk);
        while (!vif.drv_cb.enc_valid_out) @(posedge vif.clk);

        // Capture encoded codeword
        encoded_cw = vif.drv_cb.enc_codeword_out;

        // Phase 2: Inject error and decode (read path)
        corrupted_cw = txn.inject_error(encoded_cw);

        // Store codeword in transaction for scoreboard
        txn.codeword = corrupted_cw;

        @(posedge vif.clk);
        vif.drv_cb.rd_valid    <= 1'b1;
        vif.drv_cb.rd_codeword <= corrupted_cw;
        vif.drv_cb.burst_start <= 1'b1;

        @(posedge vif.clk);
        vif.drv_cb.rd_valid    <= 1'b0;
        vif.drv_cb.burst_start <= 1'b0;

        // Wait for decoder output
        @(posedge vif.clk);
        while (!vif.drv_cb.rd_out_valid) @(posedge vif.clk);

        // Small gap between transactions
        repeat(2) @(posedge vif.clk);

        `uvm_info(get_type_name(), "Transaction complete", UVM_HIGH)
    endtask

    // GF(2^16) multiplication for reference model
    function bit [15:0] gf_mul(bit [15:0] a, bit [15:0] b);
        bit [15:0] result = 0;
        bit [15:0] temp_a = a;
        for (int i = 0; i < 16; i++) begin
            if (b[i]) result ^= temp_a;
            if (temp_a[15]) temp_a = (temp_a << 1) ^ `GF_PRIMITIVE_POLY;
            else temp_a = temp_a << 1;
        end
        return result;
    endfunction

    // Reference encoder for verification
    function bit [`CODEWORD_WIDTH-1:0] ref_encode(bit [`DATA_WIDTH-1:0] data);
        bit [15:0] symbols[17];
        bit [15:0] P0, P1;

        // Extract symbols
        for (int i = 0; i < 17; i++)
            symbols[i] = data[(`DATA_WIDTH - 1 - i*16) -: 16];

        // Compute P0 = XOR of all data symbols
        P0 = 0;
        for (int i = 0; i < 17; i++)
            P0 ^= symbols[i];

        // Compute P1 = XOR of Ti*Di
        P1 = 0;
        for (int i = 0; i < 17; i++)
            P1 ^= gf_mul(T_VALUES[i], symbols[i]);

        return {data, P0, P1};
    endfunction

endclass
