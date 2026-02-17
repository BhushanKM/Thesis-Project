`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bhushan Kiran Munoli
// 
// Create Date: 2026
// Design Name: DBB-ECC Decoder
// Module Name: ecc_decoder
// Project Name: ECC implementation for HBM3
// Target Devices: FPGA
// Tool Versions: 
// Description: 
//   DBB-ECC Decoder for RS16(19,17) based on the paper:
//   "DBB-ECC: Random Double Bit and Burst Error Correction Code for HBM3"
//
//   Capabilities:
//   - Single Symbol Error (SSE) correction
//   - Double Bit Error (DBE) correction (errors in different symbols)
//
//   Architecture:
//   1. Syndrome Generator - computes S0, S1
//   2. SSE Locator - standard RS decoding
//   3. DBE Locator - based on S0 weight (0, 1, 2)
//   4. Decision Logic - selects valid correction
//   5. Error Corrector - XOR to fix errors
//
// Dependencies: gf_mul_16.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ecc_decoder (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire [303:0] codeword_in,   // 19 symbols × 16 bits = 304 bits
    output reg          valid_out,
    output reg  [271:0] data_out,      // 17 symbols × 16 bits = 272 bits (corrected)
    output reg          error_detected,
    output reg          error_corrected,
    output reg          multi_bit_error,   // High if corrected error was multi-bit (CEm)
    output reg          uncorrectable
);

    // T values: Ti = alpha^(n-1-i) where n=19, i=0..18
    // Precomputed for GF(2^16) with primitive poly x^16 + x^5 + x^3 + x + 1
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
    localparam [15:0] T17 = 16'h0002;   // alpha^1 (P0)
    localparam [15:0] T18 = 16'h0001;   // alpha^0 (P1)

    // Extract 19 codeword symbols (17 data + 2 parity)
    wire [15:0] C [0:18];
    assign C[0]  = codeword_in[303:288];  // D0
    assign C[1]  = codeword_in[287:272];  // D1
    assign C[2]  = codeword_in[271:256];  // D2
    assign C[3]  = codeword_in[255:240];  // D3
    assign C[4]  = codeword_in[239:224];  // D4
    assign C[5]  = codeword_in[223:208];  // D5
    assign C[6]  = codeword_in[207:192];  // D6
    assign C[7]  = codeword_in[191:176];  // D7
    assign C[8]  = codeword_in[175:160];  // D8
    assign C[9]  = codeword_in[159:144];  // D9
    assign C[10] = codeword_in[143:128];  // D10
    assign C[11] = codeword_in[127:112];  // D11
    assign C[12] = codeword_in[111:96];   // D12
    assign C[13] = codeword_in[95:80];    // D13
    assign C[14] = codeword_in[79:64];    // D14
    assign C[15] = codeword_in[63:48];    // D15
    assign C[16] = codeword_in[47:32];    // D16
    assign C[17] = codeword_in[31:16];    // P0
    assign C[18] = codeword_in[15:0];     // P1

    //==========================================================================
    // SYNDROME GENERATOR
    //==========================================================================
    // S0 = C[0] + C[1] + ... + C[18] (XOR of all symbols)
    // S1 = T0*C[0] + T1*C[1] + ... + T18*C[18]
    
    wire [15:0] S0;
    wire [15:0] S1;
    
    // S0: XOR of all codeword symbols
    assign S0 = C[0]  ^ C[1]  ^ C[2]  ^ C[3]  ^ C[4]  ^ 
                C[5]  ^ C[6]  ^ C[7]  ^ C[8]  ^ C[9]  ^ 
                C[10] ^ C[11] ^ C[12] ^ C[13] ^ C[14] ^ 
                C[15] ^ C[16] ^ C[17] ^ C[18];

    // GF multiplications for S1: Ti * C[i]
    wire [15:0] TC [0:18];
    
    gf_mul_16_opt_reg gf_s1_0  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(C[0]),  .valid_out(), .p(TC[0]));
    gf_mul_16_opt_reg gf_s1_1  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(C[1]),  .valid_out(), .p(TC[1]));
    gf_mul_16_opt_reg gf_s1_2  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(C[2]),  .valid_out(), .p(TC[2]));
    gf_mul_16_opt_reg gf_s1_3  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(C[3]),  .valid_out(), .p(TC[3]));
    gf_mul_16_opt_reg gf_s1_4  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(C[4]),  .valid_out(), .p(TC[4]));
    gf_mul_16_opt_reg gf_s1_5  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(C[5]),  .valid_out(), .p(TC[5]));
    gf_mul_16_opt_reg gf_s1_6  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(C[6]),  .valid_out(), .p(TC[6]));
    gf_mul_16_opt_reg gf_s1_7  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(C[7]),  .valid_out(), .p(TC[7]));
    gf_mul_16_opt_reg gf_s1_8  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(C[8]),  .valid_out(), .p(TC[8]));
    gf_mul_16_opt_reg gf_s1_9  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(C[9]),  .valid_out(), .p(TC[9]));
    gf_mul_16_opt_reg gf_s1_10 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(C[10]), .valid_out(), .p(TC[10]));
    gf_mul_16_opt_reg gf_s1_11 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(C[11]), .valid_out(), .p(TC[11]));
    gf_mul_16_opt_reg gf_s1_12 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(C[12]), .valid_out(), .p(TC[12]));
    gf_mul_16_opt_reg gf_s1_13 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(C[13]), .valid_out(), .p(TC[13]));
    gf_mul_16_opt_reg gf_s1_14 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(C[14]), .valid_out(), .p(TC[14]));
    gf_mul_16_opt_reg gf_s1_15 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(C[15]), .valid_out(), .p(TC[15]));
    gf_mul_16_opt_reg gf_s1_16 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(C[16]), .valid_out(), .p(TC[16]));
    gf_mul_16_opt_reg gf_s1_17 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T17), .b(C[17]), .valid_out(), .p(TC[17]));
    gf_mul_16_opt_reg gf_s1_18 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T18), .b(C[18]), .valid_out(), .p(TC[18]));

    // S1: XOR of all Ti*C[i] products
    assign S1 = TC[0]  ^ TC[1]  ^ TC[2]  ^ TC[3]  ^ TC[4]  ^ 
                TC[5]  ^ TC[6]  ^ TC[7]  ^ TC[8]  ^ TC[9]  ^ 
                TC[10] ^ TC[11] ^ TC[12] ^ TC[13] ^ TC[14] ^ 
                TC[15] ^ TC[16] ^ TC[17] ^ TC[18];

    //==========================================================================
    // COUNT "1"s IN S0 (Hamming Weight)
    //==========================================================================
    wire [4:0] s0_weight;
    assign s0_weight = S0[0]  + S0[1]  + S0[2]  + S0[3]  +
                       S0[4]  + S0[5]  + S0[6]  + S0[7]  +
                       S0[8]  + S0[9]  + S0[10] + S0[11] +
                       S0[12] + S0[13] + S0[14] + S0[15];

    // Classification based on S0 weight
    wire weight_is_0;
    wire weight_is_1;
    wire weight_is_2;

    assign weight_is_0 = (s0_weight == 5'd0);
    assign weight_is_1 = (s0_weight == 5'd1);
    assign weight_is_2 = (s0_weight == 5'd2);

    //==========================================================================
    // SSE LOCATOR (Single Symbol Error)
    //==========================================================================
    // For SSE: Ti * S0 XOR S1 = 0 gives error location i
    // Error pattern = S0
    
    wire [15:0] sse_check [0:18];
    wire [18:0] sse_match;
    
    // Compute Ti * S0 for each position
    wire [15:0] T_S0 [0:18];
    
    gf_mul_16_opt_reg gf_sse_0  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(S0), .valid_out(), .p(T_S0[0]));
    gf_mul_16_opt_reg gf_sse_1  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(S0), .valid_out(), .p(T_S0[1]));
    gf_mul_16_opt_reg gf_sse_2  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(S0), .valid_out(), .p(T_S0[2]));
    gf_mul_16_opt_reg gf_sse_3  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(S0), .valid_out(), .p(T_S0[3]));
    gf_mul_16_opt_reg gf_sse_4  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(S0), .valid_out(), .p(T_S0[4]));
    gf_mul_16_opt_reg gf_sse_5  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(S0), .valid_out(), .p(T_S0[5]));
    gf_mul_16_opt_reg gf_sse_6  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(S0), .valid_out(), .p(T_S0[6]));
    gf_mul_16_opt_reg gf_sse_7  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(S0), .valid_out(), .p(T_S0[7]));
    gf_mul_16_opt_reg gf_sse_8  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(S0), .valid_out(), .p(T_S0[8]));
    gf_mul_16_opt_reg gf_sse_9  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(S0), .valid_out(), .p(T_S0[9]));
    gf_mul_16_opt_reg gf_sse_10 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(S0), .valid_out(), .p(T_S0[10]));
    gf_mul_16_opt_reg gf_sse_11 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(S0), .valid_out(), .p(T_S0[11]));
    gf_mul_16_opt_reg gf_sse_12 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(S0), .valid_out(), .p(T_S0[12]));
    gf_mul_16_opt_reg gf_sse_13 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(S0), .valid_out(), .p(T_S0[13]));
    gf_mul_16_opt_reg gf_sse_14 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(S0), .valid_out(), .p(T_S0[14]));
    gf_mul_16_opt_reg gf_sse_15 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(S0), .valid_out(), .p(T_S0[15]));
    gf_mul_16_opt_reg gf_sse_16 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(S0), .valid_out(), .p(T_S0[16]));
    gf_mul_16_opt_reg gf_sse_17 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T17), .b(S0), .valid_out(), .p(T_S0[17]));
    gf_mul_16_opt_reg gf_sse_18 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T18), .b(S0), .valid_out(), .p(T_S0[18]));

    // Check Ti*S0 XOR S1 = 0
    assign sse_check[0]  = T_S0[0]  ^ S1;
    assign sse_check[1]  = T_S0[1]  ^ S1;
    assign sse_check[2]  = T_S0[2]  ^ S1;
    assign sse_check[3]  = T_S0[3]  ^ S1;
    assign sse_check[4]  = T_S0[4]  ^ S1;
    assign sse_check[5]  = T_S0[5]  ^ S1;
    assign sse_check[6]  = T_S0[6]  ^ S1;
    assign sse_check[7]  = T_S0[7]  ^ S1;
    assign sse_check[8]  = T_S0[8]  ^ S1;
    assign sse_check[9]  = T_S0[9]  ^ S1;
    assign sse_check[10] = T_S0[10] ^ S1;
    assign sse_check[11] = T_S0[11] ^ S1;
    assign sse_check[12] = T_S0[12] ^ S1;
    assign sse_check[13] = T_S0[13] ^ S1;
    assign sse_check[14] = T_S0[14] ^ S1;
    assign sse_check[15] = T_S0[15] ^ S1;
    assign sse_check[16] = T_S0[16] ^ S1;
    assign sse_check[17] = T_S0[17] ^ S1;
    assign sse_check[18] = T_S0[18] ^ S1;

    // Match flags
    assign sse_match[0]  = (sse_check[0]  == 16'h0);
    assign sse_match[1]  = (sse_check[1]  == 16'h0);
    assign sse_match[2]  = (sse_check[2]  == 16'h0);
    assign sse_match[3]  = (sse_check[3]  == 16'h0);
    assign sse_match[4]  = (sse_check[4]  == 16'h0);
    assign sse_match[5]  = (sse_check[5]  == 16'h0);
    assign sse_match[6]  = (sse_check[6]  == 16'h0);
    assign sse_match[7]  = (sse_check[7]  == 16'h0);
    assign sse_match[8]  = (sse_check[8]  == 16'h0);
    assign sse_match[9]  = (sse_check[9]  == 16'h0);
    assign sse_match[10] = (sse_check[10] == 16'h0);
    assign sse_match[11] = (sse_check[11] == 16'h0);
    assign sse_match[12] = (sse_check[12] == 16'h0);
    assign sse_match[13] = (sse_check[13] == 16'h0);
    assign sse_match[14] = (sse_check[14] == 16'h0);
    assign sse_match[15] = (sse_check[15] == 16'h0);
    assign sse_match[16] = (sse_check[16] == 16'h0);
    assign sse_match[17] = (sse_check[17] == 16'h0);
    assign sse_match[18] = (sse_check[18] == 16'h0);

    wire sse_found;
    assign sse_found = |sse_match;

    // SSE error location (one-hot to binary)
    reg [4:0] sse_location;
    always @(*) begin
        case (1'b1)
            sse_match[0]:  sse_location = 5'd0;
            sse_match[1]:  sse_location = 5'd1;
            sse_match[2]:  sse_location = 5'd2;
            sse_match[3]:  sse_location = 5'd3;
            sse_match[4]:  sse_location = 5'd4;
            sse_match[5]:  sse_location = 5'd5;
            sse_match[6]:  sse_location = 5'd6;
            sse_match[7]:  sse_location = 5'd7;
            sse_match[8]:  sse_location = 5'd8;
            sse_match[9]:  sse_location = 5'd9;
            sse_match[10]: sse_location = 5'd10;
            sse_match[11]: sse_location = 5'd11;
            sse_match[12]: sse_location = 5'd12;
            sse_match[13]: sse_location = 5'd13;
            sse_match[14]: sse_location = 5'd14;
            sse_match[15]: sse_location = 5'd15;
            sse_match[16]: sse_location = 5'd16;
            sse_match[17]: sse_location = 5'd17;
            sse_match[18]: sse_location = 5'd18;
            default:       sse_location = 5'd31;
        endcase
    end

    //==========================================================================
    // DBE LOCATOR - SYNDROME SPLITTER (for weight=2)
    //==========================================================================
    // Split S0 into two SBE patterns when weight=2
    // Find first '1' from LSB -> Ej0, then Ej1 = S0 XOR Ej0
    
    reg [15:0] Ej0_w2;
    reg [15:0] Ej1_w2;
    
    always @(*) begin
        Ej0_w2 = 16'h0;
        Ej1_w2 = 16'h0;
        if (S0[0])       Ej0_w2 = 16'h0001;
        else if (S0[1])  Ej0_w2 = 16'h0002;
        else if (S0[2])  Ej0_w2 = 16'h0004;
        else if (S0[3])  Ej0_w2 = 16'h0008;
        else if (S0[4])  Ej0_w2 = 16'h0010;
        else if (S0[5])  Ej0_w2 = 16'h0020;
        else if (S0[6])  Ej0_w2 = 16'h0040;
        else if (S0[7])  Ej0_w2 = 16'h0080;
        else if (S0[8])  Ej0_w2 = 16'h0100;
        else if (S0[9])  Ej0_w2 = 16'h0200;
        else if (S0[10]) Ej0_w2 = 16'h0400;
        else if (S0[11]) Ej0_w2 = 16'h0800;
        else if (S0[12]) Ej0_w2 = 16'h1000;
        else if (S0[13]) Ej0_w2 = 16'h2000;
        else if (S0[14]) Ej0_w2 = 16'h4000;
        else if (S0[15]) Ej0_w2 = 16'h8000;
        Ej1_w2 = S0 ^ Ej0_w2;
    end

    //==========================================================================
    // DBE SUBLOCATOR 1 (weight=2): Type 1 & Type 2
    //==========================================================================
    // Type 1: T_i0*E_i0 XOR T_i1*E_i1 XOR S1 = 0 (both in data)
    // Type 2: T_i0*E_i0 XOR S1 = 0 (one in data, one in P0)
    
    // Compute Ti*Ej0 and Ti*Ej1 for all data positions (0-16)
    wire [15:0] T_Ej0 [0:16];
    wire [15:0] T_Ej1 [0:16];
    
    gf_mul_16_opt_reg gf_dbe_0a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[0]));
    gf_mul_16_opt_reg gf_dbe_1a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[1]));
    gf_mul_16_opt_reg gf_dbe_2a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[2]));
    gf_mul_16_opt_reg gf_dbe_3a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[3]));
    gf_mul_16_opt_reg gf_dbe_4a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[4]));
    gf_mul_16_opt_reg gf_dbe_5a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[5]));
    gf_mul_16_opt_reg gf_dbe_6a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[6]));
    gf_mul_16_opt_reg gf_dbe_7a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[7]));
    gf_mul_16_opt_reg gf_dbe_8a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[8]));
    gf_mul_16_opt_reg gf_dbe_9a  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(Ej0_w2), .valid_out(), .p(T_Ej0[9]));
    gf_mul_16_opt_reg gf_dbe_10a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(Ej0_w2), .valid_out(), .p(T_Ej0[10]));
    gf_mul_16_opt_reg gf_dbe_11a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(Ej0_w2), .valid_out(), .p(T_Ej0[11]));
    gf_mul_16_opt_reg gf_dbe_12a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(Ej0_w2), .valid_out(), .p(T_Ej0[12]));
    gf_mul_16_opt_reg gf_dbe_13a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(Ej0_w2), .valid_out(), .p(T_Ej0[13]));
    gf_mul_16_opt_reg gf_dbe_14a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(Ej0_w2), .valid_out(), .p(T_Ej0[14]));
    gf_mul_16_opt_reg gf_dbe_15a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(Ej0_w2), .valid_out(), .p(T_Ej0[15]));
    gf_mul_16_opt_reg gf_dbe_16a (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(Ej0_w2), .valid_out(), .p(T_Ej0[16]));

    gf_mul_16_opt_reg gf_dbe_0b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[0]));
    gf_mul_16_opt_reg gf_dbe_1b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[1]));
    gf_mul_16_opt_reg gf_dbe_2b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[2]));
    gf_mul_16_opt_reg gf_dbe_3b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[3]));
    gf_mul_16_opt_reg gf_dbe_4b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[4]));
    gf_mul_16_opt_reg gf_dbe_5b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[5]));
    gf_mul_16_opt_reg gf_dbe_6b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[6]));
    gf_mul_16_opt_reg gf_dbe_7b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[7]));
    gf_mul_16_opt_reg gf_dbe_8b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[8]));
    gf_mul_16_opt_reg gf_dbe_9b  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(Ej1_w2), .valid_out(), .p(T_Ej1[9]));
    gf_mul_16_opt_reg gf_dbe_10b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(Ej1_w2), .valid_out(), .p(T_Ej1[10]));
    gf_mul_16_opt_reg gf_dbe_11b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(Ej1_w2), .valid_out(), .p(T_Ej1[11]));
    gf_mul_16_opt_reg gf_dbe_12b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(Ej1_w2), .valid_out(), .p(T_Ej1[12]));
    gf_mul_16_opt_reg gf_dbe_13b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(Ej1_w2), .valid_out(), .p(T_Ej1[13]));
    gf_mul_16_opt_reg gf_dbe_14b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(Ej1_w2), .valid_out(), .p(T_Ej1[14]));
    gf_mul_16_opt_reg gf_dbe_15b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(Ej1_w2), .valid_out(), .p(T_Ej1[15]));
    gf_mul_16_opt_reg gf_dbe_16b (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(Ej1_w2), .valid_out(), .p(T_Ej1[16]));

    // Type 1 check: For each pair (i0, i1), check T_i0*Ej0 XOR T_i1*Ej1 XOR S1 = 0
    // Also try swapped: T_i0*Ej1 XOR T_i1*Ej0 XOR S1 = 0
    // Simplified: Check a subset of common cases
    
    reg        dbe_w2_found;
    reg [4:0]  dbe_w2_loc0;
    reg [4:0]  dbe_w2_loc1;
    reg [15:0] dbe_w2_err0;
    reg [15:0] dbe_w2_err1;
    
    // Type 1 matching: Ti*Ej0 XOR Tj*Ej1 XOR S1 = 0
    // Generate parallel comparators for all (i0, i1) pairs
    wire [135:0] type1_match_a;  // (Ej0, Ej1) assignment
    wire [135:0] type1_match_b;  // (Ej1, Ej0) assignment
    wire [4:0]   type1_loc0 [0:135];
    wire [4:0]   type1_loc1 [0:135];

    genvar gi0, gi1;
    generate
        for (gi0 = 0; gi0 < 17; gi0 = gi0 + 1) begin : gen_type1_outer
            for (gi1 = gi0 + 1; gi1 < 17; gi1 = gi1 + 1) begin : gen_type1_inner
                localparam integer pidx = gi0 * 17 - (gi0 * (gi0 + 1)) / 2 + (gi1 - gi0 - 1);
                assign type1_match_a[pidx] = ((T_Ej0[gi0] ^ T_Ej1[gi1] ^ S1) == 16'h0);
                assign type1_match_b[pidx] = ((T_Ej1[gi0] ^ T_Ej0[gi1] ^ S1) == 16'h0);
                assign type1_loc0[pidx] = gi0[4:0];
                assign type1_loc1[pidx] = gi1[4:0];
            end
        end
    endgenerate

    // Type 2 matching: Ti*Ej0 XOR S1 = 0 (error in P0)
    wire [16:0] type2_match_a;
    wire [16:0] type2_match_b;

    genvar gt2;
    generate
        for (gt2 = 0; gt2 < 17; gt2 = gt2 + 1) begin : gen_type2
            assign type2_match_a[gt2] = ((T_Ej0[gt2] ^ S1) == 16'h0);
            assign type2_match_b[gt2] = ((T_Ej1[gt2] ^ S1) == 16'h0);
        end
    endgenerate

    // Priority encoder for Type 1 matches
    reg        type1_found;
    reg [4:0]  type1_loc0_sel;
    reg [4:0]  type1_loc1_sel;
    reg        type1_swap;

    integer p1;
    always @(*) begin
        type1_found = 1'b0;
        type1_loc0_sel = 5'd0;
        type1_loc1_sel = 5'd0;
        type1_swap = 1'b0;
        for (p1 = 0; p1 < 136; p1 = p1 + 1) begin
            if (!type1_found && type1_match_a[p1]) begin
                type1_found = 1'b1;
                type1_loc0_sel = type1_loc0[p1];
                type1_loc1_sel = type1_loc1[p1];
                type1_swap = 1'b0;
            end
            else if (!type1_found && type1_match_b[p1]) begin
                type1_found = 1'b1;
                type1_loc0_sel = type1_loc0[p1];
                type1_loc1_sel = type1_loc1[p1];
                type1_swap = 1'b1;
            end
        end
    end

    // Priority encoder for Type 2 matches
    reg        type2_found;
    reg [4:0]  type2_loc0_sel;
    reg        type2_swap;

    integer p2;
    always @(*) begin
        type2_found = 1'b0;
        type2_loc0_sel = 5'd0;
        type2_swap = 1'b0;
        for (p2 = 0; p2 < 17; p2 = p2 + 1) begin
            if (!type2_found && type2_match_a[p2]) begin
                type2_found = 1'b1;
                type2_loc0_sel = p2[4:0];
                type2_swap = 1'b0;
            end
            else if (!type2_found && type2_match_b[p2]) begin
                type2_found = 1'b1;
                type2_loc0_sel = p2[4:0];
                type2_swap = 1'b1;
            end
        end
    end

    // Combine Type 1 and Type 2 results
    always @(*) begin
        dbe_w2_found = 1'b0;
        dbe_w2_loc0  = 5'd0;
        dbe_w2_loc1  = 5'd0;
        dbe_w2_err0  = 16'h0;
        dbe_w2_err1  = 16'h0;

        if (weight_is_2) begin
            if (type1_found) begin
                dbe_w2_found = 1'b1;
                dbe_w2_loc0  = type1_loc0_sel;
                dbe_w2_loc1  = type1_loc1_sel;
                dbe_w2_err0  = type1_swap ? Ej1_w2 : Ej0_w2;
                dbe_w2_err1  = type1_swap ? Ej0_w2 : Ej1_w2;
            end
            else if (type2_found) begin
                dbe_w2_found = 1'b1;
                dbe_w2_loc0  = type2_loc0_sel;
                dbe_w2_loc1  = 5'd17;
                dbe_w2_err0  = type2_swap ? Ej1_w2 : Ej0_w2;
                dbe_w2_err1  = type2_swap ? Ej0_w2 : Ej1_w2;
            end
        end
    end

    //==========================================================================
    // DBE SUBLOCATOR 2 (weight=1): Type 3 - One in data, one in P1
    //==========================================================================
    // S0 = error pattern in data symbol
    // Try all 16 SBE patterns for P1 error
    // Check: T_i0*S0 XOR E_p1 XOR S1 = 0

    // Generate parallel comparators for all (location, bit_position) pairs
    // 17 locations × 16 bit positions = 272 comparators
    wire [271:0] type3_match;
    wire [4:0]   type3_loc [0:271];
    wire [3:0]   type3_bit [0:271];

    genvar gw1_loc, gw1_bit;
    generate
        for (gw1_loc = 0; gw1_loc < 17; gw1_loc = gw1_loc + 1) begin : gen_type3_loc
            for (gw1_bit = 0; gw1_bit < 16; gw1_bit = gw1_bit + 1) begin : gen_type3_bit
                localparam integer t3idx = gw1_loc * 16 + gw1_bit;
                assign type3_match[t3idx] = ((T_S0[gw1_loc] ^ (16'h1 << gw1_bit) ^ S1) == 16'h0);
                assign type3_loc[t3idx] = gw1_loc[4:0];
                assign type3_bit[t3idx] = gw1_bit[3:0];
            end
        end
    endgenerate

    // Priority encoder for Type 3 matches
    reg        dbe_w1_found;
    reg [4:0]  dbe_w1_loc0;
    reg [15:0] dbe_w1_err0;
    reg [15:0] dbe_w1_err1;

    integer p3;
    always @(*) begin
        dbe_w1_found = 1'b0;
        dbe_w1_loc0  = 5'd0;
        dbe_w1_err0  = 16'h0;
        dbe_w1_err1  = 16'h0;

        if (weight_is_1) begin
            for (p3 = 0; p3 < 272; p3 = p3 + 1) begin
                if (!dbe_w1_found && type3_match[p3]) begin
                    dbe_w1_found = 1'b1;
                    dbe_w1_loc0  = type3_loc[p3];
                    dbe_w1_err0  = S0;
                    dbe_w1_err1  = 16'h1 << type3_bit[p3];
                end
            end
        end
    end

    //==========================================================================
    // DBE SUBLOCATOR 3 (weight=0): Identical errors in two symbols
    //==========================================================================
    // When S0 = 0, both errors have same bit pattern E (they cancel in XOR)
    // S1 = Ti*E + Tj*E = (Ti ⊕ Tj)*E
    //
    // Per DBB-ECC paper, syndrome table stores 2,448 cases:
    //   - Type 1: 136 data-data pairs × 16 bit positions = 2,176 cases
    //   - Type 2: 17 data-P0 pairs × 16 bit positions = 272 cases
    //
    // Implementation uses precomputed syndrome lookup table for area efficiency
    // (<10% of decoder area per paper)

    reg        dbe_w0_found;
    reg [4:0]  dbe_w0_loc0;
    reg [4:0]  dbe_w0_loc1;
    reg [15:0] dbe_w0_err;

    // T values array for indexed access
    wire [15:0] T_w0 [0:17];
    assign T_w0[0]  = T0;
    assign T_w0[1]  = T1;
    assign T_w0[2]  = T2;
    assign T_w0[3]  = T3;
    assign T_w0[4]  = T4;
    assign T_w0[5]  = T5;
    assign T_w0[6]  = T6;
    assign T_w0[7]  = T7;
    assign T_w0[8]  = T8;
    assign T_w0[9]  = T9;
    assign T_w0[10] = T10;
    assign T_w0[11] = T11;
    assign T_w0[12] = T12;
    assign T_w0[13] = T13;
    assign T_w0[14] = T14;
    assign T_w0[15] = T15;
    assign T_w0[16] = T16;
    assign T_w0[17] = T17;  // P0 coefficient

    //--------------------------------------------------------------------------
    // TYPE 1: Both errors in data symbols (136 pairs × 16 bits = 2176 cases)
    // S1 = (Ti ⊕ Tj) * E where 0 ≤ i < j ≤ 16
    //--------------------------------------------------------------------------
    wire [15:0] t1_xor_val [0:135];
    wire [4:0]  t1_pair_i [0:135];
    wire [4:0]  t1_pair_j [0:135];

    genvar gt1_i, gt1_j;
    generate
        for (gt1_i = 0; gt1_i < 17; gt1_i = gt1_i + 1) begin : gen_t1_outer
            for (gt1_j = gt1_i + 1; gt1_j < 17; gt1_j = gt1_j + 1) begin : gen_t1_inner
                localparam integer t1idx = gt1_i * 17 - (gt1_i * (gt1_i + 1)) / 2 + (gt1_j - gt1_i - 1);
                assign t1_xor_val[t1idx] = T_w0[gt1_i] ^ T_w0[gt1_j];
                assign t1_pair_i[t1idx] = gt1_i[4:0];
                assign t1_pair_j[t1idx] = gt1_j[4:0];
            end
        end
    endgenerate

    // Type 1 syndrome matching: check (Ti⊕Tj)*E = S1 for all 16 single-bit E
    wire [135:0] t1_match;
    wire [15:0]  t1_err_pattern [0:135];

    genvar gt1_m;
    generate
        for (gt1_m = 0; gt1_m < 136; gt1_m = gt1_m + 1) begin : gen_t1_match
            wire [15:0] t1_product [0:15];
            wire [15:0] t1_valid_e;

            genvar gt1_e;
            for (gt1_e = 0; gt1_e < 16; gt1_e = gt1_e + 1) begin : gen_t1_e
                gf_mul_16_opt_comb gf_t1_mul (
                    .a(t1_xor_val[gt1_m]),
                    .b(16'h1 << gt1_e),
                    .p(t1_product[gt1_e])
                );
                assign t1_valid_e[gt1_e] = (t1_product[gt1_e] == S1);
            end

            // Priority encoder for error bit
            reg [3:0] t1_found_bit;
            reg       t1_found_valid;
            integer t1_eb;
            always @(*) begin
                t1_found_bit = 4'd0;
                t1_found_valid = 1'b0;
                for (t1_eb = 0; t1_eb < 16; t1_eb = t1_eb + 1) begin
                    if (!t1_found_valid && t1_valid_e[t1_eb]) begin
                        t1_found_valid = 1'b1;
                        t1_found_bit = t1_eb[3:0];
                    end
                end
            end

            assign t1_match[gt1_m] = t1_found_valid;
            assign t1_err_pattern[gt1_m] = 16'h1 << t1_found_bit;
        end
    endgenerate

    //--------------------------------------------------------------------------
    // TYPE 2: One error in data, one in P0 (17 pairs × 16 bits = 272 cases)
    // S1 = (Ti ⊕ T17) * E where 0 ≤ i ≤ 16, T17 is P0 coefficient
    //--------------------------------------------------------------------------
    wire [15:0] t2_xor_val [0:16];

    genvar gt2_i;
    generate
        for (gt2_i = 0; gt2_i < 17; gt2_i = gt2_i + 1) begin : gen_t2_xor
            assign t2_xor_val[gt2_i] = T_w0[gt2_i] ^ T17;
        end
    endgenerate

    // Type 2 syndrome matching: check (Ti⊕T17)*E = S1 for all 16 single-bit E
    wire [16:0] t2_match;
    wire [15:0] t2_err_pattern [0:16];

    genvar gt2_m;
    generate
        for (gt2_m = 0; gt2_m < 17; gt2_m = gt2_m + 1) begin : gen_t2_match
            wire [15:0] t2_product [0:15];
            wire [15:0] t2_valid_e;

            genvar gt2_e;
            for (gt2_e = 0; gt2_e < 16; gt2_e = gt2_e + 1) begin : gen_t2_e
                gf_mul_16_opt_comb gf_t2_mul (
                    .a(t2_xor_val[gt2_m]),
                    .b(16'h1 << gt2_e),
                    .p(t2_product[gt2_e])
                );
                assign t2_valid_e[gt2_e] = (t2_product[gt2_e] == S1);
            end

            // Priority encoder for error bit
            reg [3:0] t2_found_bit;
            reg       t2_found_valid;
            integer t2_eb;
            always @(*) begin
                t2_found_bit = 4'd0;
                t2_found_valid = 1'b0;
                for (t2_eb = 0; t2_eb < 16; t2_eb = t2_eb + 1) begin
                    if (!t2_found_valid && t2_valid_e[t2_eb]) begin
                        t2_found_valid = 1'b1;
                        t2_found_bit = t2_eb[3:0];
                    end
                end
            end

            assign t2_match[gt2_m] = t2_found_valid;
            assign t2_err_pattern[gt2_m] = 16'h1 << t2_found_bit;
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Priority encoder: Type 1 first, then Type 2
    // Total coverage: 2,176 + 272 = 2,448 cases (per paper)
    //--------------------------------------------------------------------------
    reg        t1_found;
    reg [4:0]  t1_loc0_sel;
    reg [4:0]  t1_loc1_sel;
    reg [15:0] t1_err_sel;

    integer pt1;
    always @(*) begin
        t1_found = 1'b0;
        t1_loc0_sel = 5'd0;
        t1_loc1_sel = 5'd0;
        t1_err_sel = 16'h0;
        for (pt1 = 0; pt1 < 136; pt1 = pt1 + 1) begin
            if (!t1_found && t1_match[pt1]) begin
                t1_found = 1'b1;
                t1_loc0_sel = t1_pair_i[pt1];
                t1_loc1_sel = t1_pair_j[pt1];
                t1_err_sel = t1_err_pattern[pt1];
            end
        end
    end

    reg        t2_found;
    reg [4:0]  t2_loc0_sel;
    reg [15:0] t2_err_sel;

    integer pt2;
    always @(*) begin
        t2_found = 1'b0;
        t2_loc0_sel = 5'd0;
        t2_err_sel = 16'h0;
        for (pt2 = 0; pt2 < 17; pt2 = pt2 + 1) begin
            if (!t2_found && t2_match[pt2]) begin
                t2_found = 1'b1;
                t2_loc0_sel = pt2[4:0];
                t2_err_sel = t2_err_pattern[pt2];
            end
        end
    end

    // Combine Type 1 and Type 2 results for weight=0
    always @(*) begin
        dbe_w0_found = 1'b0;
        dbe_w0_loc0  = 5'd0;
        dbe_w0_loc1  = 5'd0;
        dbe_w0_err   = 16'h0;

        if (weight_is_0 && (S1 != 16'h0)) begin
            if (t1_found) begin
                // Type 1: Both errors in data symbols
                dbe_w0_found = 1'b1;
                dbe_w0_loc0  = t1_loc0_sel;
                dbe_w0_loc1  = t1_loc1_sel;
                dbe_w0_err   = t1_err_sel;
            end
            else if (t2_found) begin
                // Type 2: One error in data, one in P0
                dbe_w0_found = 1'b1;
                dbe_w0_loc0  = t2_loc0_sel;
                dbe_w0_loc1  = 5'd17;  // P0 location
                dbe_w0_err   = t2_err_sel;
            end
        end
    end

    //==========================================================================
    // DECISION LOGIC
    //==========================================================================
    // Priority order:
    // 1. No error (S0=0, S1=0)
    // 2. SSE - Single Symbol Error (S0≠0, Ti*S0=S1 for some i)
    // 3. DBE weight=0 - Identical errors (S0=0, S1≠0)
    // 4. DBE weight=1 - One error in data, one in P1
    // 5. DBE weight=2 - Two single-bit errors in different symbols
    // 6. Uncorrectable - None of the above

    wire no_error;
    assign no_error = (S0 == 16'h0) && (S1 == 16'h0);

    // SSE is valid when S0≠0 AND we find a matching location
    // SSE takes priority over DBE for weight=1 and weight=2 cases
    wire use_sse;
    wire use_dbe_w2;
    wire use_dbe_w1;
    wire use_dbe_w0;

    // SSE: Valid for any S0≠0 when Ti*S0=S1
    assign use_sse    = sse_found && (S0 != 16'h0);

    // DBE weight=0: S0=0 but S1≠0 (identical single-bit errors cancel)
    assign use_dbe_w0 = dbe_w0_found && weight_is_0 && (S1 != 16'h0);

    // DBE weight=1: Only if SSE didn't match (one error in data, one in P1)
    assign use_dbe_w1 = dbe_w1_found && weight_is_1 && !sse_found;

    // DBE weight=2: Only if SSE didn't match (two single-bit errors in data)
    assign use_dbe_w2 = dbe_w2_found && weight_is_2 && !sse_found;

    //==========================================================================
    // ERROR CORRECTOR
    //==========================================================================
    reg [15:0] corrected_C [0:18];
    
    integer idx;
    always @(*) begin
        // Default: no correction
        for (idx = 0; idx < 19; idx = idx + 1) begin
            corrected_C[idx] = C[idx];
        end
        
        if (use_sse && sse_location < 19) begin
            // Single symbol error correction
            corrected_C[sse_location] = C[sse_location] ^ S0;
        end
        else if (use_dbe_w2) begin
            // Double bit error correction (weight=2)
            corrected_C[dbe_w2_loc0] = C[dbe_w2_loc0] ^ dbe_w2_err0;
            corrected_C[dbe_w2_loc1] = C[dbe_w2_loc1] ^ dbe_w2_err1;
        end
        else if (use_dbe_w1) begin
            // Double bit error correction (weight=1)
            corrected_C[dbe_w1_loc0] = C[dbe_w1_loc0] ^ dbe_w1_err0;
            corrected_C[18]          = C[18] ^ dbe_w1_err1;  // P1
        end
        else if (use_dbe_w0) begin
            // Double bit error correction (weight=0)
            corrected_C[dbe_w0_loc0] = C[dbe_w0_loc0] ^ dbe_w0_err;
            corrected_C[dbe_w0_loc1] = C[dbe_w0_loc1] ^ dbe_w0_err;
        end
    end

    //==========================================================================
    // OUTPUT REGISTERS
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out       <= 1'b0;
            data_out        <= 272'b0;
            error_detected  <= 1'b0;
            error_corrected <= 1'b0;
            multi_bit_error <= 1'b0;
            uncorrectable   <= 1'b0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                // Output corrected data (first 17 symbols)
                data_out <= {corrected_C[0],  corrected_C[1],  corrected_C[2],  corrected_C[3],
                             corrected_C[4],  corrected_C[5],  corrected_C[6],  corrected_C[7],
                             corrected_C[8],  corrected_C[9],  corrected_C[10], corrected_C[11],
                             corrected_C[12], corrected_C[13], corrected_C[14], corrected_C[15],
                             corrected_C[16]};

                // Status flags
                error_detected  <= !no_error;
                error_corrected <= use_sse || use_dbe_w2 || use_dbe_w1 || use_dbe_w0;
                // Multi-bit error: DBE corrections (errors in multiple symbols)
                multi_bit_error <= use_dbe_w2 || use_dbe_w1 || use_dbe_w0;
                uncorrectable   <= !no_error && !use_sse && !use_dbe_w2 && !use_dbe_w1 && !use_dbe_w0;
            end
        end
    end

endmodule
