`timescale 1ns / 1ps

module ecc_symbol_extract (
    input  [303:0] codeword_in,

    output [15:0] C0,
    output [15:0] C1,
    output [15:0] C2,
    output [15:0] C3,
    output [15:0] C4,
    output [15:0] C5,
    output [15:0] C6,
    output [15:0] C7,
    output [15:0] C8,
    output [15:0] C9,
    output [15:0] C10,
    output [15:0] C11,
    output [15:0] C12,
    output [15:0] C13,
    output [15:0] C14,
    output [15:0] C15,
    output [15:0] C16,
    output [15:0] C17,
    output [15:0] C18
);

    assign C0  = codeword_in[303:288];
    assign C1  = codeword_in[287:272];
    assign C2  = codeword_in[271:256];
    assign C3  = codeword_in[255:240];
    assign C4  = codeword_in[239:224];
    assign C5  = codeword_in[223:208];
    assign C6  = codeword_in[207:192];
    assign C7  = codeword_in[191:176];
    assign C8  = codeword_in[175:160];
    assign C9  = codeword_in[159:144];
    assign C10 = codeword_in[143:128];
    assign C11 = codeword_in[127:112];
    assign C12 = codeword_in[111:96];
    assign C13 = codeword_in[95:80];
    assign C14 = codeword_in[79:64];
    assign C15 = codeword_in[63:48];
    assign C16 = codeword_in[47:32];
    assign C17 = codeword_in[31:16];
    assign C18 = codeword_in[15:0];

endmodule