`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bhushan Kiran Munoli
// 
// Create Date: 2026
// Design Name: ECC Engine Top with Test Mode
// Module Name: ecc_engine_top
// Project Name: ECC implementation for HBM4
// Target Devices: FPGA
// Tool Versions: 
// Description: 
//   Top-level ECC engine with JEDEC HBM4 compliant test mode.
//   Implements ECC Engine Test Mode per JEDEC Standard No. 270-4 Section 6.9.6
//
//   Test Mode Features:
//   - test_mode_en: Enable ECC engine test mode (MR9 OP2)
//   - cw_sel: Error vector pattern select (MR9 OP3)
//       0 = CW0: Data '1' means error bit, '0' means non-error bit
//       1 = CW1: Data '0' means error bit, '1' means non-error bit
//   - In test mode, WR data is error injection pattern
//   - RD returns corrected data and severity
//
//   Severity Encoding (SEV[1:0]):
//   - 2'b00: NE  (No Error)
//   - 2'b01: CEs (Corrected single-bit error)
//   - 2'b11: CEm (Corrected multi-bit error within symbol)
//   - 2'b10: UE  (Uncorrectable Error)
//
// Dependencies: ecc_encoder.v, ecc_decoder.v, gf_mul_16.v (gf_mul_16_opt modules)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ecc_engine_top (
    input  wire         clk,
    input  wire         rst_n,
    
    // Control signals
    input  wire         test_mode_en,     // MR9 OP2: Test mode enable
    input  wire         cw_sel,           // MR9 OP3: 0=CW0, 1=CW1
    
    // Write path (Normal: data to encode, Test: error injection pattern)
    input  wire         wr_valid,
    input  wire [271:0] wr_data,          // 272b data (17 symbols × 16b)
    output wire         wr_ready,
    
    // Read path (Normal: data from memory, Test: test result)
    input  wire         rd_valid,
    input  wire [303:0] rd_codeword,      // 304b codeword from memory (normal mode)
    input  wire         burst_start,      // BL8 burst start signal for SEV timing
    output reg          rd_out_valid,
    output reg  [271:0] rd_data_out,      // Corrected data output
    output wire [1:0]   sev_out,          // Severity encoding (JEDEC BL8 timed)
    
    // Encoder output (to memory in normal mode)
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
    
    // Encoder signals
    wire        enc_valid;
    wire [271:0] enc_data_in;
    wire [303:0] enc_codeword;
    
    // Decoder signals
    wire        dec_valid_in;
    wire [303:0] dec_codeword_in;
    wire        dec_valid_out;
    wire [271:0] dec_data_out;
    wire        dec_error_detected;
    wire        dec_error_corrected;
    wire        dec_multi_bit_error;
    wire        dec_uncorrectable;
    
    // Test mode signals
    reg  [303:0] test_codeword;
    wire [271:0] error_pattern;
    wire [303:0] injected_codeword;

    //==========================================================================
    // CLOCK GATING ENABLE SIGNALS (Power Optimization)
    //==========================================================================
    // Generate enable signals for clock gating to reduce dynamic power
    
    wire test_cw_clk_en;      // Enable for test_codeword register
    wire output_reg_clk_en;   // Enable for output registers
    
    assign test_cw_clk_en    = test_mode_en & wr_valid;
    assign output_reg_clk_en = dec_valid_out;
    
    //==========================================================================
    // ERROR PATTERN CONVERSION (CW0/CW1)
    //==========================================================================
    // CW0: '1' = error bit, '0' = normal → use wr_data directly
    // CW1: '0' = error bit, '1' = normal → invert wr_data
    
    assign error_pattern = cw_sel ? ~wr_data : wr_data;
    
    //==========================================================================
    // ZERO CODEWORD NOTE (Power/Area Optimization)
    //==========================================================================
    // Encoding of all-zero data: P0 = XOR(0s) = 0, P1 = XOR(Ti*0) = 0
    // Mathematically verified: zero_codeword = 304'b0
    // This eliminates the need for ref_encoder (saves ~50% encoder area + power)
    // Since zero_codeword = 0, XOR with error_pattern = error_pattern directly
    
    //==========================================================================
    // MAIN ENCODER
    //==========================================================================
    // Normal mode: encode wr_data
    // Test mode: not used for encoding (error injection instead)
    
    assign enc_data_in = wr_data;
    assign enc_valid = wr_valid & ~test_mode_en;
    
    ecc_encoder main_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(enc_valid),
        .data_in(enc_data_in),
        .valid_out(enc_valid_out),
        .codeword_out(enc_codeword)
    );
    
    assign enc_codeword_out = enc_codeword;
    assign wr_ready = 1'b1;
    
    //==========================================================================
    // TEST MODE ERROR INJECTION
    //==========================================================================
    // Inject errors by XORing error pattern with reference codeword (all zeros)
    // Since zero_codeword = 0, injected_codeword = {error_pattern, 32'b0}
    
    assign injected_codeword = {error_pattern, 32'b0};
    
    //==========================================================================
    // TEST MODE CODEWORD REGISTER (Clock Gated)
    //==========================================================================
    // Store the injected codeword when write occurs in test mode
    // Clock gating: Only updates when test_cw_clk_en is active
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_codeword <= 304'b0;
        end else if (test_cw_clk_en) begin
            test_codeword <= injected_codeword;
        end
    end
    
    //==========================================================================
    // DECODER INPUT MUX (Optimized - removed redundant ternary)
    //==========================================================================
    // Normal mode: use rd_codeword from memory
    // Test mode: use stored test_codeword
    
    assign dec_valid_in = rd_valid;
    assign dec_codeword_in = test_mode_en ? test_codeword : rd_codeword;
    
    //==========================================================================
    // MAIN DECODER
    //==========================================================================
    
    ecc_decoder main_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(dec_valid_in),
        .codeword_in(dec_codeword_in),
        .valid_out(dec_valid_out),
        .data_out(dec_data_out),
        .error_detected(dec_error_detected),
        .error_corrected(dec_error_corrected),
        .multi_bit_error(dec_multi_bit_error),
        .uncorrectable(dec_uncorrectable)
    );
    
    //==========================================================================
    // SEVERITY ENCODER
    //==========================================================================
    // Convert error flags to SEV[1:0] encoding per JEDEC spec
    //
    // SEV[1:0] encoding:
    //   2'b00 = NE  (No Error)
    //   2'b01 = CEs (Corrected single-bit error)
    //   2'b11 = CEm (Corrected multi-bit error within symbol)
    //   2'b10 = UE  (Uncorrectable Error)

    reg [1:0] severity;

    always @(*) begin
        if (!dec_error_detected) begin
            severity = 2'b00;  // NE: No Error
        end else if (dec_uncorrectable) begin
            severity = 2'b10;  // UE: Uncorrectable Error
        end else if (dec_error_corrected && dec_multi_bit_error) begin
            severity = 2'b11;  // CEm: Corrected multi-bit error
        end else if (dec_error_corrected) begin
            severity = 2'b01;  // CEs: Corrected single-bit error
        end else begin
            severity = 2'b00;  // Default: No Error
        end
    end
    
    //==========================================================================
    // SEVERITY BURST GENERATOR (JEDEC BL8 Timing)
    //==========================================================================
    // Generates proper SEV[1:0] timing per JEDEC spec:
    // - Burst positions 0-3: SEV = 00 (inactive)
    // - Burst positions 4-7: SEV = actual severity
    
    sev_burst_generator u_sev_burst (
        .clk(clk),
        .rst_n(rst_n),
        .burst_start(burst_start),
        .severity_in(severity),
        .sev_pins(sev_out)
    );

    //==========================================================================
    // OUTPUT REGISTERS (Clock Gated)
    //==========================================================================
    // Clock gating: Data registers only update when dec_valid_out is active
    // Valid flag always updates to properly deassert
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_out_valid    <= 1'b0;
            rd_data_out     <= 272'b0;
            error_detected  <= 1'b0;
            error_corrected <= 1'b0;
            uncorrectable   <= 1'b0;
        end else begin
            rd_out_valid <= dec_valid_out;
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
// SEVERITY OUTPUT ACTIVE PATTERN GENERATOR (Clock Gated)
//================================================================================
// Generates BL8 severity pattern per JEDEC spec
// SEV signals are active only in burst positions 4-7
// Clock gating: Registers only update during active burst

module sev_burst_generator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       burst_start,    // Start of BL8 burst
    input  wire [1:0] severity_in,    // Severity from decoder
    output reg  [1:0] sev_pins        // SEV[1:0] output pins
);

    reg [2:0] burst_cnt;
    reg [1:0] sev_latched;

    // Clock gating enable: active during burst (positions 0-7)
    wire burst_active = burst_start | (burst_cnt != 3'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_cnt   <= 3'b0;
            sev_latched <= 2'b00;
            sev_pins    <= 2'b00;
        end else if (burst_active) begin
            if (burst_start) begin
                burst_cnt   <= 3'b1;
                sev_latched <= severity_in;
                sev_pins    <= 2'b00;
            end else begin
                if (burst_cnt < 3'd7) begin
                    burst_cnt <= burst_cnt + 1'b1;
                end else begin
                    burst_cnt <= 3'b0;
                end

                // SEV pattern: positions 0-3 = 00, positions 4-7 = severity
                sev_pins <= (burst_cnt >= 3'd3) ? sev_latched : 2'b00;
            end
        end
    end

endmodule
