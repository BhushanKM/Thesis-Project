///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Comprehensive Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests all error types in a single comprehensive run
///////////////////////////////////////////////////////////////////////////

class ecc_comprehensive_test extends ecc_base_test;

    `uvm_component_utils(ecc_comprehensive_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_comprehensive_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Comprehensive Test - All Error Types", UVM_NONE)
    endtask : run_phase

endclass : ecc_comprehensive_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_comprehensive_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_comprehensive_seq)

    function new(string name = "ecc_comprehensive_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Starting comprehensive error type coverage", UVM_MEDIUM)

        // Phase 1: No-error baseline (50 transactions)
        `uvm_info(get_type_name(), "Phase 1: No-error baseline", UVM_MEDIUM)
        repeat(50) begin
            `uvm_do_with(req, {
                error_type == NO_ERROR;
            })
        end

        // Phase 2: SBE tests (200 transactions)
        `uvm_info(get_type_name(), "Phase 2: SBE coverage", UVM_MEDIUM)
        repeat(200) begin
            `uvm_do_with(req, {
                error_type == SBE;
                $countones(error_pattern_0) == 1;
            })
        end

        // Phase 3: DBE tests (200 transactions)
        `uvm_info(get_type_name(), "Phase 3: DBE coverage", UVM_MEDIUM)
        repeat(200) begin
            `uvm_do_with(req, {
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
                error_symbol_0 != error_symbol_1;
            })
        end

        // Phase 4: SSE tests (200 transactions)
        `uvm_info(get_type_name(), "Phase 4: SSE coverage", UVM_MEDIUM)
        repeat(200) begin
            `uvm_do_with(req, {
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:16]};
            })
        end

        // Phase 5: DASE tests (50 transactions - uncorrectable)
        `uvm_info(get_type_name(), "Phase 5: DASE detection (uncorrectable)", UVM_MEDIUM)
        repeat(50) begin
            `uvm_do_with(req, {
                error_type == DASE;
                (error_symbol_1 == error_symbol_0 + 1) ||
                (error_symbol_0 == error_symbol_1 + 1);
                error_symbol_0 < 18;
                error_symbol_1 < 19;
            })
        end

        // Phase 6: Boundary patterns
        `uvm_info(get_type_name(), "Phase 6: Boundary patterns", UVM_MEDIUM)
        // All zeros
        `uvm_do_with(req, { error_type == NO_ERROR; data == '0; })
        // All ones
        `uvm_do_with(req, { error_type == NO_ERROR; data == '1; })
        // Alternating
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'h5555}}; })
        `uvm_do_with(req, { error_type == NO_ERROR; data == {17{16'hAAAA}}; })

        // Phase 7: Parity symbol errors
        `uvm_info(get_type_name(), "Phase 7: Parity symbol errors", UVM_MEDIUM)
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

        // Phase 8: Mixed random (500 transactions)
        `uvm_info(get_type_name(), "Phase 8: Mixed random coverage", UVM_MEDIUM)
        repeat(500) begin
            `uvm_do_with(req, {
                error_type dist {
                    NO_ERROR := 20,
                    SBE      := 30,
                    DBE      := 25,
                    SSE      := 20,
                    DASE     := 5
                };
            })
        end

        `uvm_info(get_type_name(), "Comprehensive test complete - ~1250 transactions", UVM_MEDIUM)
    endtask : body

endclass : ecc_comprehensive_seq
