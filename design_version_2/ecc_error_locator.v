`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Bhushan Kiran Munoli
//
// Module Name: ecc_error_locator
// Project Name: ECC implementation for HBM4 / HBM3 DBB-ECC
//
// Description:
//   Error locator block for split ECC decoder architecture.
//   Responsibilities:
//   1. Classify syndrome by S0 weight
//   2. Single Symbol Error (SSE) location
//   3. Double Bit Error (DBE) locator for:
//      - weight = 2
//      - weight = 1
//      - weight = 0
//
// Notes:
//   - Pure Verilog
//   - Uses gf_mul_16_opt for locator-side GF multiplies
//   - valid_out is passed through from valid_in, so S0/S1 must already be aligned
//
//////////////////////////////////////////////////////////////////////////////////

module ecc_error_locator(
    input         clk,
    input         rst_n,
    input         valid_in,
    input  [15:0] S0,
    input  [15:0] S1,

    output        valid_out,
    output        no_error,

    output reg        sse_found,
    output reg [4:0]  sse_location,
    output reg [15:0] sse_error,

    output reg        dbe_w2_found,
    output reg [4:0]  dbe_w2_loc0,
    output reg [4:0]  dbe_w2_loc1,
    output reg [15:0] dbe_w2_err0,
    output reg [15:0] dbe_w2_err1,

    output reg        dbe_w1_found,
    output reg [4:0]  dbe_w1_loc0,
    output reg [15:0] dbe_w1_err0,
    output reg [15:0] dbe_w1_err1,

    output reg        dbe_w0_found,
    output reg [4:0]  dbe_w0_loc0,
    output reg [4:0]  dbe_w0_loc1,
    output reg [15:0] dbe_w0_err
);

    //--------------------------------------------------------------------------
    // T constants helper
    //--------------------------------------------------------------------------
    function [15:0] t_const;
        input integer idx;
        begin
            case (idx)
                0:  t_const = 16'h00AC; // alpha^18
                1:  t_const = 16'h0056; // alpha^17
                2:  t_const = 16'h002B; // alpha^16
                3:  t_const = 16'h8000; // alpha^15
                4:  t_const = 16'h4000; // alpha^14
                5:  t_const = 16'h2000; // alpha^13
                6:  t_const = 16'h1000; // alpha^12
                7:  t_const = 16'h0800; // alpha^11
                8:  t_const = 16'h0400; // alpha^10
                9:  t_const = 16'h0200; // alpha^9
                10: t_const = 16'h0100; // alpha^8
                11: t_const = 16'h0080; // alpha^7
                12: t_const = 16'h0040; // alpha^6
                13: t_const = 16'h0020; // alpha^5
                14: t_const = 16'h0010; // alpha^4
                15: t_const = 16'h0008; // alpha^3
                16: t_const = 16'h0004; // alpha^2
                17: t_const = 16'h0002; // alpha^1 (P0)
                18: t_const = 16'h0001; // alpha^0 (P1)
                default: t_const = 16'h0000;
            endcase
        end
    endfunction

    //--------------------------------------------------------------------------
    // valid / no_error
    //--------------------------------------------------------------------------
    assign valid_out = valid_in;
    assign no_error  = (S0 == 16'h0000) && (S1 == 16'h0000);

    //--------------------------------------------------------------------------
    // COUNT "1"s IN S0 (Hamming Weight)
    //--------------------------------------------------------------------------
                            // wire [4:0] s0_weight;
                            // wire weight_is_0;
                            // wire weight_is_1;
                            // wire weight_is_2;

                            // assign s0_weight = S0[0]  + S0[1]  + S0[2]  + S0[3]  +
                            //                 S0[4]  + S0[5]  + S0[6]  + S0[7]  +
                            //                 S0[8]  + S0[9]  + S0[10] + S0[11] +
                            //                 S0[12] + S0[13] + S0[14] + S0[15];

                            // assign weight_is_0 = (s0_weight == 5'd0);
                            // assign weight_is_1 = (s0_weight == 5'd1);
                            // assign weight_is_2 = (s0_weight == 5'd2);

    wire [4:0] s0_weight;
    assign s0_weight = S0[0]  + S0[1]  + S0[2]  + S0[3]  + S0[4]  + S0[5]  + S0[6]  + S0[7]  + S0[8]  + S0[9]  + S0[10] + S0[11] + S0[12] + S0[13] + S0[14] + S0[15];

    //--------------------------------------------------------------------------
    // SSE LOCATOR
    // For SSE: Ti * S0 XOR S1 = 0 gives error location i
    // Error pattern = S0
    //--------------------------------------------------------------------------

    wire [19*16-1:0] T_S0_bus;
    wire [18:0]      sse_match;

    genvar gsse;
    generate
        for (gsse = 0; gsse < 19; gsse = gsse + 1) begin : GEN_SSE
            localparam [15:0] TI_SSE = t_const(gsse);

            gf_mul_16_opt u_mul_sse (
                .a(TI_SSE),
                .b(S0),
                .p(T_S0_bus[16*gsse + 15 : 16*gsse])
            );

            assign sse_match[gsse] =
                ((T_S0_bus[16*gsse + 15 : 16*gsse] ^ S1) == 16'h0000);
        end
    endgenerate

    integer ksse;
    always @(*) begin
        sse_found    = 1'b0;
        sse_location = 5'd31;
        sse_error    = S0;

        if (S0 != 16'h0000) begin
            for (ksse = 0; ksse < 19; ksse = ksse + 1) begin
                if (!sse_found && sse_match[ksse]) begin
                    sse_found    = 1'b1;
                    sse_location = ksse[4:0];
                    sse_error    = S0;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // DBE LOCATOR - SYNDROME SPLITTER (for weight=2)
    // Split S0 into two SBE patterns when weight=2
    //--------------------------------------------------------------------------

    reg [15:0] Ej0_w2;
    reg [15:0] Ej1_w2;

    always @(*) begin
        Ej0_w2 = 16'h0000;
        Ej1_w2 = 16'h0000;

        if (S0[0])       Ej0_w2 = 16'h0001;
        else if (S0[1])  Ej0_w2 = 16'h0002;
        else if (S0[2])  Ej0_w2 = 16'h0004;
        else if (S0[3])  Ej0_w2 = 16'h0008;
        else if (S0[4])  Ej0_w2 = 16'h0010;
        else if (S0[5])  Ej0_w2 = 16'h0020;
        else if (S0[6])  Ej0_w2 = 16'h0040;
        else if (S0[7])  Ej0_w2 = 16'h0080;
        else if (S0[8])  Ej0_w2 = 16'h0100;
        else if (S0[9])  Ej0_w2 = 16'h0200;
        else if (S0[10]) Ej0_w2 = 16'h0400;
        else if (S0[11]) Ej0_w2 = 16'h0800;
        else if (S0[12]) Ej0_w2 = 16'h1000;
        else if (S0[13]) Ej0_w2 = 16'h2000;
        else if (S0[14]) Ej0_w2 = 16'h4000;
        else if (S0[15]) Ej0_w2 = 16'h8000;

        Ej1_w2 = S0 ^ Ej0_w2;
    end

    //--------------------------------------------------------------------------
    // DBE SUBLOCATOR 1 (weight=2): Type 1 & Type 2
    //--------------------------------------------------------------------------

    wire [17*16-1:0] T_Ej0_bus;
    wire [17*16-1:0] T_Ej1_bus;

    genvar gw2m;
    generate
        for (gw2m = 0; gw2m < 17; gw2m = gw2m + 1) begin : GEN_W2_MUL
            localparam [15:0] TI_W2 = t_const(gw2m);

            gf_mul_16_opt u_mul_ej0 (
                .a(TI_W2),
                .b(Ej0_w2),
                .p(T_Ej0_bus[16*gw2m + 15 : 16*gw2m])
            );

            gf_mul_16_opt u_mul_ej1 (
                .a(TI_W2),
                .b(Ej1_w2),
                .p(T_Ej1_bus[16*gw2m + 15 : 16*gw2m])
            );
        end
    endgenerate

    // 136 pairs total for 17 choose 2
    wire [135:0] type1_match_a;
    wire [135:0] type1_match_b;
    wire [136*5-1:0] type1_loc0_bus;
    wire [136*5-1:0] type1_loc1_bus;

    genvar gi0, gi1;
    generate
        for (gi0 = 0; gi0 < 17; gi0 = gi0 + 1) begin : GEN_TYPE1_OUTER
            for (gi1 = gi0 + 1; gi1 < 17; gi1 = gi1 + 1) begin : GEN_TYPE1_INNER
                localparam integer PIDX =
                    gi0 * 17 - (gi0 * (gi0 + 1)) / 2 + (gi1 - gi0 - 1);

                wire [15:0] te0_i;
                wire [15:0] te1_i;
                wire [15:0] te0_j;
                wire [15:0] te1_j;

                assign te0_i = T_Ej0_bus[16*gi0 + 15 : 16*gi0];
                assign te1_i = T_Ej1_bus[16*gi0 + 15 : 16*gi0];
                assign te0_j = T_Ej0_bus[16*gi1 + 15 : 16*gi1];
                assign te1_j = T_Ej1_bus[16*gi1 + 15 : 16*gi1];

                assign type1_match_a[PIDX] = ((te0_i ^ te1_j ^ S1) == 16'h0000);
                assign type1_match_b[PIDX] = ((te1_i ^ te0_j ^ S1) == 16'h0000);

                assign type1_loc0_bus[5*PIDX + 4 : 5*PIDX] = gi0[4:0];
                assign type1_loc1_bus[5*PIDX + 4 : 5*PIDX] = gi1[4:0];
            end
        end
    endgenerate

    // Type 2: one error in data, one in P0
    wire [16:0] type2_match_a;
    wire [16:0] type2_match_b;

    genvar gt2;
    generate
        for (gt2 = 0; gt2 < 17; gt2 = gt2 + 1) begin : GEN_TYPE2
            wire [15:0] te0;
            wire [15:0] te1;

            assign te0 = T_Ej0_bus[16*gt2 + 15 : 16*gt2];
            assign te1 = T_Ej1_bus[16*gt2 + 15 : 16*gt2];

            assign type2_match_a[gt2] = ((te0 ^ S1) == 16'h0000);
            assign type2_match_b[gt2] = ((te1 ^ S1) == 16'h0000);
        end
    endgenerate

    reg       type1_found;
    reg [4:0] type1_loc0_sel;
    reg [4:0] type1_loc1_sel;
    reg       type1_swap;

    integer p1;
    always @(*) begin
        type1_found    = 1'b0;
        type1_loc0_sel = 5'd0;
        type1_loc1_sel = 5'd0;
        type1_swap     = 1'b0;

        for (p1 = 0; p1 < 136; p1 = p1 + 1) begin
            if (!type1_found && type1_match_a[p1]) begin
                type1_found    = 1'b1;
                type1_loc0_sel = type1_loc0_bus[5*p1 + 4 : 5*p1];
                type1_loc1_sel = type1_loc1_bus[5*p1 + 4 : 5*p1];
                type1_swap     = 1'b0;
            end
            else if (!type1_found && type1_match_b[p1]) begin
                type1_found    = 1'b1;
                type1_loc0_sel = type1_loc0_bus[5*p1 + 4 : 5*p1];
                type1_loc1_sel = type1_loc1_bus[5*p1 + 4 : 5*p1];
                type1_swap     = 1'b1;
            end
        end
    end

    reg       type2_found;
    reg [4:0] type2_loc0_sel;
    reg       type2_swap;

    integer p2;
    always @(*) begin
        type2_found    = 1'b0;
        type2_loc0_sel = 5'd0;
        type2_swap     = 1'b0;

        for (p2 = 0; p2 < 17; p2 = p2 + 1) begin
            if (!type2_found && type2_match_a[p2]) begin
                type2_found    = 1'b1;
                type2_loc0_sel = p2[4:0];
                type2_swap     = 1'b0;
            end
            else if (!type2_found && type2_match_b[p2]) begin
                type2_found    = 1'b1;
                type2_loc0_sel = p2[4:0];
                type2_swap     = 1'b1;
            end
        end
    end

    always @(*) begin
        dbe_w2_found = 1'b0;
        dbe_w2_loc0  = 5'd0;
        dbe_w2_loc1  = 5'd0;
        dbe_w2_err0  = 16'h0000;
        dbe_w2_err1  = 16'h0000;

        if (weight_is_2) begin
            if (type1_found) begin
                dbe_w2_found = 1'b1;
                dbe_w2_loc0  = type1_loc0_sel;
                dbe_w2_loc1  = type1_loc1_sel;
                dbe_w2_err0  = type1_swap ? Ej1_w2 : Ej0_w2;
                dbe_w2_err1  = type1_swap ? Ej0_w2 : Ej1_w2;
            end
            else if (type2_found) begin
                dbe_w2_found = 1'b1;
                dbe_w2_loc0  = type2_loc0_sel;
                dbe_w2_loc1  = 5'd17;   // P0
                dbe_w2_err0  = type2_swap ? Ej1_w2 : Ej0_w2;
                dbe_w2_err1  = type2_swap ? Ej0_w2 : Ej1_w2;
            end
        end
    end

    //--------------------------------------------------------------------------
    // DBE SUBLOCATOR 2 (weight=1): Type 3 - one in data, one in P1
    //--------------------------------------------------------------------------

    wire [271:0]   type3_match;
    wire [272*5-1:0] type3_loc_bus;
    wire [272*4-1:0] type3_bit_bus;

    genvar gw1_loc, gw1_bit;
    generate
        for (gw1_loc = 0; gw1_loc < 17; gw1_loc = gw1_loc + 1) begin : GEN_TYPE3_LOC
            for (gw1_bit = 0; gw1_bit < 16; gw1_bit = gw1_bit + 1) begin : GEN_TYPE3_BIT
                localparam integer T3IDX = gw1_loc * 16 + gw1_bit;
                localparam [15:0]  TI_W1 = t_const(gw1_loc);

                wire [15:0] t_s0_loc;
                wire [15:0] p1_onehot;

                gf_mul_16_opt u_mul_type3 (
                    .a(TI_W1),
                    .b(S0),
                    .p(t_s0_loc)
                );

                assign p1_onehot = (16'h0001 << gw1_bit);
                assign type3_match[T3IDX] = ((t_s0_loc ^ p1_onehot ^ S1) == 16'h0000);

                assign type3_loc_bus[5*T3IDX + 4 : 5*T3IDX] = gw1_loc[4:0];
                assign type3_bit_bus[4*T3IDX + 3 : 4*T3IDX] = gw1_bit[3:0];
            end
        end
    endgenerate

    integer p3;
    always @(*) begin
        dbe_w1_found = 1'b0;
        dbe_w1_loc0  = 5'd0;
        dbe_w1_err0  = 16'h0000;
        dbe_w1_err1  = 16'h0000;

        if (weight_is_1) begin
            for (p3 = 0; p3 < 272; p3 = p3 + 1) begin
                if (!dbe_w1_found && type3_match[p3]) begin
                    dbe_w1_found = 1'b1;
                    dbe_w1_loc0  = type3_loc_bus[5*p3 + 4 : 5*p3];
                    dbe_w1_err0  = S0;
                    dbe_w1_err1  = (16'h0001 << type3_bit_bus[4*p3 + 3 : 4*p3]);
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // DBE SUBLOCATOR 3 (weight=0): identical errors in two symbols
    //--------------------------------------------------------------------------

    // Type 1: both errors in data symbols (136 pairs)
    wire [136*16-1:0] t1_xor_val_bus;
    wire [136*5-1:0]  t1_pair_i_bus;
    wire [136*5-1:0]  t1_pair_j_bus;

    genvar gt1_i, gt1_j;
    generate
        for (gt1_i = 0; gt1_i < 17; gt1_i = gt1_i + 1) begin : GEN_T1_OUTER
            for (gt1_j = gt1_i + 1; gt1_j < 17; gt1_j = gt1_j + 1) begin : GEN_T1_INNER
                localparam integer T1IDX =
                    gt1_i * 17 - (gt1_i * (gt1_i + 1)) / 2 + (gt1_j - gt1_i - 1);

                localparam [15:0] TI = t_const(gt1_i);
                localparam [15:0] TJ = t_const(gt1_j);

                assign t1_xor_val_bus[16*T1IDX + 15 : 16*T1IDX] = TI ^ TJ;
                assign t1_pair_i_bus[5*T1IDX + 4 : 5*T1IDX]     = gt1_i[4:0];
                assign t1_pair_j_bus[5*T1IDX + 4 : 5*T1IDX]     = gt1_j[4:0];
            end
        end
    endgenerate

    wire [135:0]      t1_match;
    wire [136*16-1:0] t1_err_pattern_bus;

    genvar gt1_m, gt1_e;
    generate
        for (gt1_m = 0; gt1_m < 136; gt1_m = gt1_m + 1) begin : GEN_T1_MATCH
            wire [15:0] xor_val;
            wire [15:0] valid_e;

            assign xor_val = t1_xor_val_bus[16*gt1_m + 15 : 16*gt1_m];

            for (gt1_e = 0; gt1_e < 16; gt1_e = gt1_e + 1) begin : GEN_T1_E
                wire [15:0] t1_product;
                gf_mul_16_opt u_mul_t1 (
                    .a(xor_val),
                    .b(16'h0001 << gt1_e),
                    .p(t1_product)
                );
                assign valid_e[gt1_e] = (t1_product == S1);
            end

            reg [3:0] t1_found_bit;
            reg       t1_found_valid;
            integer   t1_eb;
            always @(*) begin
                t1_found_bit   = 4'd0;
                t1_found_valid = 1'b0;
                for (t1_eb = 0; t1_eb < 16; t1_eb = t1_eb + 1) begin
                    if (!t1_found_valid && valid_e[t1_eb]) begin
                        t1_found_valid = 1'b1;
                        t1_found_bit   = t1_eb[3:0];
                    end
                end
            end

            assign t1_match[gt1_m] = t1_found_valid;
            assign t1_err_pattern_bus[16*gt1_m + 15 : 16*gt1_m] = (16'h0001 << t1_found_bit);
        end
    endgenerate

    // Type 2: one error in data, one in P0
    wire [17*16-1:0] t2_xor_val_bus;

    genvar gt2_i2;
    generate
        for (gt2_i2 = 0; gt2_i2 < 17; gt2_i2 = gt2_i2 + 1) begin : GEN_T2_XOR
            localparam [15:0] TI2 = t_const(gt2_i2);
            localparam [15:0] TP0 = t_const(17);
            assign t2_xor_val_bus[16*gt2_i2 + 15 : 16*gt2_i2] = TI2 ^ TP0;
        end
    endgenerate

    wire [16:0]      t2_match;
    wire [17*16-1:0] t2_err_pattern_bus;

    genvar gt2_m2, gt2_e2;
    generate
        for (gt2_m2 = 0; gt2_m2 < 17; gt2_m2 = gt2_m2 + 1) begin : GEN_T2_MATCH
            wire [15:0] xor_val2;
            wire [15:0] valid_e2;

            assign xor_val2 = t2_xor_val_bus[16*gt2_m2 + 15 : 16*gt2_m2];

            for (gt2_e2 = 0; gt2_e2 < 16; gt2_e2 = gt2_e2 + 1) begin : GEN_T2_E
                wire [15:0] t2_product;
                gf_mul_16_opt u_mul_t2 (
                    .a(xor_val2),
                    .b(16'h0001 << gt2_e2),
                    .p(t2_product)
                );
                assign valid_e2[gt2_e2] = (t2_product == S1);
            end

            reg [3:0] t2_found_bit;
            reg       t2_found_valid;
            integer   t2_eb;
            always @(*) begin
                t2_found_bit   = 4'd0;
                t2_found_valid = 1'b0;
                for (t2_eb = 0; t2_eb < 16; t2_eb = t2_eb + 1) begin
                    if (!t2_found_valid && valid_e2[t2_eb]) begin
                        t2_found_valid = 1'b1;
                        t2_found_bit   = t2_eb[3:0];
                    end
                end
            end

            assign t2_match[gt2_m2] = t2_found_valid;
            assign t2_err_pattern_bus[16*gt2_m2 + 15 : 16*gt2_m2] = (16'h0001 << t2_found_bit);
        end
    endgenerate

    reg       t1_found;
    reg [4:0] t1_loc0_sel;
    reg [4:0] t1_loc1_sel;
    reg [15:0] t1_err_sel;

    integer pt1;
    always @(*) begin
        t1_found    = 1'b0;
        t1_loc0_sel = 5'd0;
        t1_loc1_sel = 5'd0;
        t1_err_sel  = 16'h0000;

        for (pt1 = 0; pt1 < 136; pt1 = pt1 + 1) begin
            if (!t1_found && t1_match[pt1]) begin
                t1_found    = 1'b1;
                t1_loc0_sel = t1_pair_i_bus[5*pt1 + 4 : 5*pt1];
                t1_loc1_sel = t1_pair_j_bus[5*pt1 + 4 : 5*pt1];
                t1_err_sel  = t1_err_pattern_bus[16*pt1 + 15 : 16*pt1];
            end
        end
    end

    reg       t2_found;
    reg [4:0] t2_loc0_sel;
    reg [15:0] t2_err_sel;

    integer pt2;
    always @(*) begin
        t2_found    = 1'b0;
        t2_loc0_sel = 5'd0;
        t2_err_sel  = 16'h0000;

        for (pt2 = 0; pt2 < 17; pt2 = pt2 + 1) begin
            if (!t2_found && t2_match[pt2]) begin
                t2_found    = 1'b1;
                t2_loc0_sel = pt2[4:0];
                t2_err_sel  = t2_err_pattern_bus[16*pt2 + 15 : 16*pt2];
            end
        end
    end

    always @(*) begin
        dbe_w0_found = 1'b0;
        dbe_w0_loc0  = 5'd0;
        dbe_w0_loc1  = 5'd0;
        dbe_w0_err   = 16'h0000;

        if (weight_is_0 && (S1 != 16'h0000)) begin
            if (t1_found) begin
                dbe_w0_found = 1'b1;
                dbe_w0_loc0  = t1_loc0_sel;
                dbe_w0_loc1  = t1_loc1_sel;
                dbe_w0_err   = t1_err_sel;
            end
            else if (t2_found) begin
                dbe_w0_found = 1'b1;
                dbe_w0_loc0  = t2_loc0_sel;
                dbe_w0_loc1  = 5'd17; // P0
                dbe_w0_err   = t2_err_sel;
            end
        end
    end

endmodule