// =============================================================================
//
//  Module      : ecc_decision_logic
//  Description : Priority arbitration and status flags for the ECC decoder.
//
//  Correction priority (highest first): dbe_w2 > dbe_w1 > dbe_w0
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_decision_logic (
    input  wire no_error,
    input  wire dbe_w2_found,
    input  wire dbe_w1_found,
    input  wire dbe_w0_found,

    output wire use_dbe_w2,
    output wire use_dbe_w1,
    output wire use_dbe_w0,

    output wire error_detected,
    output wire error_corrected,
    output wire multi_bit_error,
    output wire uncorrectable
);

    assign use_dbe_w2 = dbe_w2_found;
    assign use_dbe_w1 = dbe_w1_found & ~use_dbe_w2;
    assign use_dbe_w0 = dbe_w0_found & ~use_dbe_w2 & ~use_dbe_w1;

    assign error_detected  = ~no_error;
    assign error_corrected = use_dbe_w2 | use_dbe_w1 | use_dbe_w0;
    assign multi_bit_error = use_dbe_w2 | use_dbe_w1 | use_dbe_w0;
    assign uncorrectable   = ~no_error & ~error_corrected;

endmodule