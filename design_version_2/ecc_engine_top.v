`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Bhushan Kiran Munoli
//
// Create Date: 2026
// Design Name: ECC Engine Top with Test Mode
// Module Name: ecc_engine_top
// Project Name: ECC implementation for HBM4
//
// Description:
//   Top-level ECC engine with JEDEC HBM4 compliant test mode.
//   Uses fully connected split decoder architecture:
//
//   1. ecc_symbol_extract    - slice codeword into 19 GF symbols
//   2. ecc_syndrome_gen      - compute S0 and S1 (1-cycle registered latency)
//   3. ecc_error_locator     - classify & locate SSE / DBE-w2 / DBE-w1 / DBE-w0
//   4. ecc_decision_logic    - priority arbitration, status flags
//   5. ecc_error_corrector   - XOR correction for all four modes
//
// Pipeline latency: 1 clock (dominated by GF registered multipliers in
//                   ecc_syndrome_gen; all other stages are combinational).
//
//////////////////////////////////////////////////////////////////////////////////

module ecc_engine_top (
    input  wire         clk,
    input  wire         rst_n,

    // Control signals
    input  wire         test_mode_en,
    input  wire         cw_sel,

    // Write path
    input  wire         wr_valid,
    input  wire [271:0] wr_data,
    output wire         wr_ready,

    // Read path
    input  wire         rd_valid,
    input  wire [303:0] rd_codeword,
    input  wire         burst_start,
    output reg          rd_out_valid,
    output reg  [271:0] rd_data_out,
    output wire [1:0]   sev_out,

    // Encoder output
    output wire         enc_valid_out,
    output wire [303:0] enc_codeword_out,

    // Status flags
    output reg          error_detected,
    output reg          error_corrected,
    output reg          uncorrectable
);

    //==========================================================================
    // INTERNAL SIGNALS
    //==========================================================================

    // Encoder path
    wire         enc_valid;
    wire [271:0] enc_data_in;
    wire [303:0] enc_codeword;

    // Test path
    reg  [303:0] test_codeword;
    wire [271:0] error_pattern;
    wire [303:0] injected_codeword;

    // Decoder input mux
    wire         dec_valid_in;
    wire [303:0] dec_codeword_in;

    //--------------------------------------------------------------------------
    // Symbol extraction outputs (C0..C18)
    //--------------------------------------------------------------------------
    wire [15:0] C0,  C1,  C2,  C3,  C4,  C5,  C6,  C7,  C8,  C9;
    wire [15:0] C10, C11, C12, C13, C14, C15, C16, C17, C18;

    //--------------------------------------------------------------------------
    // Syndrome outputs
    //--------------------------------------------------------------------------
    wire [15:0] S0, S1;
    wire        synd_valid_out;

    //--------------------------------------------------------------------------
    // Error locator outputs
    //--------------------------------------------------------------------------
    wire         loc_valid_out;
    wire         no_error;

    wire         dbe_w2_found;
    wire [4:0]   dbe_w2_loc0,  dbe_w2_loc1;
    wire [15:0]  dbe_w2_err0,  dbe_w2_err1;

    wire         dbe_w1_found;
    wire [4:0]   dbe_w1_loc0;
    wire [15:0]  dbe_w1_err0,  dbe_w1_err1;

    wire         dbe_w0_found;
    wire [4:0]   dbe_w0_loc0,  dbe_w0_loc1;
    wire [15:0]  dbe_w0_err;

    //--------------------------------------------------------------------------
    // Decision logic outputs
    //--------------------------------------------------------------------------
    wire         use_dbe_w2, use_dbe_w1, use_dbe_w0;
    wire         dec_error_detected;
    wire         dec_error_corrected;
    wire         dec_multi_bit_error;
    wire         dec_uncorrectable;

    //--------------------------------------------------------------------------
    // Corrector output
    //--------------------------------------------------------------------------
    wire [271:0] dec_data_out;

    //==========================================================================
    // CLOCK ENABLE SIGNALS
    //==========================================================================
    wire test_cw_clk_en    = test_mode_en & wr_valid;
    wire output_reg_clk_en = loc_valid_out;

    //==========================================================================
    // ERROR PATTERN CONVERSION (test mode)
    //==========================================================================
    assign error_pattern    = cw_sel ? ~wr_data : wr_data;
    assign injected_codeword = {error_pattern, 32'b0};

    //==========================================================================
    // ENCODER
    //==========================================================================
    assign enc_data_in = wr_data;
    assign enc_valid   = wr_valid & ~test_mode_en;

    ecc_encoder main_encoder (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (enc_valid),
        .data_in      (enc_data_in),
        .valid_out    (enc_valid_out),
        .codeword_out (enc_codeword)
    );

    assign enc_codeword_out = enc_codeword;
    assign wr_ready         = 1'b1;

    //==========================================================================
    // TEST MODE ERROR INJECTION
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                test_codeword <= 304'b0;
        else if (test_cw_clk_en)  test_codeword <= injected_codeword;
    end

    //==========================================================================
    // DECODER INPUT MUX
    //==========================================================================
    assign dec_valid_in    = rd_valid;
    assign dec_codeword_in = test_mode_en ? test_codeword : rd_codeword;

    //==========================================================================
    // 1. SYMBOL EXTRACTION
    //==========================================================================
    ecc_symbol_extract u_symbol_extract (
        .codeword_in (dec_codeword_in),
        .C0  (C0),  .C1  (C1),  .C2  (C2),  .C3  (C3),  .C4  (C4),
        .C5  (C5),  .C6  (C6),  .C7  (C7),  .C8  (C8),  .C9  (C9),
        .C10 (C10), .C11 (C11), .C12 (C12), .C13 (C13), .C14 (C14),
        .C15 (C15), .C16 (C16), .C17 (C17), .C18 (C18)
    );

    //==========================================================================
    // 2. SYNDROME GENERATION
    //    Adds 1-cycle latency; valid_out indicates when S0/S1 are stable.
    //==========================================================================
    ecc_syndrome_gen u_syndrome_gen (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (dec_valid_in),

        .C0  (C0),  .C1  (C1),  .C2  (C2),  .C3  (C3),  .C4  (C4),
        .C5  (C5),  .C6  (C6),  .C7  (C7),  .C8  (C8),  .C9  (C9),
        .C10 (C10), .C11 (C11), .C12 (C12), .C13 (C13), .C14 (C14),
        .C15 (C15), .C16 (C16), .P0  (C17), .P1  (C18),

        .valid_out (synd_valid_out),
        .S0        (S0),
        .S1        (S1)
    );

    //==========================================================================
    // 3. ERROR LOCATOR
    //    Fully combinational — no extra latency beyond synd_valid_out.
    //==========================================================================
    ecc_error_locator u_error_locator (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (synd_valid_out),

        .S0           (S0),
        .S1           (S1),

        .valid_out    (loc_valid_out),
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

    //==========================================================================
    // 4. DECISION LOGIC
    //==========================================================================
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

    //==========================================================================
    // 5. ERROR CORRECTOR
    //    NOTE: The codeword symbols used here are the PRE-syndrome symbols,
    //    which are combinationally valid before the syndrome stage completes.
    //    The locator outputs that drive correction are aligned 1 cycle later
    //    via loc_valid_out gating the output registers.
    //    For proper alignment across the pipeline, C0..C18 must be delayed
    //    by one cycle to match S0/S1.  A simple register stage is added below.
    //==========================================================================

    // Delay C0..C18 by 1 cycle to align with the registered S0/S1
    reg [15:0] C0r,  C1r,  C2r,  C3r,  C4r,  C5r,  C6r,  C7r,  C8r,  C9r;
    reg [15:0] C10r, C11r, C12r, C13r, C14r, C15r, C16r, C17r, C18r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            C0r<=0; C1r<=0; C2r<=0; C3r<=0; C4r<=0; C5r<=0; C6r<=0;
            C7r<=0; C8r<=0; C9r<=0; C10r<=0; C11r<=0; C12r<=0; C13r<=0;
            C14r<=0; C15r<=0; C16r<=0; C17r<=0; C18r<=0;
        end else if (dec_valid_in) begin
            C0r<=C0;   C1r<=C1;   C2r<=C2;   C3r<=C3;   C4r<=C4;
            C5r<=C5;   C6r<=C6;   C7r<=C7;   C8r<=C8;   C9r<=C9;
            C10r<=C10; C11r<=C11; C12r<=C12; C13r<=C13; C14r<=C14;
            C15r<=C15; C16r<=C16; C17r<=C17; C18r<=C18;
        end
    end

    ecc_error_corrector u_error_corrector (
        // Delayed (aligned) codeword symbols
        .C0  (C0r),  .C1  (C1r),  .C2  (C2r),  .C3  (C3r),  .C4  (C4r),
        .C5  (C5r),  .C6  (C6r),  .C7  (C7r),  .C8  (C8r),  .C9  (C9r),
        .C10 (C10r), .C11 (C11r), .C12 (C12r), .C13 (C13r), .C14 (C14r),
        .C15 (C15r), .C16 (C16r), .C17 (C17r), .C18 (C18r),

        // DBE weight-2
        .use_dbe_w2   (use_dbe_w2),
        .dbe_w2_loc0  (dbe_w2_loc0),
        .dbe_w2_loc1  (dbe_w2_loc1),
        .dbe_w2_err0  (dbe_w2_err0),
        .dbe_w2_err1  (dbe_w2_err1),

        // DBE weight-1
        .use_dbe_w1   (use_dbe_w1),
        .dbe_w1_loc0  (dbe_w1_loc0),
        .dbe_w1_err0  (dbe_w1_err0),
        .dbe_w1_err1  (dbe_w1_err1),

        // DBE weight-0
        .use_dbe_w0   (use_dbe_w0),
        .dbe_w0_loc0  (dbe_w0_loc0),
        .dbe_w0_loc1  (dbe_w0_loc1),
        .dbe_w0_err   (dbe_w0_err),

        .data_out     (dec_data_out)
    );

    //==========================================================================
    // SEVERITY ENCODER
    //==========================================================================
    reg [1:0] severity;
    always @(*) begin
        if (!dec_error_detected)                               severity = 2'b00;
        else if (dec_uncorrectable)                            severity = 2'b10;
        else if (dec_error_corrected && dec_multi_bit_error)   severity = 2'b11;
        else if (dec_error_corrected)                          severity = 2'b01;
        else                                                   severity = 2'b00;
    end

    //==========================================================================
    // SEVERITY BURST GENERATOR
    //==========================================================================
    sev_burst_generator u_sev_burst (
        .clk         (clk),
        .rst_n       (rst_n),
        .burst_start (burst_start),
        .severity_in (severity),
        .sev_pins    (sev_out)
    );

    //==========================================================================
    // OUTPUT REGISTERS
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_out_valid    <= 1'b0;
            rd_data_out     <= 272'b0;
            error_detected  <= 1'b0;
            error_corrected <= 1'b0;
            uncorrectable   <= 1'b0;
        end else begin
            rd_out_valid <= loc_valid_out;

            if (output_reg_clk_en) begin
                rd_data_out     <= dec_data_out;
                error_detected  <= dec_error_detected;
                error_corrected <= dec_error_corrected;
                uncorrectable   <= dec_uncorrectable;
            end
        end
    end

endmodule


//================================================================================
// SEVERITY OUTPUT ACTIVE PATTERN GENERATOR
//================================================================================
module sev_burst_generator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       burst_start,
    input  wire [1:0] severity_in,
    output reg  [1:0] sev_pins
);

    reg [2:0] burst_cnt;
    reg [1:0] sev_latched;

    wire burst_active;
    assign burst_active = burst_start | (burst_cnt != 3'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_cnt   <= 3'b000;
            sev_latched <= 2'b00;
            sev_pins    <= 2'b00;
        end else if (burst_active) begin
            if (burst_start) begin
                burst_cnt   <= 3'b001;
                sev_latched <= severity_in;
                sev_pins    <= 2'b00;
            end else begin
                if (burst_cnt < 3'd7)
                    burst_cnt <= burst_cnt + 1'b1;
                else
                    burst_cnt <= 3'b000;

                if (burst_cnt >= 3'd3)
                    sev_pins <= sev_latched;
                else
                    sev_pins <= 2'b00;
            end
        end
    end

endmodule