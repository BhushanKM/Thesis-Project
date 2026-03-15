//////////////////////////////////////////////////////////////////////////////////
// ECC Monitor - Monitors DUT and Collects Coverage
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_monitor_c extends uvm_monitor;

    `uvm_component_utils(ecc_monitor_c)

    virtual ecc_interface vif;

    // Analysis ports
    uvm_analysis_port #(ecc_transaction) enc_ap;  // Encoder output
    uvm_analysis_port #(ecc_transaction) dec_ap;  // Decoder output

    // Coverage
    ecc_transaction cov_txn;

    covergroup ecc_coverage;
        option.per_instance = 1;

        // Error type coverage
        error_type_cp: coverpoint cov_txn.error_type {
            bins no_error = {NO_ERROR};
            bins sbe      = {SBE};
            bins dbe      = {DBE};
            bins sse      = {SSE};
            bins dase     = {DASE};
        }

        // Error symbol position coverage
        error_symbol_0_cp: coverpoint cov_txn.error_symbol_0 {
            bins data_symbols[] = {[0:16]};
            bins parity_p0 = {17};
            bins parity_p1 = {18};
        }

        error_symbol_1_cp: coverpoint cov_txn.error_symbol_1 {
            bins data_symbols[] = {[0:16]};
            bins parity_p0 = {17};
            bins parity_p1 = {18};
        }

        // Bit position coverage for SBE
        sbe_bit_position_cp: coverpoint cov_txn.error_bit_pos_0 iff (cov_txn.error_type == SBE) {
            bins bit_pos[] = {[0:15]};
        }

        // Severity output coverage
        severity_cp: coverpoint cov_txn.expected_severity {
            bins ne  = {`SEV_NE};
            bins ces = {`SEV_CEs};
            bins ue  = {`SEV_UE};
            bins cem = {`SEV_CEm};
        }

        // Cross coverage: error type x symbol position
        error_type_x_symbol: cross error_type_cp, error_symbol_0_cp {
            ignore_bins no_err = binsof(error_type_cp.no_error);
        }

        // Cross coverage: DBE symbol pairs
        dbe_symbol_pairs: cross error_symbol_0_cp, error_symbol_1_cp iff (cov_txn.error_type == DBE);

        // Test mode coverage
        test_mode_cp: coverpoint cov_txn.test_mode {
            bins normal_mode = {0};
            bins test_mode   = {1};
        }

        // CW select coverage
        cw_sel_cp: coverpoint cov_txn.cw_sel iff (cov_txn.test_mode == 1) {
            bins cw0 = {0};
            bins cw1 = {1};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        enc_ap = new("enc_ap", this);
        dec_ap = new("dec_ap", this);
        ecc_coverage = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ecc_interface)::get(this, "", "ecc_vif", vif))
            `uvm_fatal("NO_VIF", {"Virtual interface not set for ", get_full_name(), ".ecc_vif"})
    endfunction

    task run_phase(uvm_phase phase);
        fork
            monitor_encoder();
            monitor_decoder();
        join
    endtask

    task monitor_encoder();
        ecc_transaction txn;
        forever begin
            @(posedge vif.clk);
            if (vif.mon_cb.enc_valid_out) begin
                txn = ecc_transaction::type_id::create("enc_txn");
                txn.codeword = vif.mon_cb.enc_codeword_out;
                txn.data = vif.mon_cb.enc_codeword_out[`CODEWORD_WIDTH-1:`CODEWORD_WIDTH-`DATA_WIDTH];
                enc_ap.write(txn);
                `uvm_info(get_type_name(), $sformatf("Encoder output captured: codeword=0x%h", txn.codeword), UVM_HIGH)
            end
        end
    endtask

    task monitor_decoder();
        ecc_transaction txn;
        forever begin
            @(posedge vif.clk);
            if (vif.mon_cb.rd_out_valid) begin
                txn = ecc_transaction::type_id::create("dec_txn");
                txn.data = vif.mon_cb.rd_data_out;
                txn.expected_severity = vif.mon_cb.sev_out;
                txn.expected_error_detected = vif.mon_cb.error_detected;
                txn.expected_error_corrected = vif.mon_cb.error_corrected;
                txn.expected_uncorrectable = vif.mon_cb.uncorrectable;

                // Sample coverage
                cov_txn = txn;
                ecc_coverage.sample();

                dec_ap.write(txn);
                `uvm_info(get_type_name(), $sformatf("Decoder output: data=0x%h, sev=%b, err_det=%b, err_corr=%b, uncorr=%b",
                    txn.data, txn.expected_severity, txn.expected_error_detected,
                    txn.expected_error_corrected, txn.expected_uncorrectable), UVM_HIGH)
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("ECC Coverage: %.2f%%", ecc_coverage.get_coverage()), UVM_NONE)
    endfunction

endclass
