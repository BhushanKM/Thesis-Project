//////////////////////////////////////////////////////////////////////////////////
// ECC Transaction - Sequence Item with Error Injection Fields
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_transaction extends uvm_sequence_item;

    // Data fields
    rand bit [`DATA_WIDTH-1:0]     data;
    rand bit [`CODEWORD_WIDTH-1:0] codeword;

    // Error injection fields
    rand error_type_e error_type;
    rand bit [4:0]    error_symbol_0;    // 0-16 for data, 17-18 for parity
    rand bit [4:0]    error_symbol_1;    // Second symbol for DBE
    rand bit [15:0]   error_pattern_0;   // Error pattern for first symbol
    rand bit [15:0]   error_pattern_1;   // Error pattern for second symbol
    rand bit [3:0]    error_bit_pos_0;   // Bit position for SBE
    rand bit [3:0]    error_bit_pos_1;   // Bit position for second SBE in DBE

    // Control fields
    rand bit          test_mode;
    rand bit          cw_sel;
    rand int unsigned delay;

    // Expected outputs (for scoreboard)
    bit [`DATA_WIDTH-1:0] expected_data;
    bit [1:0]             expected_severity;
    bit                   expected_error_detected;
    bit                   expected_error_corrected;
    bit                   expected_uncorrectable;

    // UVM macros
    `uvm_object_utils_begin(ecc_transaction)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(codeword, UVM_ALL_ON)
        `uvm_field_enum(error_type_e, error_type, UVM_ALL_ON)
        `uvm_field_int(error_symbol_0, UVM_ALL_ON)
        `uvm_field_int(error_symbol_1, UVM_ALL_ON)
        `uvm_field_int(error_pattern_0, UVM_ALL_ON)
        `uvm_field_int(error_pattern_1, UVM_ALL_ON)
        `uvm_field_int(error_bit_pos_0, UVM_ALL_ON)
        `uvm_field_int(error_bit_pos_1, UVM_ALL_ON)
        `uvm_field_int(test_mode, UVM_ALL_ON)
        `uvm_field_int(cw_sel, UVM_ALL_ON)
        `uvm_field_int(delay, UVM_ALL_ON)
        `uvm_field_int(expected_data, UVM_ALL_ON)
        `uvm_field_int(expected_severity, UVM_ALL_ON)
        `uvm_field_int(expected_error_detected, UVM_ALL_ON)
        `uvm_field_int(expected_error_corrected, UVM_ALL_ON)
        `uvm_field_int(expected_uncorrectable, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "ecc_transaction");
        super.new(name);
    endfunction

    // Constraints
    constraint c_valid_symbols {
        error_symbol_0 inside {[0:18]};
        error_symbol_1 inside {[0:18]};
        error_symbol_0 != error_symbol_1;
    }

    constraint c_delay {
        delay inside {[0:10]};
    }

    constraint c_test_mode_default {
        soft test_mode == 0;
    }

    constraint c_cw_sel_default {
        soft cw_sel == 0;
    }

    // SBE constraint: single bit in single symbol
    constraint c_sbe {
        error_type == SBE -> {
            $countones(error_pattern_0) == 1;
            error_pattern_1 == 0;
        }
    }

    // DBE constraint: single bit in each of two different symbols
    constraint c_dbe {
        error_type == DBE -> {
            $countones(error_pattern_0) == 1;
            $countones(error_pattern_1) == 1;
            error_symbol_0 != error_symbol_1;
        }
    }

    // SSE constraint: multiple bits in single symbol (2-16 bits)
    constraint c_sse {
        error_type == SSE -> {
            $countones(error_pattern_0) inside {[2:16]};
            error_pattern_1 == 0;
        }
    }

    // DASE constraint: errors in two adjacent symbols
    constraint c_dase {
        error_type == DASE -> {
            (error_symbol_1 == error_symbol_0 + 1) ||
            (error_symbol_0 == error_symbol_1 + 1);
            $countones(error_pattern_0) >= 1;
            $countones(error_pattern_1) >= 1;
        }
    }

    // No error constraint
    constraint c_no_error {
        error_type == NO_ERROR -> {
            error_pattern_0 == 0;
            error_pattern_1 == 0;
        }
    }

    // Convert bit position to one-hot pattern
    function bit [15:0] bit_to_pattern(bit [3:0] pos);
        return 16'h1 << pos;
    endfunction

    // Apply error to codeword
    function bit [`CODEWORD_WIDTH-1:0] inject_error(bit [`CODEWORD_WIDTH-1:0] clean_cw);
        bit [`CODEWORD_WIDTH-1:0] corrupted_cw;
        int sym0_start, sym1_start;

        corrupted_cw = clean_cw;

        if (error_type == NO_ERROR)
            return corrupted_cw;

        // Calculate symbol positions (MSB first: symbol 0 at bits 303:288)
        sym0_start = (`NUM_TOTAL_SYMBOLS - 1 - error_symbol_0) * `SYMBOL_WIDTH;

        case (error_type)
            SBE: begin
                corrupted_cw[sym0_start +: 16] ^= error_pattern_0;
            end
            DBE: begin
                sym1_start = (`NUM_TOTAL_SYMBOLS - 1 - error_symbol_1) * `SYMBOL_WIDTH;
                corrupted_cw[sym0_start +: 16] ^= error_pattern_0;
                corrupted_cw[sym1_start +: 16] ^= error_pattern_1;
            end
            SSE: begin
                corrupted_cw[sym0_start +: 16] ^= error_pattern_0;
            end
            DASE: begin
                sym1_start = (`NUM_TOTAL_SYMBOLS - 1 - error_symbol_1) * `SYMBOL_WIDTH;
                corrupted_cw[sym0_start +: 16] ^= error_pattern_0;
                corrupted_cw[sym1_start +: 16] ^= error_pattern_1;
            end
            RANDOM: begin
                corrupted_cw[sym0_start +: 16] ^= error_pattern_0;
                if (error_pattern_1 != 0) begin
                    sym1_start = (`NUM_TOTAL_SYMBOLS - 1 - error_symbol_1) * `SYMBOL_WIDTH;
                    corrupted_cw[sym1_start +: 16] ^= error_pattern_1;
                end
            end
        endcase

        return corrupted_cw;
    endfunction

    // Compute expected outputs based on error type
    function void compute_expected();
        case (error_type)
            NO_ERROR: begin
                expected_data = data;
                expected_severity = `SEV_NE;
                expected_error_detected = 0;
                expected_error_corrected = 0;
                expected_uncorrectable = 0;
            end
            SBE: begin
                expected_data = data;
                expected_severity = `SEV_CEs;
                expected_error_detected = 1;
                expected_error_corrected = 1;
                expected_uncorrectable = 0;
            end
            DBE: begin
                expected_data = data;
                expected_severity = `SEV_CEm;
                expected_error_detected = 1;
                expected_error_corrected = 1;
                expected_uncorrectable = 0;
            end
            SSE: begin
                expected_data = data;
                expected_severity = `SEV_CEm;
                expected_error_detected = 1;
                expected_error_corrected = 1;
                expected_uncorrectable = 0;
            end
            DASE: begin
                // DASE is detectable but not correctable
                expected_severity = `SEV_UE;
                expected_error_detected = 1;
                expected_error_corrected = 0;
                expected_uncorrectable = 1;
            end
            default: begin
                expected_error_detected = 1;
                expected_uncorrectable = 1;
            end
        endcase
    endfunction

endclass
