//////////////////////////////////////////////////////////////////////////////////
// ECC Scoreboard - Reference Model Comparison
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

`uvm_analysis_imp_decl(_drv)
`uvm_analysis_imp_decl(_dec)

class ecc_scoreboard_c extends uvm_scoreboard;

    `uvm_component_utils(ecc_scoreboard_c)

    // Analysis imports
    uvm_analysis_imp_drv #(ecc_transaction, ecc_scoreboard_c) drv_export;
    uvm_analysis_imp_dec #(ecc_transaction, ecc_scoreboard_c) dec_export;

    // Transaction queues
    ecc_transaction drv_queue[$];

    // Statistics
    int unsigned total_transactions;
    int unsigned passed_transactions;
    int unsigned failed_transactions;
    int unsigned no_error_count;
    int unsigned sbe_count;
    int unsigned dbe_count;
    int unsigned sse_count;
    int unsigned dase_count;
    int unsigned uncorrectable_count;

    // T-values for reference model
    bit [15:0] T_VALUES[19] = '{
        `T0, `T1, `T2, `T3, `T4, `T5, `T6, `T7, `T8, `T9,
        `T10, `T11, `T12, `T13, `T14, `T15, `T16, `T17, `T18
    };

    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv_export = new("drv_export", this);
        dec_export = new("dec_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        total_transactions = 0;
        passed_transactions = 0;
        failed_transactions = 0;
        no_error_count = 0;
        sbe_count = 0;
        dbe_count = 0;
        sse_count = 0;
        dase_count = 0;
        uncorrectable_count = 0;
    endfunction

    // Receive transaction from driver
    function void write_drv(ecc_transaction txn);
        ecc_transaction txn_copy;
        txn_copy = new();
        txn_copy.copy(txn);
        txn_copy.compute_expected();
        drv_queue.push_back(txn_copy);
        `uvm_info(get_type_name(), $sformatf("Received driver txn: error_type=%s, data=0x%h",
            txn.error_type.name(), txn.data), UVM_HIGH)
    endfunction

    // Receive transaction from decoder monitor and compare
    function void write_dec(ecc_transaction dec_txn);
        ecc_transaction exp_txn;
        bit data_match, status_match;

        if (drv_queue.size() == 0) begin
            `uvm_error(get_type_name(), "Received decoder output but driver queue is empty!")
            return;
        end

        exp_txn = drv_queue.pop_front();
        total_transactions++;

        // Update error type statistics
        case (exp_txn.error_type)
            NO_ERROR: no_error_count++;
            SBE:      sbe_count++;
            DBE:      dbe_count++;
            SSE:      sse_count++;
            DASE:     dase_count++;
        endcase

        // Compare results
        if (exp_txn.expected_uncorrectable) begin
            // For uncorrectable errors, only check status flags
            status_match = (dec_txn.expected_error_detected == 1) &&
                           (dec_txn.expected_uncorrectable == 1);
            data_match = 1; // Don't check data for uncorrectable errors
            uncorrectable_count++;
        end else begin
            // For correctable errors, check data and status
            data_match = (dec_txn.data == exp_txn.expected_data);
            status_match = (dec_txn.expected_error_detected == exp_txn.expected_error_detected) &&
                           (dec_txn.expected_error_corrected == exp_txn.expected_error_corrected);
        end

        if (data_match && status_match) begin
            passed_transactions++;
            `uvm_info(get_type_name(), $sformatf("PASS [%0d]: error_type=%s, data_match=%b, status_match=%b",
                total_transactions, exp_txn.error_type.name(), data_match, status_match), UVM_MEDIUM)
        end else begin
            failed_transactions++;
            `uvm_error(get_type_name(), $sformatf(
                "FAIL [%0d]: error_type=%s\n  Expected: data=0x%h, err_det=%b, err_corr=%b, uncorr=%b\n  Actual:   data=0x%h, err_det=%b, err_corr=%b, uncorr=%b",
                total_transactions, exp_txn.error_type.name(),
                exp_txn.expected_data, exp_txn.expected_error_detected, exp_txn.expected_error_corrected, exp_txn.expected_uncorrectable,
                dec_txn.data, dec_txn.expected_error_detected, dec_txn.expected_error_corrected, dec_txn.expected_uncorrectable))
        end
    endfunction

    // GF(2^16) multiplication
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

    // Compute syndromes for reference
    function void compute_syndromes(bit [`CODEWORD_WIDTH-1:0] codeword, output bit [15:0] S0, output bit [15:0] S1);
        bit [15:0] symbols[19];

        // Extract symbols
        for (int i = 0; i < 19; i++)
            symbols[i] = codeword[(`CODEWORD_WIDTH - 1 - i*16) -: 16];

        // S0 = XOR of all symbols
        S0 = 0;
        for (int i = 0; i < 19; i++)
            S0 ^= symbols[i];

        // S1 = XOR of Ti*Ci
        S1 = 0;
        for (int i = 0; i < 19; i++)
            S1 ^= gf_mul(T_VALUES[i], symbols[i]);
    endfunction

    function void check_phase(uvm_phase phase);
        if (drv_queue.size() > 0)
            `uvm_error(get_type_name(), $sformatf("Driver queue not empty at end of test: %0d items remaining", drv_queue.size()))
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "========== ECC SCOREBOARD SUMMARY ==========", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Total Transactions: %0d", total_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Passed:             %0d", passed_transactions), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Failed:             %0d", failed_transactions), UVM_NONE)
        `uvm_info(get_type_name(), "---------- Error Type Breakdown ----------", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("No Error:           %0d", no_error_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("SBE:                %0d", sbe_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("DBE:                %0d", dbe_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("SSE:                %0d", sse_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("DASE:               %0d", dase_count), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Uncorrectable:      %0d", uncorrectable_count), UVM_NONE)
        `uvm_info(get_type_name(), "============================================", UVM_NONE)

        if (failed_transactions > 0)
            `uvm_error(get_type_name(), $sformatf("TEST FAILED: %0d transactions failed", failed_transactions))
        else
            `uvm_info(get_type_name(), "TEST PASSED: All transactions matched", UVM_NONE)
    endfunction

endclass
