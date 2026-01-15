`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 02:48:03 PM
// Design Name: 
// Module Name: gf_mul_16
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gf_mul_16 (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] p
);
    // MATLAB primpoly(16, 'min') = x^16 + x^5 + x^3 + x^1 + 1 (0x1002D)
    localparam [15:0] POLY = 16'h002D; 

    logic [15:0] tmp_a[16];
    logic [15:0] tmp_p[16];

    always_comb begin
        tmp_a[0] = a;
        tmp_p[0] = b[0] ? a : 16'h0;
        for (int i = 1; i < 16; i++) begin
            tmp_a[i] = tmp_a[i-1][15] ? (tmp_a[i-1] << 1) ^ POLY : (tmp_a[i-1] << 1);
            tmp_p[i] = b[i] ? tmp_p[i-1] ^ tmp_a[i] : tmp_p[i-1];
        end
    end
    assign p = tmp_p[15];
endmodule