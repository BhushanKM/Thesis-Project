// =============================================================================
//
//  Module      : ecc_decoder_top
//  Description : Top-level wrapper for the ECC decoder subsystem.
//
//  Accepts a 304-bit codeword (19 × 16-bit GF(2^16) symbols) and produces
//  corrected 272-bit data (17 data symbols) plus status flags.
//
//  Internal pipeline:
//    1. ecc_symbol_extract   — slice codeword into 19 symbols      (comb)
//    2. ecc_syndrome_gen     — compute S0 and S1                   (1 cycle)
//    3. ecc_error_locator    — classify & locate DBE-w2/w1/w0      (comb)
//    4. ecc_decision_logic   — priority arbitration, status flags   (comb)
//    5. ecc_error_corrector  — XOR correction for all three modes   (comb)
//    6. Output registers     — capture corrected data & status      (1 cycle)
//
//  Total latency: 2 clock cycles (syndrome register + output register).
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_decoder_top (
    input  wire         clk,
    input  wire         rst_n,

    // Read interface
    input  wire         rd_valid,
    input  wire [303:0] rd_codeword,

    // Corrected data output
    output reg          rd_out_valid,
    output reg  [271:0] rd_data_out,

    // Status flags
    output reg          error_detected,
    output reg          error_corrected,
    output reg          multi_bit_error,
    output reg          uncorrectable
);

    // =========================================================================
    //  Stage 1: Symbol Extraction (combinational)
    // =========================================================================

    wire [15:0] C0,  C1,  C2,  C3,  C4,  C5,  C6,  C7,  C8,  C9;
    wire [15:0] C10, C11, C12, C13, C14, C15, C16, C17, C18;

    ecc_symbol_extract u_symbol_extract (
        .codeword_in (rd_codeword),
        .C0  (C0),  .C1  (C1),  .C2  (C2),  .C3  (C3),  .C4  (C4),
        .C5  (C5),  .C6  (C6),  .C7  (C7),  .C8  (C8),  .C9  (C9),
        .C10 (C10), .C11 (C11), .C12 (C12), .C13 (C13), .C14 (C14),
        .C15 (C15), .C16 (C16), .C17 (C17), .C18 (C18)
    );

    // =========================================================================
    //  Stage 2: Syndrome Generation (1-cycle registered latency)
    // =========================================================================

    wire [15:0] S0, S1;
    wire        synd_valid;

    ecc_syndrome_gen u_syndrome_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (rd_valid),
        .C0  (C0),  .C1  (C1),  .C2  (C2),  .C3  (C3),  .C4  (C4),
        .C5  (C5),  .C6  (C6),  .C7  (C7),  .C8  (C8),  .C9  (C9),
        .C10 (C10), .C11 (C11), .C12 (C12), .C13 (C13), .C14 (C14),
        .C15 (C15), .C16 (C16), .P0  (C17), .P1  (C18),
        .valid_out (synd_valid),
        .S0        (S0),
        .S1        (S1)
    );

    // =========================================================================
    //  Delay codeword symbols by 1 cycle to align with registered syndromes
    // =========================================================================

    reg [15:0] C0r,  C1r,  C2r,  C3r,  C4r,  C5r,  C6r,  C7r,  C8r,  C9r;
    reg [15:0] C10r, C11r, C12r, C13r, C14r, C15r, C16r, C17r, C18r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            C0r  <= 16'd0; C1r  <= 16'd0; C2r  <= 16'd0; C3r  <= 16'd0;
            C4r  <= 16'd0; C5r  <= 16'd0; C6r  <= 16'd0; C7r  <= 16'd0;
            C8r  <= 16'd0; C9r  <= 16'd0; C10r <= 16'd0; C11r <= 16'd0;
            C12r <= 16'd0; C13r <= 16'd0; C14r <= 16'd0; C15r <= 16'd0;
            C16r <= 16'd0; C17r <= 16'd0; C18r <= 16'd0;
        end
        else if (rd_valid) begin
            C0r  <= C0;  C1r  <= C1;  C2r  <= C2;  C3r  <= C3;
            C4r  <= C4;  C5r  <= C5;  C6r  <= C6;  C7r  <= C7;
            C8r  <= C8;  C9r  <= C9;  C10r <= C10; C11r <= C11;
            C12r <= C12; C13r <= C13; C14r <= C14; C15r <= C15;
            C16r <= C16; C17r <= C17; C18r <= C18;
        end
    end

    // =========================================================================
    //  Stage 3: Error Locator (combinational)
    // =========================================================================

    wire        loc_valid;
    wire        no_error;

    wire        dbe_w2_found;
    wire [4:0]  dbe_w2_loc0, dbe_w2_loc1;
    wire [15:0] dbe_w2_err0, dbe_w2_err1;

    wire        dbe_w1_found;
    wire [4:0]  dbe_w1_loc0;
    wire [15:0] dbe_w1_err0, dbe_w1_err1;

    wire        dbe_w0_found;
    wire [4:0]  dbe_w0_loc0, dbe_w0_loc1;
    wire [15:0] dbe_w0_err;

    ecc_error_locator u_error_locator (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (synd_valid),
        .S0           (S0),
        .S1           (S1),
        .valid_out    (loc_valid),
        .no_error     (no_error),
        .dbe_w2_found (dbe_w2_found),
        .dbe_w2_loc0  (dbe_w2_loc0),
        .dbe_w2_loc1  (dbe_w2_loc1),
        .dbe_w2_err0  (dbe_w2_err0),
        .dbe_w2_err1  (dbe_w2_err1),
        .dbe_w1_found (dbe_w1_found),
        .dbe_w1_loc0  (dbe_w1_loc0),
        .dbe_w1_err0  (dbe_w1_err0),
        .dbe_w1_err1  (dbe_w1_err1),
        .dbe_w0_found (dbe_w0_found),
        .dbe_w0_loc0  (dbe_w0_loc0),
        .dbe_w0_loc1  (dbe_w0_loc1),
        .dbe_w0_err   (dbe_w0_err)
    );

    // =========================================================================
    //  Stage 4: Decision Logic (combinational)
    // =========================================================================

    wire use_dbe_w2, use_dbe_w1, use_dbe_w0;
    wire dec_error_detected;
    wire dec_error_corrected;
    wire dec_multi_bit_error;
    wire dec_uncorrectable;

    ecc_decision_logic u_decision_logic (
        .no_error        (no_error),
        .dbe_w2_found    (dbe_w2_found),
        .dbe_w1_found    (dbe_w1_found),
        .dbe_w0_found    (dbe_w0_found),
        .use_dbe_w2      (use_dbe_w2),
        .use_dbe_w1      (use_dbe_w1),
        .use_dbe_w0      (use_dbe_w0),
        .error_detected  (dec_error_detected),
        .error_corrected (dec_error_corrected),
        .multi_bit_error (dec_multi_bit_error),
        .uncorrectable   (dec_uncorrectable)
    );

    // =========================================================================
    //  Stage 5: Error Corrector (combinational, uses aligned C0r..C18r)
    // =========================================================================

    wire [271:0] corrected_data;

    ecc_error_corrector u_error_corrector (
        .C0  (C0r),  .C1  (C1r),  .C2  (C2r),  .C3  (C3r),  .C4  (C4r),
        .C5  (C5r),  .C6  (C6r),  .C7  (C7r),  .C8  (C8r),  .C9  (C9r),
        .C10 (C10r), .C11 (C11r), .C12 (C12r), .C13 (C13r), .C14 (C14r),
        .C15 (C15r), .C16 (C16r), .C17 (C17r), .C18 (C18r),
        .use_dbe_w2   (use_dbe_w2),
        .dbe_w2_loc0  (dbe_w2_loc0),
        .dbe_w2_loc1  (dbe_w2_loc1),
        .dbe_w2_err0  (dbe_w2_err0),
        .dbe_w2_err1  (dbe_w2_err1),
        .use_dbe_w1   (use_dbe_w1),
        .dbe_w1_loc0  (dbe_w1_loc0),
        .dbe_w1_err0  (dbe_w1_err0),
        .dbe_w1_err1  (dbe_w1_err1),
        .use_dbe_w0   (use_dbe_w0),
        .dbe_w0_loc0  (dbe_w0_loc0),
        .dbe_w0_loc1  (dbe_w0_loc1),
        .dbe_w0_err   (dbe_w0_err),
        .data_out     (corrected_data)
    );

    // =========================================================================
    //  Stage 6: Output Registers (1-cycle capture)
    // =========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_out_valid    <= 1'b0;
            rd_data_out     <= 272'd0;
            error_detected  <= 1'b0;
            error_corrected <= 1'b0;
            multi_bit_error <= 1'b0;
            uncorrectable   <= 1'b0;
        end
        else begin
            rd_out_valid <= loc_valid;
            if (loc_valid) begin
                rd_data_out     <= corrected_data;
                error_detected  <= dec_error_detected;
                error_corrected <= dec_error_corrected;
                multi_bit_error <= dec_multi_bit_error;
                uncorrectable   <= dec_uncorrectable;
            end
        end
    end

endmodule
