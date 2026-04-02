// =============================================================================
//
//  Module      : ecc_eloc_weight1
//  Description : Weight-1 sublocator for the ECC error locator.
//
//  Handles the case where Hamming weight of S0 = 1, meaning one single-bit
//  error in a data symbol and one single-bit error in P1.
//
//  17 GF multipliers compute T[k] * S0 for k = 0..16.
//  For each location k, the inferred P1 error is:
//      p1_err = T[k]*S0 ^ S1
//  If p1_err is one-hot, location k is the data error and p1_err is the P1
//  error pattern.
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_eloc_weight1 (
    input         clk,
    input         rst_n,
    input         valid_in,
    input  [15:0] S0,                   // Syndrome 0 (weight = 1)
    input  [15:0] S1,                   // Syndrome 1

    output reg        found,
    output reg [4:0]  loc0,             // Data symbol location (0..16)
    output reg [15:0] err0,             // Data error pattern (= S0)
    output reg [15:0] err1              // P1 error pattern (one-hot)
);

`include "ecc_gf_utils.vh"

    // -------------------------------------------------------------------------
    //  GF Multiplications: T[k] * S0  for k = 0..16
    // -------------------------------------------------------------------------

    wire [15:0] T_S0 [0:16];

    genvar gk;
    generate
        for (gk = 0; gk < 17; gk = gk + 1) begin : GEN_W1_MUL
            localparam [15:0] TK = t_const(gk);

            gf_mul_16_opt #(.REGISTERED(0)) u_ts0 (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),
                .a         (TK),
                .b         (S0),
                .valid_out (),
                .p         (T_S0[gk])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    //  Priority search: find first location where inferred P1 error is one-hot
    // -------------------------------------------------------------------------

    integer w1i;
    reg [15:0] w1_p1_err;

    always @(*) begin
        found = 1'b0;
        loc0  = 5'd0;
        err0  = 16'h0000;
        err1  = 16'h0000;

        for (w1i = 0; w1i < 17; w1i = w1i + 1) begin
            w1_p1_err = T_S0[w1i] ^ S1;
            if (!found &&
                (w1_p1_err != 16'h0000) &&
                ((w1_p1_err & (w1_p1_err - 16'h0001)) == 16'h0000)) begin
                found = 1'b1;
                loc0  = w1i[4:0];
                err0  = S0;
                err1  = w1_p1_err;
            end
        end
    end

endmodule
