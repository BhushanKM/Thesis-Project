///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Full Regression Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Complete regression suite with exhaustive coverage
///////////////////////////////////////////////////////////////////////////

class ecc_regression_test extends ecc_base_test;

    `uvm_component_utils(ecc_regression_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_regression_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Full Regression Test Suite", UVM_NONE)
    endtask : run_phase

endclass : ecc_regression_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_regression_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_regression_seq)

    function new(string name = "ecc_regression_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "========== FULL REGRESSION SUITE ==========", UVM_MEDIUM)

        //----------------------------------------------------------------------
        // PART 1: Exhaustive SBE (304 positions)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 1: Exhaustive SBE (304 positions)", UVM_MEDIUM)
        for (int sym = 0; sym < 19; sym++) begin
            for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
                `uvm_do_with(req, {
                    error_type == SBE;
                    error_symbol_0 == sym;
                    error_pattern_0 == (16'h1 << bit_pos);
                })
            end
        end

        //----------------------------------------------------------------------
        // PART 2: Extended DBE (1000 transactions)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 2: Extended DBE (1000 transactions)", UVM_MEDIUM)
        repeat(1000) begin
            `uvm_do_with(req, {
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
                error_symbol_0 != error_symbol_1;
            })
        end

        //----------------------------------------------------------------------
        // PART 3: Extended SSE (1000 transactions)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 3: Extended SSE (1000 transactions)", UVM_MEDIUM)
        repeat(1000) begin
            `uvm_do_with(req, {
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:16]};
            })
        end

        //----------------------------------------------------------------------
        // PART 4: DASE Detection (all adjacent pairs)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 4: DASE Detection (all adjacent pairs)", UVM_MEDIUM)
        for (int i = 0; i < 18; i++) begin
            repeat(5) begin
                `uvm_do_with(req, {
                    error_type == DASE;
                    error_symbol_0 == i;
                    error_symbol_1 == i + 1;
                    $countones(error_pattern_0) >= 1;
                    $countones(error_pattern_1) >= 1;
                })
            end
        end

        //----------------------------------------------------------------------
        // PART 5: Boundary Patterns
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 5: Boundary patterns", UVM_MEDIUM)

        // Special data patterns with no errors
        `uvm_do_with(req, { error_type == NO_ERROR; data == '0; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == '1; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'h5555}}; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'hAAAA}}; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'hFF00}}; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'h00FF}}; })

        // Boundary patterns with errors
        for (int sym = 0; sym < 19; sym++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                data == '0;
                error_symbol_0 == sym;
                error_pattern_0 == 16'h0001;
            })
            `uvm_do_with(req, {
                error_type == SBE;
                data == '1;
                error_symbol_0 == sym;
                error_pattern_0 == 16'h8000;
            })
        end

        //----------------------------------------------------------------------
        // PART 6: Parity Symbol Coverage
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 6: Parity symbol coverage", UVM_MEDIUM)

        // All bit positions in P0 and P1
        for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == 17;
                error_pattern_0 == (16'h1 << bit_pos);
            })
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == 18;
                error_pattern_0 == (16'h1 << bit_pos);
            })
        end

        // DBE with parity symbols
        for (int data_sym = 0; data_sym < 17; data_sym++) begin
            `uvm_do_with(req, {
                error_type == DBE;
                error_symbol_0 == data_sym;
                error_symbol_1 == 17;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
            `uvm_do_with(req, {
                error_type == DBE;
                error_symbol_0 == data_sym;
                error_symbol_1 == 18;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        //----------------------------------------------------------------------
        // PART 7: Stress Test (5000 back-to-back)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 7: Stress test (5000 transactions)", UVM_MEDIUM)
        repeat(5000) begin
            `uvm_do_with(req, {
                delay == 0;
                error_type dist {
                    NO_ERROR := 10,
                    SBE      := 40,
                    DBE      := 30,
                    SSE      := 20
                };
            })
        end

        //----------------------------------------------------------------------
        // PART 8: Test Mode (CW0/CW1)
        //----------------------------------------------------------------------
        `uvm_info(get_type_name(), "REGRESSION PART 8: Test mode CW0/CW1", UVM_MEDIUM)

        // CW0 mode
        repeat(50) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 0;
                error_type dist { SBE := 50, DBE := 30, SSE := 20 };
            })
        end

        // CW1 mode
        repeat(50) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 1;
                error_type dist { SBE := 50, DBE := 30, SSE := 20 };
            })
        end

        `uvm_info(get_type_name(), "========== REGRESSION COMPLETE ==========", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Total: ~8500+ transactions executed", UVM_MEDIUM)
    endtask : body

endclass : ecc_regression_seq
