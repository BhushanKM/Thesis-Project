// =============================================================================
//
//  Module      : ecc_error_corrector
//  Description : Error corrector for DBE-ECC RS16(19,17).
//
//  Receives the 19 raw codeword symbols C0..C18 plus correction selectors
//  and error values from the decision/locator pipeline, and outputs the
//  17 corrected data symbols (272 bits).
//
//  Correction modes (mutually exclusive, driven by decision logic):
//    use_dbe_w2 — two SBE errors in two different data/P0 symbols (loc 0..17)
//    use_dbe_w1 — one error in a data symbol (loc 0..16), one in P1 (C18)
//    use_dbe_w0 — identical SBE errors in two data/P0 symbols (loc 0..17)
//
//  Only data symbols C0..C16 appear in data_out.
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_error_corrector (
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
    input  wire [15:0] C17,    // P0
    input  wire [15:0] C18,    // P1

    // DBE weight=2 correction inputs (loc 0..17)
    input  wire        use_dbe_w2,
    input  wire [4:0]  dbe_w2_loc0,
    input  wire [4:0]  dbe_w2_loc1,
    input  wire [15:0] dbe_w2_err0,
    input  wire [15:0] dbe_w2_err1,

    // DBE weight=1 correction inputs (data loc 0..16, P1 error separate)
    input  wire        use_dbe_w1,
    input  wire [4:0]  dbe_w1_loc0,
    input  wire [15:0] dbe_w1_err0,
    input  wire [15:0] dbe_w1_err1,

    // DBE weight=0 correction inputs (loc 0..17)
    input  wire        use_dbe_w0,
    input  wire [4:0]  dbe_w0_loc0,
    input  wire [4:0]  dbe_w0_loc1,
    input  wire [15:0] dbe_w0_err,

    output wire [271:0] data_out
);

    // -------------------------------------------------------------------------
    //  Per-symbol correction using explicit index comparison.
    //  Each symbol checks whether it is targeted by the active correction mode.
    // -------------------------------------------------------------------------

    reg [15:0] D [0:18];

    integer idx;

    always @(*) begin
        D[0]  = C0;   D[1]  = C1;   D[2]  = C2;   D[3]  = C3;
        D[4]  = C4;   D[5]  = C5;   D[6]  = C6;   D[7]  = C7;
        D[8]  = C8;   D[9]  = C9;   D[10] = C10;  D[11] = C11;
        D[12] = C12;  D[13] = C13;  D[14] = C14;  D[15] = C15;
        D[16] = C16;  D[17] = C17;  D[18] = C18;

        for (idx = 0; idx < 19; idx = idx + 1) begin
            if (use_dbe_w2) begin
                if (dbe_w2_loc0 == idx[4:0] && dbe_w2_loc0 <= 5'd17)
                    D[idx] = D[idx] ^ dbe_w2_err0;
                if (dbe_w2_loc1 == idx[4:0] && dbe_w2_loc1 <= 5'd17)
                    D[idx] = D[idx] ^ dbe_w2_err1;
            end
            else if (use_dbe_w1) begin
                if (dbe_w1_loc0 == idx[4:0] && dbe_w1_loc0 <= 5'd16)
                    D[idx] = D[idx] ^ dbe_w1_err0;
                if (idx == 18)
                    D[18] = D[18] ^ dbe_w1_err1;
            end
            else if (use_dbe_w0) begin
                if (dbe_w0_loc0 == idx[4:0] && dbe_w0_loc0 <= 5'd17)
                    D[idx] = D[idx] ^ dbe_w0_err;
                if (dbe_w0_loc1 == idx[4:0] && dbe_w0_loc1 <= 5'd17)
                    D[idx] = D[idx] ^ dbe_w0_err;
            end
        end
    end

    // -------------------------------------------------------------------------
    //  Output: 17 data symbols only (D0..D16), MSB-first matching encoder
    // -------------------------------------------------------------------------

    assign data_out = { D[0],  D[1],  D[2],  D[3],  D[4],  D[5],  D[6],  D[7],
                        D[8],  D[9],  D[10], D[11], D[12], D[13], D[14], D[15],
                        D[16] };

endmodule
