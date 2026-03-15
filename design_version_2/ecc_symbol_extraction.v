`timescale 1ns / 1ps

module ecc_symbol_extract(
    input  [303:0] codeword_in,

    output [15:0] S0,
    output [15:0] S1,
    output [15:0] S2,
    output [15:0] S3,
    output [15:0] S4,
    output [15:0] S5,
    output [15:0] S6,
    output [15:0] S7,
    output [15:0] S8,
    output [15:0] S9,
    output [15:0] S10,
    output [15:0] S11,
    output [15:0] S12,
    output [15:0] S13,
    output [15:0] S14,
    output [15:0] S15,
    output [15:0] S16,
    output [15:0] P0,
    output [15:0] P1
);

assign S0  = codeword_in[303:288];
assign S1  = codeword_in[287:272];
assign S2  = codeword_in[271:256];
assign S3  = codeword_in[255:240];
assign S4  = codeword_in[239:224];
assign S5  = codeword_in[223:208];
assign S6  = codeword_in[207:192];
assign S7  = codeword_in[191:176];
assign S8  = codeword_in[175:160];
assign S9  = codeword_in[159:144];
assign S10 = codeword_in[143:128];
assign S11 = codeword_in[127:112];
assign S12 = codeword_in[111:96];
assign S13 = codeword_in[95:80];
assign S14 = codeword_in[79:64];
assign S15 = codeword_in[63:48];
assign S16 = codeword_in[47:32];
assign P0 = codeword_in[31:16]; // P0
assign P1 = codeword_in[15:0];  // P1

endmodule