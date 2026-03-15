`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Bhushan Kiran Munoli
//
// Module Name: ecc_syndrome_gen
// Project Name: ECC implementation for HBM4
//
// Description:
//   Syndrome generator for DBB-ECC RS16(19,17) decoder.
//
//   Consistent with encoder:
//
//     P0 = D0 ^ D1 ^ ... ^ D16
//     P1 = T0*D0 ^ T1*D1 ^ ... ^ T16*D16
//
//   Therefore decoder computes:
//
//     S0 = C0 ^ C1 ^ ... ^ C16 ^ P0
//     S1 = T0*C0 ^ T1*C1 ^ ... ^ T16*C16 ^ P1
//
//   For a valid codeword, S0 = 0 and S1 = 0.
//
//////////////////////////////////////////////////////////////////////////////////

module ecc_syndrome_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,

    input  wire [15:0] C0,
    input  wire [15:0] C1,
    input  wire [15:0] C2,
    input  wire [15:0] C3,
    input  wire [15:0] C4,
    input  wire [15:0] C5,
    input  wire [15:0] C6,
    input  wire [15:0] C7,
    input  wire [15:0] C8,
    input  wire [15:0] C9,
    input  wire [15:0] C10,
    input  wire [15:0] C11,
    input  wire [15:0] C12,
    input  wire [15:0] C13,
    input  wire [15:0] C14,
    input  wire [15:0] C15,
    input  wire [15:0] C16,
    input  wire [15:0] P0,
    input  wire [15:0] P1,

    output wire        valid_out,
    output wire [15:0] S0,
    output wire [15:0] S1
);

    // -------------------------------------------------------------------------
    // T constants must MATCH the encoder exactly
    // Encoder uses:
    //   T0  = alpha^18
    //   ...
    //   T16 = alpha^2
    // -------------------------------------------------------------------------
    localparam [15:0] T0  = 16'h00AC;   // alpha^18
    localparam [15:0] T1  = 16'h0056;   // alpha^17
    localparam [15:0] T2  = 16'h002B;   // alpha^16
    localparam [15:0] T3  = 16'h8000;   // alpha^15
    localparam [15:0] T4  = 16'h4000;   // alpha^14
    localparam [15:0] T5  = 16'h2000;   // alpha^13
    localparam [15:0] T6  = 16'h1000;   // alpha^12
    localparam [15:0] T7  = 16'h0800;   // alpha^11
    localparam [15:0] T8  = 16'h0400;   // alpha^10
    localparam [15:0] T9  = 16'h0200;   // alpha^9
    localparam [15:0] T10 = 16'h0100;   // alpha^8
    localparam [15:0] T11 = 16'h0080;   // alpha^7
    localparam [15:0] T12 = 16'h0040;   // alpha^6
    localparam [15:0] T13 = 16'h0020;   // alpha^5
    localparam [15:0] T14 = 16'h0010;   // alpha^4
    localparam [15:0] T15 = 16'h0008;   // alpha^3
    localparam [15:0] T16 = 16'h0004;   // alpha^2

    // -------------------------------------------------------------------------
    // S0 = XOR of 17 data symbols and P0
    // -------------------------------------------------------------------------
    wire [15:0] S0_comb;
    assign S0_comb = C0  ^ C1  ^ C2  ^ C3  ^ C4  ^ C5  ^ C6  ^ C7  ^ C8 ^
                     C9  ^ C10 ^ C11 ^ C12 ^ C13 ^ C14 ^ C15 ^ C16 ^ P0;

    // -------------------------------------------------------------------------
    // S1 data contribution = XOR of Ti*Ci for i=0..16
    // -------------------------------------------------------------------------
    wire [15:0] TC [0:16];

    gf_mul_16_opt gf_s1_0  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(C0),  .valid_out(),         .p(TC[0]));
    gf_mul_16_opt gf_s1_1  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(C1),  .valid_out(),         .p(TC[1]));
    gf_mul_16_opt gf_s1_2  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(C2),  .valid_out(),         .p(TC[2]));
    gf_mul_16_opt gf_s1_3  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(C3),  .valid_out(),         .p(TC[3]));
    gf_mul_16_opt gf_s1_4  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(C4),  .valid_out(),         .p(TC[4]));
    gf_mul_16_opt gf_s1_5  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(C5),  .valid_out(),         .p(TC[5]));
    gf_mul_16_opt gf_s1_6  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(C6),  .valid_out(),         .p(TC[6]));
    gf_mul_16_opt gf_s1_7  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(C7),  .valid_out(),         .p(TC[7]));
    gf_mul_16_opt gf_s1_8  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(C8),  .valid_out(),         .p(TC[8]));
    gf_mul_16_opt gf_s1_9  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(C9),  .valid_out(),         .p(TC[9]));
    gf_mul_16_opt gf_s1_10 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(C10), .valid_out(),         .p(TC[10]));
    gf_mul_16_opt gf_s1_11 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(C11), .valid_out(),         .p(TC[11]));
    gf_mul_16_opt gf_s1_12 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(C12), .valid_out(),         .p(TC[12]));
    gf_mul_16_opt gf_s1_13 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(C13), .valid_out(),         .p(TC[13]));
    gf_mul_16_opt gf_s1_14 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(C14), .valid_out(),         .p(TC[14]));
    gf_mul_16_opt gf_s1_15 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(C15), .valid_out(),         .p(TC[15]));
    gf_mul_16_opt gf_s1_16 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(C16), .valid_out(valid_out), .p(TC[16]));

    wire [15:0] S1_data_comb;
    assign S1_data_comb = TC[0]  ^ TC[1]  ^ TC[2]  ^ TC[3]  ^ TC[4]  ^
                          TC[5]  ^ TC[6]  ^ TC[7]  ^ TC[8]  ^ TC[9]  ^
                          TC[10] ^ TC[11] ^ TC[12] ^ TC[13] ^ TC[14] ^
                          TC[15] ^ TC[16];

    // -------------------------------------------------------------------------
    // Register S0 and P1 one cycle to align with multiplier latency
    // -------------------------------------------------------------------------
    reg [15:0] S0_reg;
    reg [15:0] P1_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            S0_reg <= 16'h0000;
            P1_reg <= 16'h0000;
        end
        else if (valid_in) begin
            S0_reg <= S0_comb;
            P1_reg <= P1;
        end
    end

    assign S0 = S0_reg;
    assign S1 = S1_data_comb ^ P1_reg;

endmodule