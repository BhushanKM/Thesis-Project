//////////////////////////////////////////////////////////////////////////////////
// ECC Sequences - Error Injection Sequences
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Base Sequence
//==============================================================================
class ecc_base_seq extends uvm_sequence #(ecc_transaction);

    `uvm_object_utils(ecc_base_seq)

    function new(string name = "ecc_base_seq");
        super.new(name);
    endfunction

    task pre_body();
        if (starting_phase != null)
            starting_phase.raise_objection(this, get_type_name());
    endtask

    task post_body();
        if (starting_phase != null)
            starting_phase.drop_objection(this, get_type_name());
    endtask

endclass

//==============================================================================
// No Error Sequence - Basic functionality test
//==============================================================================
class no_error_seq extends ecc_base_seq;

    `uvm_object_utils(no_error_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[10:50]}; }

    function new(string name = "no_error_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d no-error transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                error_type == NO_ERROR;
            })
        end
    endtask

endclass

//==============================================================================
// SBE Sequence - Single Bit Error in all positions
//==============================================================================
class sbe_seq extends ecc_base_seq;

    `uvm_object_utils(sbe_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[100:500]}; }

    function new(string name = "sbe_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d SBE transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                error_type == SBE;
                $countones(error_pattern_0) == 1;
            })
        end
    endtask

endclass

//==============================================================================
// SBE Exhaustive Sequence - All 304 bit positions
//==============================================================================
class sbe_exhaustive_seq extends ecc_base_seq;

    `uvm_object_utils(sbe_exhaustive_seq)

    function new(string name = "sbe_exhaustive_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "Running exhaustive SBE test (304 bit positions)", UVM_MEDIUM)

        // Test all 19 symbols × 16 bits = 304 positions
        for (int sym = 0; sym < 19; sym++) begin
            for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
                `uvm_do_with(req, {
                    error_type == SBE;
                    error_symbol_0 == sym;
                    error_pattern_0 == (16'h1 << bit_pos);
                })
            end
        end
    endtask

endclass

//==============================================================================
// DBE Sequence - Double Bit Errors in different symbols
//==============================================================================
class dbe_seq extends ecc_base_seq;

    `uvm_object_utils(dbe_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[100:500]}; }

    function new(string name = "dbe_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d DBE transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
                error_symbol_0 != error_symbol_1;
            })
        end
    endtask

endclass

//==============================================================================
// SSE Sequence - Single Symbol Error (multi-bit within symbol)
//==============================================================================
class sse_seq extends ecc_base_seq;

    `uvm_object_utils(sse_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[100:500]}; }

    function new(string name = "sse_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d SSE transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:16]};
            })
        end
    endtask

endclass

//==============================================================================
// DASE Sequence - Double Adjacent Symbol Error (uncorrectable)
//==============================================================================
class dase_seq extends ecc_base_seq;

    `uvm_object_utils(dase_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[20:100]}; }

    function new(string name = "dase_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d DASE transactions (uncorrectable)", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                error_type == DASE;
                (error_symbol_1 == error_symbol_0 + 1) ||
                (error_symbol_0 == error_symbol_1 + 1);
                error_symbol_0 < 18;
                error_symbol_1 < 19;
            })
        end
    endtask

endclass

//==============================================================================
// Boundary Patterns Sequence
//==============================================================================
class boundary_seq extends ecc_base_seq;

    `uvm_object_utils(boundary_seq)

    function new(string name = "boundary_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "Running boundary pattern tests", UVM_MEDIUM)

        // All zeros
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == '0;
        })

        // All ones
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == '1;
        })

        // Alternating 0x5555
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == {17{16'h5555}};
        })

        // Alternating 0xAAAA
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == {17{16'hAAAA}};
        })

        // Walking ones in each symbol
        for (int sym = 0; sym < 17; sym++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == sym;
                error_pattern_0 == 16'h0001;
            })
        end

        // Errors in parity symbols
        `uvm_do_with(req, {
            error_type == SBE;
            error_symbol_0 == 17;  // P0
            error_pattern_0 == 16'h0001;
        })

        `uvm_do_with(req, {
            error_type == SBE;
            error_symbol_0 == 18;  // P1
            error_pattern_0 == 16'h0001;
        })
    endtask

endclass

//==============================================================================
// Mixed Error Sequence - Comprehensive test
//==============================================================================
class mixed_error_seq extends ecc_base_seq;

    `uvm_object_utils(mixed_error_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[200:1000]}; }

    function new(string name = "mixed_error_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d mixed error transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
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
    endtask

endclass

//==============================================================================
// Stress Sequence - Back-to-back transactions
//==============================================================================
class stress_seq extends ecc_base_seq;

    `uvm_object_utils(stress_seq)

    rand int num_transactions;

    constraint c_num_trans { num_transactions inside {[500:2000]}; }

    function new(string name = "stress_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("Running %0d stress test transactions", num_transactions), UVM_MEDIUM)
        repeat(num_transactions) begin
            `uvm_do_with(req, {
                delay == 0;  // No delay between transactions
                error_type dist {
                    NO_ERROR := 10,
                    SBE      := 40,
                    DBE      := 30,
                    SSE      := 20
                };
            })
        end
    endtask

endclass

//==============================================================================
// Test Mode Sequence
//==============================================================================
class test_mode_seq extends ecc_base_seq;

    `uvm_object_utils(test_mode_seq)

    function new(string name = "test_mode_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "Running test mode sequence", UVM_MEDIUM)

        // CW0 mode tests
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 0;
                error_type == SBE;
            })
        end

        // CW1 mode tests
        repeat(20) begin
            `uvm_do_with(req, {
                test_mode == 1;
                cw_sel == 1;
                error_type == SBE;
            })
        end
    endtask

endclass
