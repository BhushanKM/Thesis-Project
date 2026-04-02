// =============================================================================
//
//  Module      : ecc_eloc_weight2
//  Description : Weight-2 sublocator for the ECC error locator.
//
//  Handles the case where Hamming weight of S0 = 2, meaning two single-bit
//  errors in separate data/P0 symbols contribute distinct bits to S0.
//
//  34 GF multipliers compute T[k]*Ej0 and T[k]*Ej1 for k = 0..16.
//  A priority-select search checks:
//    Type 1 — both errors in data:  T[i]*Ej0 ^ T[j]*Ej1 == S1  (136 pairs)
//    Type 2 — one in data, one P0:  T[k]*Ej == S1               (17 candidates)
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_eloc_weight2 (
    input         clk,
    input         rst_n,
    input         valid_in,
    input  [15:0] Ej0,                  // First  one-hot error pattern (low bit of S0)
    input  [15:0] Ej1,                  // Second one-hot error pattern (remaining bit)
    input  [15:0] S1,                   // Syndrome 1

    output reg        found,
    output reg [4:0]  loc0,
    output reg [4:0]  loc1,
    output reg [15:0] err0,
    output reg [15:0] err1
);

`include "ecc_gf_utils.vh"

    // -------------------------------------------------------------------------
    //  GF Multiplications: T[k] * Ej0,  T[k] * Ej1   for k = 0..16
    // -------------------------------------------------------------------------

    wire [15:0] T_Ej0 [0:16];
    wire [15:0] T_Ej1 [0:16];

    genvar gk;
    generate
        for (gk = 0; gk < 17; gk = gk + 1) begin : GEN_W2_MUL
            localparam [15:0] TK = t_const(gk);

            gf_mul_16_opt #(.REGISTERED(0)) u_ej0 (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),
                .a         (TK),
                .b         (Ej0),
                .valid_out (),
                .p         (T_Ej0[gk])
            );

            gf_mul_16_opt #(.REGISTERED(0)) u_ej1 (
                .clk       (clk),
                .rst_n     (rst_n),
                .valid_in  (valid_in),
                .a         (TK),
                .b         (Ej1),
                .valid_out (),
                .p         (T_Ej1[gk])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    //  Priority search: Type 1 (data-data) then Type 2 (data-P0)
    // -------------------------------------------------------------------------

    integer w2i, w2j;

    always @(*) begin
        found = 1'b0;
        loc0  = 5'd0;
        loc1  = 5'd0;
        err0  = 16'h0000;
        err1  = 16'h0000;

        // Type 1: both errors in data symbols (C(17,2) = 136 pairs)
        for (w2i = 0; w2i < 17; w2i = w2i + 1) begin
            for (w2j = w2i + 1; w2j < 17; w2j = w2j + 1) begin
                if (!found && ((T_Ej0[w2i] ^ T_Ej1[w2j]) == S1)) begin
                    found = 1'b1;
                    loc0  = w2i[4:0];
                    loc1  = w2j[4:0];
                    err0  = Ej0;
                    err1  = Ej1;
                end
                else if (!found && ((T_Ej1[w2i] ^ T_Ej0[w2j]) == S1)) begin
                    found = 1'b1;
                    loc0  = w2i[4:0];
                    loc1  = w2j[4:0];
                    err0  = Ej1;
                    err1  = Ej0;
                end
            end
        end

        // Type 2: one error in data, one in P0 (17 candidates, lower priority)
        for (w2i = 0; w2i < 17; w2i = w2i + 1) begin
            if (!found && (T_Ej0[w2i] == S1)) begin
                found = 1'b1;
                loc0  = w2i[4:0];
                loc1  = 5'd17;
                err0  = Ej0;
                err1  = Ej1;
            end
            else if (!found && (T_Ej1[w2i] == S1)) begin
                found = 1'b1;
                loc0  = w2i[4:0];
                loc1  = 5'd17;
                err0  = Ej1;
                err1  = Ej0;
            end
        end
    end

endmodule
