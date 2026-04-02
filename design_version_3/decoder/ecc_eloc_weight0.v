// =============================================================================
//
//  Module      : ecc_eloc_weight0
//  Description : Weight-0 sublocator for the ECC error locator.
//
//  Handles the case where S0 = 0 and S1 != 0, meaning both errors are the
//  same 16-bit pattern applied to two different symbols (S0 cancels).
//
//      S1 = (T[i] ^ T[j]) * e
//      e  = inv(T[i] ^ T[j]) * S1
//
//  GF inverses are precomputed as elaboration-time constants.
//  If the computed e is one-hot, it is a valid single-bit error pattern.
//
//  Type 1: both in data — 136 multipliers (one per C(17,2) pair)
//  Type 2: data + P0    — 17 multipliers
//  Total: 153 GF multipliers
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_eloc_weight0 (
    input         clk,
    input         rst_n,
    input         valid_in,
    input  [15:0] S1,                   // Syndrome 1

    output reg        found,
    output reg [4:0]  loc0,
    output reg [4:0]  loc1,
    output reg [15:0] err
);

`include "ecc_gf_utils.vh"

    // -------------------------------------------------------------------------
    //  Type 1 — both errors in data symbols (136 pairs)
    //
    //  For each pair (i, j) with i < j:
    //      e = inv(T[i] ^ T[j]) * S1
    //  Match if e is one-hot.
    // -------------------------------------------------------------------------

    wire [15:0] t1_err [0:135];
    wire [135:0] t1_match;

    genvar g7i, g7j;
    generate
        for (g7i = 0; g7i < 17; g7i = g7i + 1) begin : GEN_W0T1_I
            for (g7j = g7i + 1; g7j < 17; g7j = g7j + 1) begin : GEN_W0T1_J
                localparam integer IDX =
                    g7i * 17 - (g7i * (g7i + 1)) / 2 + (g7j - g7i - 1);
                localparam [15:0] INV_TIJ =
                    gf_inv_func(t_const(g7i) ^ t_const(g7j));

                gf_mul_16_opt #(.REGISTERED(0)) u_mul (
                    .clk       (clk),
                    .rst_n     (rst_n),
                    .valid_in  (valid_in),
                    .a         (INV_TIJ),
                    .b         (S1),
                    .valid_out (),
                    .p         (t1_err[IDX])
                );

                assign t1_match[IDX] =
                    (t1_err[IDX] != 16'h0000) &&
                    ((t1_err[IDX] & (t1_err[IDX] - 16'h0001)) == 16'h0000);
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    //  Type 2 — one error in data symbol k, one in P0 (17 candidates)
    //
    //      e = inv(T[k] ^ T[17]) * S1
    // -------------------------------------------------------------------------

    wire [15:0] t2_err [0:16];
    wire [16:0] t2_match;

    generate
        for (g7i = 0; g7i < 17; g7i = g7i + 1) begin : GEN_W0T2
            localparam [15:0] INV_TIP0 =
                gf_inv_func(t_const(g7i) ^ t_const(17));

            gf_mul_16_opt #(.REGISTERED(0)) u_mul (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),
                .a         (INV_TIP0),
                .b         (S1),
                .valid_out (),
                .p         (t2_err[g7i])
            );

            assign t2_match[g7i] =
                (t2_err[g7i] != 16'h0000) &&
                ((t2_err[g7i] & (t2_err[g7i] - 16'h0001)) == 16'h0000);
        end
    endgenerate

    // -------------------------------------------------------------------------
    //  Priority selection: Type 1 (data-data) then Type 2 (data-P0)
    // -------------------------------------------------------------------------

    integer w0i, w0j, w0_flat;

    always @(*) begin
        found = 1'b0;
        loc0  = 5'd0;
        loc1  = 5'd0;
        err   = 16'h0000;

        // Type 1: data-data pairs
        w0_flat = 0;
        for (w0i = 0; w0i < 17; w0i = w0i + 1) begin
            for (w0j = w0i + 1; w0j < 17; w0j = w0j + 1) begin
                if (!found && t1_match[w0_flat]) begin
                    found = 1'b1;
                    loc0  = w0i[4:0];
                    loc1  = w0j[4:0];
                    err   = t1_err[w0_flat];
                end
                w0_flat = w0_flat + 1;
            end
        end

        // Type 2: data-P0 pairs (lower priority)
        for (w0i = 0; w0i < 17; w0i = w0i + 1) begin
            if (!found && t2_match[w0i]) begin
                found = 1'b1;
                loc0  = w0i[4:0];
                loc1  = 5'd17;
                err   = t2_err[w0i];
            end
        end
    end

endmodule
