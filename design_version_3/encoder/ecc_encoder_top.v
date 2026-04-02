// =============================================================================
//
//  Module      : ecc_encoder_top
//  Description : Top-level wrapper for the ECC encoder subsystem.
//
//  Provides a ready/valid interface around the RS16(19,17) encoder pipeline.
//  Accepts 272-bit data (17 × 16-bit symbols), produces a 304-bit codeword
//  (17 data + P0 + P1).
//
//  Pipeline latency: 2 clock cycles (GF multiplier register + output register).
//
//  Interface:
//    wr_valid / wr_ready  — input handshake (ready is always asserted since
//                           the encoder can accept data every cycle)
//    enc_valid / enc_codeword — output handshake with encoded codeword
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_encoder_top (
    input  wire         clk,
    input  wire         rst_n,

    // Write interface
    input  wire         wr_valid,
    input  wire [271:0] wr_data,
    output wire         wr_ready,

    // Encoded output
    output wire         enc_valid,
    output wire [303:0] enc_codeword
);

    // -------------------------------------------------------------------------
    //  The encoder pipeline is fully pipelined with no stalls — it can accept
    //  new data every clock cycle.  wr_ready is therefore always asserted.
    // -------------------------------------------------------------------------

    assign wr_ready = 1'b1;

    // -------------------------------------------------------------------------
    //  Encoder instance
    // -------------------------------------------------------------------------

    ecc_encoder u_encoder (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (wr_valid),
        .data_in      (wr_data),
        .valid_out    (enc_valid),
        .codeword_out (enc_codeword)
    );

endmodule
