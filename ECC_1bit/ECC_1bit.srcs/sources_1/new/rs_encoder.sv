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

module rs_encoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] din,
    input  logic        din_valid,
    output logic [15:0] dout,
    output logic        dout_valid,
    output logic        ready
);
    // Generator: g(x) = (x+alpha^1)(x+alpha^2) = x^2 + 6x + 8
    localparam [15:0] G1 = 16'h0006; 
    localparam [15:0] G0 = 16'h0008;

    logic [15:0] r0, r1;
    logic [15:0] fb, m0, m1;
    logic [4:0]  count;

    gf_mul_16 mul0 (.a(fb), .b(G0), .p(m0));
    gf_mul_16 mul1 (.a(fb), .b(G1), .p(m1));

    assign fb = din ^ r1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {r0, r1, count} <= 0;
            ready <= 1;
        end else if (din_valid && count < 17) begin
            r1 <= r0 ^ m1;
            r0 <= m0;
            dout <= din;
            dout_valid <= 1;
            count <= count + 1;
            ready <= 0;
        end else if (count >= 17 && count < 19) begin
            dout <= (count == 17) ? r1 : r0;
            dout_valid <= 1;
            count <= count + 1;
            if (count == 18) begin 
                {r0, r1} <= 0;
                ready <= 1;
            end
        end else begin
            dout_valid <= 0;
            count <= 0;
        end
    end
endmodule