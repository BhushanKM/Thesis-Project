///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Parity Symbol Error Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests errors specifically in parity symbols P0 (17) and P1 (18)
///////////////////////////////////////////////////////////////////////////

class ecc_parity_error_test extends ecc_base_test;

    `uvm_component_utils(ecc_parity_error_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_parity_error_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Parity Symbol Error Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_parity_error_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_parity_error_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_parity_error_seq)

    function new(string name = "ecc_parity_error_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Testing errors in parity symbols P0 and P1", UVM_MEDIUM)

        // SBE in P0 (symbol 17) - all 16 bit positions
        `uvm_info(get_type_name(), "Testing SBE in P0 (symbol 17)", UVM_MEDIUM)
        for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == 17;
                error_pattern_0 == (16'h1 << bit_pos);
            })
        end

        // SBE in P1 (symbol 18) - all 16 bit positions
        `uvm_info(get_type_name(), "Testing SBE in P1 (symbol 18)", UVM_MEDIUM)
        for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == 18;
                error_pattern_0 == (16'h1 << bit_pos);
            })
        end

        // DBE: one in data, one in P0
        `uvm_info(get_type_name(), "Testing DBE: data + P0", UVM_MEDIUM)
        for (int data_sym = 0; data_sym < 17; data_sym++) begin
            `uvm_do_with(req, {
                error_type == DBE;
                error_symbol_0 == data_sym;
                error_symbol_1 == 17;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        // DBE: one in data, one in P1
        `uvm_info(get_type_name(), "Testing DBE: data + P1", UVM_MEDIUM)
        for (int data_sym = 0; data_sym < 17; data_sym++) begin
            `uvm_do_with(req, {
                error_type == DBE;
                error_symbol_0 == data_sym;
                error_symbol_1 == 18;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        // DBE: one in P0, one in P1
        `uvm_info(get_type_name(), "Testing DBE: P0 + P1", UVM_MEDIUM)
        repeat(16) begin
            `uvm_do_with(req, {
                error_type == DBE;
                error_symbol_0 == 17;
                error_symbol_1 == 18;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        // SSE in P0
        `uvm_info(get_type_name(), "Testing SSE in P0", UVM_MEDIUM)
        repeat(20) begin
            `uvm_do_with(req, {
                error_type == SSE;
                error_symbol_0 == 17;
                $countones(error_pattern_0) inside {[2:16]};
            })
        end

        // SSE in P1
        `uvm_info(get_type_name(), "Testing SSE in P1", UVM_MEDIUM)
        repeat(20) begin
            `uvm_do_with(req, {
                error_type == SSE;
                error_symbol_0 == 18;
                $countones(error_pattern_0) inside {[2:16]};
            })
        end

        // DASE: D16 + P0 (adjacent)
        `uvm_info(get_type_name(), "Testing DASE: D16 + P0", UVM_MEDIUM)
        repeat(10) begin
            `uvm_do_with(req, {
                error_type == DASE;
                error_symbol_0 == 16;
                error_symbol_1 == 17;
                $countones(error_pattern_0) >= 1;
                $countones(error_pattern_1) >= 1;
            })
        end

        // DASE: P0 + P1 (adjacent)
        `uvm_info(get_type_name(), "Testing DASE: P0 + P1", UVM_MEDIUM)
        repeat(10) begin
            `uvm_do_with(req, {
                error_type == DASE;
                error_symbol_0 == 17;
                error_symbol_1 == 18;
                $countones(error_pattern_0) >= 1;
                $countones(error_pattern_1) >= 1;
            })
        end

        `uvm_info(get_type_name(), "Parity error test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_parity_error_seq
