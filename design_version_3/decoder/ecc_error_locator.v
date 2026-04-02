// =============================================================================
//
//  Module      : ecc_error_locator
//  Description : Top-level Double-Bit Error (DBE) locator for a (19,17)
//                GF(2^16) ECC code.
//
//  Receives syndromes S0 and S1, computes the Hamming weight of S0, and
//  dispatches to one of three sublocator modules:
//
//    weight(S0) = 2 : ecc_eloc_weight2 — two single-bit errors in data/P0
//    weight(S0) = 1 : ecc_eloc_weight1 — one data error + one P1 error
//    weight(S0) = 0 : ecc_eloc_weight0 — identical errors in two symbols
//
//  Each sublocator runs combinationally in parallel.  The top-level gates
//  each sublocator's "found" output based on the actual S0 weight.
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_error_locator (
    input         clk,
    input         rst_n,
    input         valid_in,
    input  [15:0] S0,
    input  [15:0] S1,

    output        valid_out,
    output        no_error,

    // --- Weight-2 result ---
    output reg        dbe_w2_found,
    output reg [4:0]  dbe_w2_loc0,
    output reg [4:0]  dbe_w2_loc1,
    output reg [15:0] dbe_w2_err0,
    output reg [15:0] dbe_w2_err1,

    // --- Weight-1 result ---
    output reg        dbe_w1_found,
    output reg [4:0]  dbe_w1_loc0,
    output reg [15:0] dbe_w1_err0,
    output reg [15:0] dbe_w1_err1,

    // --- Weight-0 result ---
    output reg        dbe_w0_found,
    output reg [4:0]  dbe_w0_loc0,
    output reg [4:0]  dbe_w0_loc1,
    output reg [15:0] dbe_w0_err
);

    // -------------------------------------------------------------------------
    //  Valid & No-Error (combinational pass-through)
    // -------------------------------------------------------------------------

    assign valid_out = valid_in;
    assign no_error  = (S0 == 16'h0000) && (S1 == 16'h0000);

    // -------------------------------------------------------------------------
    //  Hamming Weight of S0
    // -------------------------------------------------------------------------

    wire [4:0] s0_weight;

    assign s0_weight = S0[0]  + S0[1]  + S0[2]  + S0[3]
                     + S0[4]  + S0[5]  + S0[6]  + S0[7]
                     + S0[8]  + S0[9]  + S0[10] + S0[11]
                     + S0[12] + S0[13] + S0[14] + S0[15];

    // -------------------------------------------------------------------------
    //  Syndrome Splitter (for weight-2 path)
    //  Isolate lowest set bit: Ej0 = S0 & (-S0), Ej1 = S0 ^ Ej0
    // -------------------------------------------------------------------------

    wire [15:0] Ej0_w2 = S0 & (~S0 + 16'h0001);
    wire [15:0] Ej1_w2 = S0 ^ Ej0_w2;

    // -------------------------------------------------------------------------
    //  Sublocator instances (all run in parallel, combinationally)
    // -------------------------------------------------------------------------

    wire        w2_found;
    wire [4:0]  w2_loc0, w2_loc1;
    wire [15:0] w2_err0, w2_err1;

    ecc_eloc_weight2 u_weight2 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .Ej0       (Ej0_w2),
        .Ej1       (Ej1_w2),
        .S1        (S1),
        .found     (w2_found),
        .loc0      (w2_loc0),
        .loc1      (w2_loc1),
        .err0      (w2_err0),
        .err1      (w2_err1)
    );

    wire        w1_found;
    wire [4:0]  w1_loc0;
    wire [15:0] w1_err0, w1_err1;

    ecc_eloc_weight1 u_weight1 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .S0        (S0),
        .S1        (S1),
        .found     (w1_found),
        .loc0      (w1_loc0),
        .err0      (w1_err0),
        .err1      (w1_err1)
    );

    wire        w0_found;
    wire [4:0]  w0_loc0, w0_loc1;
    wire [15:0] w0_err;

    ecc_eloc_weight0 u_weight0 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .S1        (S1),
        .found     (w0_found),
        .loc0      (w0_loc0),
        .loc1      (w0_loc1),
        .err       (w0_err)
    );

    // -------------------------------------------------------------------------
    //  Output gating — enable each path only for the matching S0 weight
    // -------------------------------------------------------------------------

    always @(*) begin
        dbe_w2_found = 1'b0;
        dbe_w2_loc0  = 5'd0;
        dbe_w2_loc1  = 5'd0;
        dbe_w2_err0  = 16'h0000;
        dbe_w2_err1  = 16'h0000;

        if (s0_weight == 5'd2) begin
            dbe_w2_found = w2_found;
            dbe_w2_loc0  = w2_loc0;
            dbe_w2_loc1  = w2_loc1;
            dbe_w2_err0  = w2_err0;
            dbe_w2_err1  = w2_err1;
        end
    end

    always @(*) begin
        dbe_w1_found = 1'b0;
        dbe_w1_loc0  = 5'd0;
        dbe_w1_err0  = 16'h0000;
        dbe_w1_err1  = 16'h0000;

        if (s0_weight == 5'd1) begin
            dbe_w1_found = w1_found;
            dbe_w1_loc0  = w1_loc0;
            dbe_w1_err0  = w1_err0;
            dbe_w1_err1  = w1_err1;
        end
    end

    always @(*) begin
        dbe_w0_found = 1'b0;
        dbe_w0_loc0  = 5'd0;
        dbe_w0_loc1  = 5'd0;
        dbe_w0_err   = 16'h0000;

        if ((s0_weight == 5'd0) && (S1 != 16'h0000)) begin
            dbe_w0_found = w0_found;
            dbe_w0_loc0  = w0_loc0;
            dbe_w0_loc1  = w0_loc1;
            dbe_w0_err   = w0_err;
        end
    end

endmodule
