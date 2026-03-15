`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Bhushan Kiran Munoli
//
// Module Name: ecc_error_corrector
// Project Name: ECC implementation for HBM4
//
// Description:
//   Error corrector for DBB-ECC RS16(19,17).
//   Receives the 19 raw codeword symbols C0..C18 plus the correction
//   selectors and error values from the decision/locator pipeline,
//   and outputs the 17 corrected data symbols (272 bits).
//
//   Correction modes (mutually exclusive, driven by decision logic):
//     use_sse    - Single Symbol Error: XOR sse_error into symbol sse_location
//     use_dbe_w2 - DBE weight-2: two SBE errors in two different symbols
//     use_dbe_w1 - DBE weight-1: one error in a data symbol, one in P1 (C18)
//     use_dbe_w0 - DBE weight-0: identical SBE errors in two symbols (cancel
//                  in S0 but detectable via S1)
//
//   Only data symbols C0..C16 are in data_out.
//   Parity symbols C17 (P0) and C18 (P1) are corrected internally if needed
//   but are not forwarded to data_out.
//
//////////////////////////////////////////////////////////////////////////////////

module ecc_error_corrector (
    // Raw codeword symbols
    input  wire [15:0] C0,
    input  wire [15:0] C1,
    input  wire [15:0] C2,
    input  wire [15:0] C3,
    input  wire [15:0] C4,
    input  wire [15:0] C5,
    input  wire [15:0] C6,
    input  wire [15:0] C7,
    input  wire [15:0] C8,
    input  wire [15:0] C9,
    input  wire [15:0] C10,
    input  wire [15:0] C11,
    input  wire [15:0] C12,
    input  wire [15:0] C13,
    input  wire [15:0] C14,
    input  wire [15:0] C15,
    input  wire [15:0] C16,
    input  wire [15:0] C17,   // P0
    input  wire [15:0] C18,   // P1

    // SSE correction inputs
    input  wire        use_sse,
    input  wire [4:0]  sse_location,   // 0-18
    input  wire [15:0] sse_error,      // = S0

    // DBE weight=2 correction inputs
    input  wire        use_dbe_w2,
    input  wire [4:0]  dbe_w2_loc0,
    input  wire [4:0]  dbe_w2_loc1,
    input  wire [15:0] dbe_w2_err0,
    input  wire [15:0] dbe_w2_err1,

    // DBE weight=1 correction inputs
    input  wire        use_dbe_w1,
    input  wire [4:0]  dbe_w1_loc0,   // data symbol location
    input  wire [15:0] dbe_w1_err0,   // error pattern in data symbol
    input  wire [15:0] dbe_w1_err1,   // error pattern in P1 (C18)

    // DBE weight=0 correction inputs
    input  wire        use_dbe_w0,
    input  wire [4:0]  dbe_w0_loc0,
    input  wire [4:0]  dbe_w0_loc1,
    input  wire [15:0] dbe_w0_err,

    // Corrected data output (17 data symbols only)
    output wire [271:0] data_out
);

    // Internal array holding all 19 corrected symbols
    reg [15:0] D [0:18];

    integer idx;
    always @(*) begin
        // Default: pass through unchanged
        D[0]  = C0;   D[1]  = C1;   D[2]  = C2;   D[3]  = C3;
        D[4]  = C4;   D[5]  = C5;   D[6]  = C6;   D[7]  = C7;
        D[8]  = C8;   D[9]  = C9;   D[10] = C10;  D[11] = C11;
        D[12] = C12;  D[13] = C13;  D[14] = C14;  D[15] = C15;
        D[16] = C16;  D[17] = C17;  D[18] = C18;

        if (use_sse) begin
            // Single Symbol Error: flip the full symbol at sse_location
            if (sse_location <= 5'd18)
                D[sse_location] = D[sse_location] ^ sse_error;
        end
        else if (use_dbe_w2) begin
            // Double Bit Error, weight-2 S0: two SBEs in two distinct symbols
            if (dbe_w2_loc0 <= 5'd18)
                D[dbe_w2_loc0] = D[dbe_w2_loc0] ^ dbe_w2_err0;
            if (dbe_w2_loc1 <= 5'd18)
                D[dbe_w2_loc1] = D[dbe_w2_loc1] ^ dbe_w2_err1;
        end
        else if (use_dbe_w1) begin
            // Double Bit Error, weight-1 S0: one SBE in a data symbol, one in P1
            if (dbe_w1_loc0 <= 5'd18)
                D[dbe_w1_loc0] = D[dbe_w1_loc0] ^ dbe_w1_err0;
            D[18] = D[18] ^ dbe_w1_err1;   // P1 correction
        end
        else if (use_dbe_w0) begin
            // Double Bit Error, weight-0 S0: identical SBEs cancelling in S0
            if (dbe_w0_loc0 <= 5'd18)
                D[dbe_w0_loc0] = D[dbe_w0_loc0] ^ dbe_w0_err;
            if (dbe_w0_loc1 <= 5'd18)
                D[dbe_w0_loc1] = D[dbe_w0_loc1] ^ dbe_w0_err;
        end
    end

    // Output: only the 17 data symbols (D0..D16)
    assign data_out = { D[0],  D[1],  D[2],  D[3],  D[4],  D[5],  D[6],  D[7],
                        D[8],  D[9],  D[10], D[11], D[12], D[13], D[14], D[15],
                        D[16] };

endmodule 