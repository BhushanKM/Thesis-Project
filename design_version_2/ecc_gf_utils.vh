// =============================================================================
//
//  File        : ecc_gf_utils.vh
//  Description : Shared GF(2^16) helper functions for the ECC error locator.
//
//  Contains:
//    - t_const      : T-coefficient lookup (alpha powers for each symbol)
//    - gf_mul_func  : GF(2^16) multiplication (elaboration-time)
//    - gf_inv_func  : GF(2^16) multiplicative inverse (elaboration-time)
//
//  Primitive polynomial: x^16 + x^5 + x^3 + x + 1  (POLY = 0x002B)
//
//  Usage: `include "ecc_gf_utils.vh" inside each module that needs these.
//
// =============================================================================

// -----------------------------------------------------------------------------
//  T-constant lookup
//
//  Returns the GF(2^16) element T[idx] used as the multiplier for symbol idx:
//    idx  0..16  —  data symbols   T[i] = alpha^(18-i)
//    idx 17      —  parity P0      T[17] = alpha^1
//    idx 18      —  parity P1      T[18] = alpha^0 = 1
// -----------------------------------------------------------------------------

function [15:0] t_const;
    input integer idx;
    begin
        case (idx)
            0:  t_const = 16'h00AC;     // alpha^18
            1:  t_const = 16'h0056;     // alpha^17
            2:  t_const = 16'h002B;     // alpha^16
            3:  t_const = 16'h8000;     // alpha^15
            4:  t_const = 16'h4000;     // alpha^14
            5:  t_const = 16'h2000;     // alpha^13
            6:  t_const = 16'h1000;     // alpha^12
            7:  t_const = 16'h0800;     // alpha^11
            8:  t_const = 16'h0400;     // alpha^10
            9:  t_const = 16'h0200;     // alpha^9
            10: t_const = 16'h0100;     // alpha^8
            11: t_const = 16'h0080;     // alpha^7
            12: t_const = 16'h0040;     // alpha^6
            13: t_const = 16'h0020;     // alpha^5
            14: t_const = 16'h0010;     // alpha^4
            15: t_const = 16'h0008;     // alpha^3
            16: t_const = 16'h0004;     // alpha^2
            17: t_const = 16'h0002;     // alpha^1  (P0)
            18: t_const = 16'h0001;     // alpha^0  (P1)
            default: t_const = 16'h0000;
        endcase
    end
endfunction

// -----------------------------------------------------------------------------
//  GF(2^16) multiplication — shift-and-add with reduction by POLY.
//  Used at elaboration time only (localparam evaluation).
// -----------------------------------------------------------------------------

function [15:0] gf_mul_func;
    input [15:0] a;
    input [15:0] b;
    reg [15:0] result;
    reg [15:0] shifted;
    integer i;
    begin
        result  = 16'h0000;
        shifted = a;
        for (i = 0; i < 16; i = i + 1) begin
            if (b[i])
                result = result ^ shifted;
            if (shifted[15])
                shifted = {shifted[14:0], 1'b0} ^ 16'h002B;
            else
                shifted = {shifted[14:0], 1'b0};
        end
        gf_mul_func = result;
    end
endfunction

// -----------------------------------------------------------------------------
//  GF(2^16) multiplicative inverse: a^(-1) = a^(2^16 - 2).
//  Computes a^2 * a^4 * a^8 * ... * a^(2^15) via repeated squaring.
//  Used at elaboration time only (localparam evaluation).
// -----------------------------------------------------------------------------

function [15:0] gf_inv_func;
    input [15:0] a;
    reg [15:0] r;
    reg [15:0] sq;
    integer i;
    begin
        r  = 16'h0001;
        sq = a;
        for (i = 0; i < 15; i = i + 1) begin
            sq = gf_mul_func(sq, sq);
            r  = gf_mul_func(r, sq);
        end
        gf_inv_func = r;
    end
endfunction
