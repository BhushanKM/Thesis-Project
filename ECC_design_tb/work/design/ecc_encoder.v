`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Bhushan Kiran Munoli
// 
// Create Date: 2026
// Design Name: DBB-ECC Encoder
// Module Name: ecc_encoder
// Project Name: ECC implementation for HBM3
// Target Devices: FPGA
// Tool Versions: 
// Description: 
//   RS16(19,17) Encoder based on H-matrix method from DBB-ECC paper.
//   - 17 data symbols (272-bit data)
//   - 2 parity symbols (32-bit parity)
//   - Uses GF(2^16) arithmetic with primitive polynomial x^16 + x^5 + x^3 + x + 1
//
//   H-Matrix Structure:
//       [ 1      1      ...    1        1      1    0 ]
//   H = [                                              ]
//       [ T_0    T_1    ...    T_{k-2}  T_{k-1} 0    1 ]
//
//   Parity Generation:
//   P0 = D0 ⊕ D1 ⊕ D2 ⊕ ... ⊕ D16
//   P1 = T0·D0 ⊕ T1·D1 ⊕ T2·D2 ⊕ ... ⊕ T16·D16
//
//   Where Ti = alpha^(n-1-i) in GF(2^16)
//
// Dependencies: gf_mul_16.sv (GF(2^16) multiplier)
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ecc_encoder (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire [271:0] data_in,      // 17 data symbols × 16 bits = 272 bits
    output reg          valid_out,
    output reg  [303:0] codeword_out  // 19 symbols × 16 bits = 304 bits (data + parity)
);

    // T values: Ti = alpha^(n-1-i) where n=19, i=0..18
    // These are precomputed elements in GF(2^16)
    // Primitive poly: x^16 + x^5 + x^3 + x + 1, so alpha^16 = x^5 + x^3 + x + 1 = 0x002B
    // T0 = alpha^18, T1 = alpha^17, ..., T16 = alpha^2, T17 = alpha^1, T18 = alpha^0
    localparam [15:0] T0  = 16'h00AC;   // alpha^18 mod p(x) = x^7 + x^5 + x^3 + x^2
    localparam [15:0] T1  = 16'h0056;   // alpha^17 mod p(x) = x^6 + x^4 + x^2 + x
    localparam [15:0] T2  = 16'h002B;   // alpha^16 mod p(x) = x^5 + x^3 + x + 1
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
    localparam [15:0] T17 = 16'h0002;   // alpha^1 (P0 coefficient)
    localparam [15:0] T18 = 16'h0001;   // alpha^0 (P1 coefficient)
    
    // inv(T17 XOR T18) = inv(0x0003) = 0xFFE6 in GF(2^16)
    localparam [15:0] INV_T17_XOR_T18 = 16'hFFE6;

    // Extract 17 data symbols from input (each 16 bits)
    wire [15:0] D [0:16];
    assign D[0]  = data_in[271:256];
    assign D[1]  = data_in[255:240];
    assign D[2]  = data_in[239:224];
    assign D[3]  = data_in[223:208];
    assign D[4]  = data_in[207:192];
    assign D[5]  = data_in[191:176];
    assign D[6]  = data_in[175:160];
    assign D[7]  = data_in[159:144];
    assign D[8]  = data_in[143:128];
    assign D[9]  = data_in[127:112];
    assign D[10] = data_in[111:96];
    assign D[11] = data_in[95:80];
    assign D[12] = data_in[79:64];
    assign D[13] = data_in[63:48];
    assign D[14] = data_in[47:32];
    assign D[15] = data_in[31:16];
    assign D[16] = data_in[15:0];

    // GF(2^16) multiplication results: Ti * Di
    wire [15:0] TD [0:16];

    // Instantiate 17 optimized GF multipliers for parity P1 calculation
    gf_mul_16_opt_reg gf_mult_0  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T0),  .b(D[0]),  .valid_out(), .p(TD[0]));
    gf_mul_16_opt_reg gf_mult_1  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T1),  .b(D[1]),  .valid_out(), .p(TD[1]));
    gf_mul_16_opt_reg gf_mult_2  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T2),  .b(D[2]),  .valid_out(), .p(TD[2]));
    gf_mul_16_opt_reg gf_mult_3  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T3),  .b(D[3]),  .valid_out(), .p(TD[3]));
    gf_mul_16_opt_reg gf_mult_4  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T4),  .b(D[4]),  .valid_out(), .p(TD[4]));
    gf_mul_16_opt_reg gf_mult_5  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T5),  .b(D[5]),  .valid_out(), .p(TD[5]));
    gf_mul_16_opt_reg gf_mult_6  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T6),  .b(D[6]),  .valid_out(), .p(TD[6]));
    gf_mul_16_opt_reg gf_mult_7  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T7),  .b(D[7]),  .valid_out(), .p(TD[7]));
    gf_mul_16_opt_reg gf_mult_8  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T8),  .b(D[8]),  .valid_out(), .p(TD[8]));
    gf_mul_16_opt_reg gf_mult_9  (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T9),  .b(D[9]),  .valid_out(), .p(TD[9]));
    gf_mul_16_opt_reg gf_mult_10 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T10), .b(D[10]), .valid_out(), .p(TD[10]));
    gf_mul_16_opt_reg gf_mult_11 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T11), .b(D[11]), .valid_out(), .p(TD[11]));
    gf_mul_16_opt_reg gf_mult_12 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T12), .b(D[12]), .valid_out(), .p(TD[12]));
    gf_mul_16_opt_reg gf_mult_13 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T13), .b(D[13]), .valid_out(), .p(TD[13]));
    gf_mul_16_opt_reg gf_mult_14 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T14), .b(D[14]), .valid_out(), .p(TD[14]));
    gf_mul_16_opt_reg gf_mult_15 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T15), .b(D[15]), .valid_out(), .p(TD[15]));
    gf_mul_16_opt_reg gf_mult_16 (.clk(clk), .rst_n(rst_n), .valid_in(valid_in), .a(T16), .b(D[16]), .valid_out(), .p(TD[16]));

    // Standard RS H-matrix parity computation:
    // H = [ 1   1   ...  1   1   1 ]
    //     [ T0  T1  ... T16 T17 T18]
    // For codeword C = [D0..D16, P0, P1], H*C^T = 0 requires:
    //   Row1: D0 + D1 + ... + D16 + P0 + P1 = 0
    //   Row2: T0*D0 + ... + T16*D16 + T17*P0 + T18*P1 = 0
    // Solving: P0 = (S_TD ^ S_D) * inv(T17^T18), P1 = S_D ^ P0
    
    // S_D = XOR of all data symbols
    wire [15:0] S_D;
    assign S_D = D[0]  ^ D[1]  ^ D[2]  ^ D[3]  ^ D[4]  ^ 
                 D[5]  ^ D[6]  ^ D[7]  ^ D[8]  ^ D[9]  ^ 
                 D[10] ^ D[11] ^ D[12] ^ D[13] ^ D[14] ^ 
                 D[15] ^ D[16];

    // S_TD = XOR of all Ti*Di products
    wire [15:0] S_TD;
    assign S_TD = TD[0]  ^ TD[1]  ^ TD[2]  ^ TD[3]  ^ TD[4]  ^ 
                  TD[5]  ^ TD[6]  ^ TD[7]  ^ TD[8]  ^ TD[9]  ^ 
                  TD[10] ^ TD[11] ^ TD[12] ^ TD[13] ^ TD[14] ^ 
                  TD[15] ^ TD[16];

    // diff = S_TD ^ S_D (numerator for P0 computation)
    wire [15:0] diff;
    assign diff = S_TD ^ S_D;

    // Pipeline for proper timing:
    // Cycle 0: valid_in, D[] available, start Ti*Di multipliers
    // Cycle 2: TD[] ready, S_TD available, compute diff, start P0 multiplier
    // Cycle 4: P0 ready, compute P1, output codeword
    
    // Stage 1: Delay valid and data for 2 cycles (waiting for TD[])
    reg valid_d1, valid_d2;
    reg [271:0] data_d1, data_d2;
    reg [15:0] S_D_d1, S_D_d2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_d1 <= 1'b0;
            valid_d2 <= 1'b0;
            data_d1  <= 272'b0;
            data_d2  <= 272'b0;
            S_D_d1   <= 16'b0;
            S_D_d2   <= 16'b0;
        end else begin
            valid_d1 <= valid_in;
            valid_d2 <= valid_d1;
            data_d1  <= data_in;
            data_d2  <= data_d1;
            S_D_d1   <= S_D;
            S_D_d2   <= S_D_d1;
        end
    end
    
    // At cycle 2: TD[] ready, compute diff_delayed for P0 multiplier
    // Note: The P0 multiplier input (diff) uses TD[] which is ready at cycle 2
    // But we instantiated gf_p0_mul with valid_in, which is wrong
    // We need to use combinational multiplier or restructure
    
    // Use combinational GF multiplier for P0 (no additional latency)
    wire [15:0] P0_comb;
    gf_mul_16_opt_comb gf_p0_mul_comb (.a(INV_T17_XOR_T18), .b(diff), .p(P0_comb));
    
    // P1 = S_D ^ P0 (using delayed S_D aligned with TD[])
    wire [15:0] P1;
    assign P1 = S_D_d2 ^ P0_comb;
    
    // Stage 2: Register outputs at cycle 2 (when TD[] and P0_comb ready)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out    <= 1'b0;
            codeword_out <= 304'b0;
        end else begin
            valid_out <= valid_d2;
            if (valid_d2) begin
                codeword_out <= {data_d2, P0_comb, P1};
            end
        end
    end

endmodule
