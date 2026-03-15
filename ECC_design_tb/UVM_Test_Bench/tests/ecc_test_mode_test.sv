///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - JEDEC Test Mode Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests JEDEC HBM4 test mode (MR9 OP2/OP3) with CW0/CW1 patterns
///////////////////////////////////////////////////////////////////////////

class ecc_test_mode_test extends ecc_base_test;

    `uvm_component_utils(ecc_test_mode_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_test_mode_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting JEDEC Test Mode Test (CW0/CW1)", UVM_NONE)
    endtask : run_phase

endclass : ecc_test_mode_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_test_mode_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_test_mode_seq)

    function new(string name = "ecc_test_mode_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Testing JEDEC HBM4 ECC test mode", UVM_MEDIUM)

        // CW0 mode: '1' = error bit, '0' = non-error bit
        `uvm_info(get_type_name(), "Testing CW0 mode (1=error)", UVM_MEDIUM)

        // CW0 with SBE
        repeat(30) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 0;
                error_type == SBE;
                $countones(error_pattern_0) == 1;
            })
        end

        // CW0 with DBE
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 0;
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        // CW0 with SSE
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 0;
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:8]};
            })
        end

        // CW1 mode: '0' = error bit, '1' = non-error bit
        `uvm_info(get_type_name(), "Testing CW1 mode (0=error)", UVM_MEDIUM)

        // CW1 with SBE
        repeat(30) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 1;
                error_type == SBE;
                $countones(error_pattern_0) == 1;
            })
        end

        // CW1 with DBE
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 1;
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
            })
        end

        // CW1 with SSE
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 1;
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:8]};
            })
        end

        // Mixed CW0/CW1 with all error types
        `uvm_info(get_type_name(), "Testing mixed CW0/CW1 patterns", UVM_MEDIUM)
        repeat(50) begin
            `uvm_do_with(req, {
                test_mode == 1;
                error_type dist {
                    SBE := 40,
                    DBE := 30,
                    SSE := 30
                };
            })
        end

        `uvm_info(get_type_name(), "Test mode test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_test_mode_seq
