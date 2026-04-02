`timescale 1ns / 1ps

module ecc_encoder (
    input         clk,          // system clock
    input         rst_n,        // active low reset
    input         valid_in,     // input data valid
    input  [271:0] data_in,     // 17 symbols x 16 bits = 272 bits
    output reg    valid_out,    // output valid
    output reg [303:0] codeword_out, // 19 symbols x 16 bits = 304 bits
    inout         VDD,
    inout         VSS
);

    //--------------------------------------------------------------------------
    // Split input into 17 data symbols of 16 bits each
    //--------------------------------------------------------------------------
    wire [15:0] D [0:16];

    assign D[0]  = data_in[271:256];
    assign D[1]  = data_in[255:240];
    assign D[2]  = data_in[239:224];
    assign D[3]  = data_in[223:208];
    assign D[4]  = data_in[207:192];
    assign D[5]  = data_in[191:176];
    assign D[6]  = data_in[175:160];
    assign D[7]  = data_in[159:144];
    assign D[8]  = data_in[143:128];
    assign D[9]  = data_in[127:112];
    assign D[10] = data_in[111:96];
    assign D[11] = data_in[95:80];
    assign D[12] = data_in[79:64];
    assign D[13] = data_in[63:48];
    assign D[14] = data_in[47:32];
    assign D[15] = data_in[31:16];
    assign D[16] = data_in[15:0];

    //--------------------------------------------------------------------------
    // GF multiplication outputs: TD[i] = T[i] * D[i]
    //--------------------------------------------------------------------------
    wire [15:0] TD [0:16];
    wire [16:0] mult_valid_bus;

    genvar i;
    generate
        for (i = 0; i < 17; i = i + 1) begin : GEN_GF_MULT
            localparam [15:0] TI =
                (i == 0)  ? 16'h00AC : // alpha^18
                (i == 1)  ? 16'h0056 : // alpha^17
                (i == 2)  ? 16'h002B : // alpha^16
                (i == 3)  ? 16'h8000 : // alpha^15
                (i == 4)  ? 16'h4000 : // alpha^14
                (i == 5)  ? 16'h2000 : // alpha^13
                (i == 6)  ? 16'h1000 : // alpha^12
                (i == 7)  ? 16'h0800 : // alpha^11
                (i == 8)  ? 16'h0400 : // alpha^10
                (i == 9)  ? 16'h0200 : // alpha^9
                (i == 10) ? 16'h0100 : // alpha^8
                (i == 11) ? 16'h0080 : // alpha^7
                (i == 12) ? 16'h0040 : // alpha^6
                (i == 13) ? 16'h0020 : // alpha^5
                (i == 14) ? 16'h0010 : // alpha^4
                (i == 15) ? 16'h0008 : // alpha^3
                            16'h0004 ; // alpha^2

            gf_mul_16_opt u_gf_mul (
                .clk      (clk),
                .rst_n    (rst_n),
                .valid_in (valid_in),
                .a        (TI),
                .b        (D[i]),
                .valid_out(mult_valid_bus[i]),
                .p        (TD[i]),
                .VDD      (VDD),
                .VSS      (VSS)
            );
        end
    endgenerate

    //--------------------------------------------------------------------------
    // Since all multipliers are identical, their valid_out should align.
    // Use one as the representative pipeline-valid.
    //--------------------------------------------------------------------------
    wire mult_valid;
    assign mult_valid = mult_valid_bus[0];

    //--------------------------------------------------------------------------
    // P0 = XOR of all input data symbols
    //--------------------------------------------------------------------------
    wire [15:0] P0_comb;
    assign P0_comb = D[0]  ^ D[1]  ^ D[2]  ^ D[3]  ^ D[4]  ^
                     D[5]  ^ D[6]  ^ D[7]  ^ D[8]  ^ D[9]  ^
                     D[10] ^ D[11] ^ D[12] ^ D[13] ^ D[14] ^
                     D[15] ^ D[16];

    //--------------------------------------------------------------------------
    // P1 = XOR of all GF multiplication outputs
    //--------------------------------------------------------------------------
    wire [15:0] P1_comb;
    assign P1_comb = TD[0]  ^ TD[1]  ^ TD[2]  ^ TD[3]  ^ TD[4]  ^
                     TD[5]  ^ TD[6]  ^ TD[7]  ^ TD[8]  ^ TD[9]  ^
                     TD[10] ^ TD[11] ^ TD[12] ^ TD[13] ^ TD[14] ^
                     TD[15] ^ TD[16];

    //--------------------------------------------------------------------------
    // Delay input data and P0 by 1 cycle to align with multiplier pipeline
    //--------------------------------------------------------------------------
    reg [271:0] data_in_d1;
    reg [15:0]  P0_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_d1 <= 272'd0;
            P0_d1      <= 16'd0;
        end
        else if (valid_in) begin
            data_in_d1 <= data_in;
            P0_d1      <= P0_comb;
        end
    end

    //--------------------------------------------------------------------------
    // Output register stage
    // valid_out follows multiplier valid
    // codeword_out updates only when aligned valid is present
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out    <= 1'b0;
            codeword_out <= 304'd0;
        end
        else begin
            valid_out <= mult_valid;

            if (mult_valid) begin
                // Codeword = [D0, D1, ..., D16, P0, P1]
                codeword_out <= {data_in_d1, P0_d1, P1_comb};
            end
        end
    end

endmodule