// =============================================================================
//
//  Testbench : ecc_error_locator_tb
//  DUT       : ecc_error_locator (simplified, fully combinational)
//
//  Tests all three error-location paths:
//    Group 1 — No error (S0=0, S1=0)
//    Group 2 — Weight-2: two single-bit errors in two data symbols
//    Group 3 — Weight-2: one single-bit error in data + one in P0
//    Group 4 — Weight-1: one single-bit error in data + one in P1
//    Group 5 — Weight-0: identical single-bit error in two data symbols
//    Group 6 — Weight-0: identical single-bit error in data + P0
//    Group 7 — valid_out tracks valid_in (combinational pass-through)
//    Group 8 — No false positives (invalid / out-of-range syndromes)
//    Group 9 — Edge cases (adjacent symbols, MSB, max-distance pairs)
//
// =============================================================================

`timescale 1ns / 1ps

module ecc_error_locator_tb;

    // -------------------------------------------------------------------------
    //  DUT signals
    // -------------------------------------------------------------------------

    reg         clk;
    reg         rst_n;
    reg         valid_in;
    reg  [15:0] S0;
    reg  [15:0] S1;

    wire        valid_out;
    wire        no_error;

    wire        dbe_w2_found;
    wire [4:0]  dbe_w2_loc0;
    wire [4:0]  dbe_w2_loc1;
    wire [15:0] dbe_w2_err0;
    wire [15:0] dbe_w2_err1;

    wire        dbe_w1_found;
    wire [4:0]  dbe_w1_loc0;
    wire [15:0] dbe_w1_err0;
    wire [15:0] dbe_w1_err1;

    wire        dbe_w0_found;
    wire [4:0]  dbe_w0_loc0;
    wire [4:0]  dbe_w0_loc1;
    wire [15:0] dbe_w0_err;

    // -------------------------------------------------------------------------
    //  DUT instantiation
    // -------------------------------------------------------------------------

    ecc_error_locator uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in      (valid_in),
        .S0            (S0),
        .S1            (S1),
        .valid_out     (valid_out),
        .no_error      (no_error),
        .dbe_w2_found  (dbe_w2_found),
        .dbe_w2_loc0   (dbe_w2_loc0),
        .dbe_w2_loc1   (dbe_w2_loc1),
        .dbe_w2_err0   (dbe_w2_err0),
        .dbe_w2_err1   (dbe_w2_err1),
        .dbe_w1_found  (dbe_w1_found),
        .dbe_w1_loc0   (dbe_w1_loc0),
        .dbe_w1_err0   (dbe_w1_err0),
        .dbe_w1_err1   (dbe_w1_err1),
        .dbe_w0_found  (dbe_w0_found),
        .dbe_w0_loc0   (dbe_w0_loc0),
        .dbe_w0_loc1   (dbe_w0_loc1),
        .dbe_w0_err    (dbe_w0_err)
    );

    // -------------------------------------------------------------------------
    //  Clock generation
    // -------------------------------------------------------------------------

    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    //  Reference helper functions (must match RTL exactly)
    // -------------------------------------------------------------------------

    localparam [15:0] POLY = 16'h002B;

    function [15:0] t_const;
        input integer idx;
        begin
            case (idx)
                0:  t_const = 16'h00AC;
                1:  t_const = 16'h0056;
                2:  t_const = 16'h002B;
                3:  t_const = 16'h8000;
                4:  t_const = 16'h4000;
                5:  t_const = 16'h2000;
                6:  t_const = 16'h1000;
                7:  t_const = 16'h0800;
                8:  t_const = 16'h0400;
                9:  t_const = 16'h0200;
                10: t_const = 16'h0100;
                11: t_const = 16'h0080;
                12: t_const = 16'h0040;
                13: t_const = 16'h0020;
                14: t_const = 16'h0010;
                15: t_const = 16'h0008;
                16: t_const = 16'h0004;
                17: t_const = 16'h0002;
                18: t_const = 16'h0001;
                default: t_const = 16'h0000;
            endcase
        end
    endfunction

    function [15:0] gf_mul;
        input [15:0] a;
        input [15:0] b;
        reg [15:0] tmp;
        reg [15:0] result;
        integer k;
        begin
            tmp    = a;
            result = (b[0]) ? a : 16'h0000;
            for (k = 1; k < 16; k = k + 1) begin
                tmp = tmp[15] ? ({tmp[14:0], 1'b0} ^ POLY) : {tmp[14:0], 1'b0};
                result = result ^ (b[k] ? tmp : 16'h0000);
            end
            gf_mul = result;
        end
    endfunction

    // -------------------------------------------------------------------------
    //  Syndrome computation helpers
    //
    //  S0 = E_loc0 ^ E_loc1   (P1 errors do NOT contribute to S0)
    //  S1 = T[loc0]*E0 ^ T[loc1]*E1  (P0 contributes 0 to S1, P1 contributes E1)
    // -------------------------------------------------------------------------

    function [15:0] compute_s0;
        input integer loc0;
        input [15:0]  e0;
        input integer loc1;
        input [15:0]  e1;
        begin
            if (loc0 == 18)
                compute_s0 = e1;
            else if (loc1 == 18)
                compute_s0 = e0;
            else
                compute_s0 = e0 ^ e1;
        end
    endfunction

    function [15:0] compute_s1;
        input integer loc0;
        input [15:0]  e0;
        input integer loc1;
        input [15:0]  e1;
        reg [15:0] contrib0;
        reg [15:0] contrib1;
        begin
            if (loc0 == 17)
                contrib0 = 16'h0000;
            else if (loc0 == 18)
                contrib0 = e0;
            else
                contrib0 = gf_mul(t_const(loc0), e0);

            if (loc1 == 17)
                contrib1 = 16'h0000;
            else if (loc1 == 18)
                contrib1 = e1;
            else
                contrib1 = gf_mul(t_const(loc1), e1);

            compute_s1 = contrib0 ^ contrib1;
        end
    endfunction

    // -------------------------------------------------------------------------
    //  Test infrastructure
    // -------------------------------------------------------------------------

    integer pass_count;
    integer fail_count;
    integer test_num;
    integer i, j, b0, b1;

    // Apply syndromes and allow combinational settling.
    // DUT is fully combinational — outputs settle within #1 of input change.
    task apply_syndromes;
        input [15:0] s0_val;
        input [15:0] s1_val;
        begin
            @(posedge clk);
            valid_in = 1'b1;
            S0       = s0_val;
            S1       = s1_val;
            #1;
        end
    endtask

    // -------------------------------------------------------------------------
    //  Weight-2 checker: accepts any valid (loc,err) permutation
    // -------------------------------------------------------------------------
    task check_w2;
        input integer exp_loc0;
        input integer exp_loc1;
        input [15:0]  exp_err0;
        input [15:0]  exp_err1;
        begin
            if (dbe_w2_found !== 1'b1) begin
                $display("FAIL Test %0d: dbe_w2_found=0 (expected 1)", test_num);
                fail_count = fail_count + 1;
            end
            else if (((dbe_w2_loc0 == exp_loc0[4:0] && dbe_w2_loc1 == exp_loc1[4:0]) &&
                      (dbe_w2_err0 == exp_err0      && dbe_w2_err1 == exp_err1)) ||
                     ((dbe_w2_loc0 == exp_loc0[4:0] && dbe_w2_loc1 == exp_loc1[4:0]) &&
                      (dbe_w2_err0 == exp_err1      && dbe_w2_err1 == exp_err0)) ||
                     ((dbe_w2_loc0 == exp_loc1[4:0] && dbe_w2_loc1 == exp_loc0[4:0]) &&
                      (dbe_w2_err0 == exp_err0      && dbe_w2_err1 == exp_err1)) ||
                     ((dbe_w2_loc0 == exp_loc1[4:0] && dbe_w2_loc1 == exp_loc0[4:0]) &&
                      (dbe_w2_err0 == exp_err1      && dbe_w2_err1 == exp_err0))) begin
                $display("PASS Test %0d: loc0=%0d loc1=%0d err0=%h err1=%h",
                         test_num, dbe_w2_loc0, dbe_w2_loc1, dbe_w2_err0, dbe_w2_err1);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL Test %0d: Wrong loc/err. Got loc0=%0d loc1=%0d err0=%h err1=%h",
                         test_num, dbe_w2_loc0, dbe_w2_loc1, dbe_w2_err0, dbe_w2_err1);
                $display("              Expected locs {%0d,%0d} errs {%h,%h}",
                         exp_loc0, exp_loc1, exp_err0, exp_err1);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    //  Weight-0 checker: accepts any valid (loc) permutation
    // -------------------------------------------------------------------------
    task check_w0;
        input integer exp_loc0;
        input integer exp_loc1;
        input [15:0]  exp_err;
        begin
            if (dbe_w0_found !== 1'b1) begin
                $display("FAIL Test %0d: dbe_w0_found=0 (expected 1)", test_num);
                fail_count = fail_count + 1;
            end
            else if (((dbe_w0_loc0 == exp_loc0[4:0] && dbe_w0_loc1 == exp_loc1[4:0]) ||
                      (dbe_w0_loc0 == exp_loc1[4:0] && dbe_w0_loc1 == exp_loc0[4:0])) &&
                     dbe_w0_err == exp_err) begin
                $display("PASS Test %0d: loc0=%0d loc1=%0d err=%h",
                         test_num, dbe_w0_loc0, dbe_w0_loc1, dbe_w0_err);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL Test %0d: Wrong. Got loc0=%0d loc1=%0d err=%h  Expected locs {%0d,%0d} err=%h",
                         test_num, dbe_w0_loc0, dbe_w0_loc1, dbe_w0_err, exp_loc0, exp_loc1, exp_err);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    //  Main test sequence
    // =========================================================================

    initial begin
        $dumpfile("ecc_error_locator_tb.vcd");
        $dumpvars(0, ecc_error_locator_tb);

        clk        = 0;
        rst_n      = 0;
        valid_in   = 0;
        S0         = 16'h0000;
        S1         = 16'h0000;
        pass_count = 0;
        fail_count = 0;
        test_num   = 1;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // =============================================================
        // GROUP 1: NO ERROR (S0=0, S1=0)
        // =============================================================
        $display("\n====== GROUP 1: NO ERROR ======");

        $display("--- Test %0d: S0=0, S1=0 ---", test_num);
        apply_syndromes(16'h0000, 16'h0000);
        if (no_error === 1'b1 &&
            dbe_w0_found === 1'b0 &&
            dbe_w1_found === 1'b0 &&
            dbe_w2_found === 1'b0) begin
            $display("PASS Test %0d: no_error asserted, no DBE found", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: no_error=%b w0=%b w1=%b w2=%b",
                     test_num, no_error, dbe_w0_found, dbe_w1_found, dbe_w2_found);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // =============================================================
        // GROUP 2: WEIGHT-2 (two single-bit errors in two data symbols)
        //
        // Iterate over sampled (i, j, b0, b1) combinations where b0 != b1.
        // S0 = (1<<b0) ^ (1<<b1)  (weight 2)
        // S1 = T[i]*(1<<b0) ^ T[j]*(1<<b1)
        // =============================================================
        $display("\n====== GROUP 2: WEIGHT-2 (two data symbols) ======");

        for (i = 0; i < 17; i = i + 4) begin
            for (j = i + 1; j < 17; j = j + 4) begin
                for (b0 = 0; b0 < 16; b0 = b0 + 5) begin
                    b1 = (b0 + 3) % 16;
                    if (b0 != b1) begin : grp2_test
                        reg [15:0] e0, e1, s0_exp, s1_exp;
                        e0 = 16'h0001 << b0;
                        e1 = 16'h0001 << b1;
                        s0_exp = e0 ^ e1;
                        s1_exp = gf_mul(t_const(i), e0) ^ gf_mul(t_const(j), e1);

                        $display("--- Test %0d: W2 data[%0d] bit%0d + data[%0d] bit%0d ---",
                                 test_num, i, b0, j, b1);
                        apply_syndromes(s0_exp, s1_exp);
                        check_w2(i, j, e0, e1);
                        test_num = test_num + 1;
                    end
                end
            end
        end

        // =============================================================
        // GROUP 3: WEIGHT-2 (one data + P0)
        //
        // Data error at symbol i bit b0, P0 error at bit b1 (b0 != b1).
        // S0 = e_data ^ e_p0    S1 = T[i]*e_data  (P0 has no S1 contrib)
        // =============================================================
        $display("\n====== GROUP 3: WEIGHT-2 (data + P0) ======");

        for (i = 0; i < 17; i = i + 4) begin
            for (b0 = 0; b0 < 16; b0 = b0 + 5) begin
                b1 = (b0 + 7) % 16;
                if (b0 != b1) begin : grp3_test
                    reg [15:0] e_data, e_p0, s0_exp, s1_exp;
                    e_data = 16'h0001 << b0;
                    e_p0   = 16'h0001 << b1;
                    s0_exp = e_data ^ e_p0;
                    s1_exp = gf_mul(t_const(i), e_data);

                    $display("--- Test %0d: W2 data[%0d] bit%0d + P0 bit%0d ---",
                             test_num, i, b0, b1);
                    apply_syndromes(s0_exp, s1_exp);
                    check_w2(i, 17, e_data, e_p0);
                    test_num = test_num + 1;
                end
            end
        end

        // =============================================================
        // GROUP 4: WEIGHT-1 (one data error + one P1 error)
        //
        // Data error at symbol i (error = 1<<b0, single-bit in S0).
        // P1 error = 1<<b1  (P1 does not affect S0).
        // S0 = e_data   S1 = T[i]*e_data ^ e_p1
        // =============================================================
        $display("\n====== GROUP 4: WEIGHT-1 (data + P1) ======");

        for (i = 0; i < 17; i = i + 4) begin
            for (b0 = 0; b0 < 16; b0 = b0 + 5) begin
                for (b1 = 0; b1 < 16; b1 = b1 + 7) begin : grp4_test
                    reg [15:0] e_data, e_p1, s0_exp, s1_exp;
                    e_data = 16'h0001 << b0;
                    e_p1   = 16'h0001 << b1;
                    s0_exp = e_data;
                    s1_exp = gf_mul(t_const(i), e_data) ^ e_p1;

                    $display("--- Test %0d: W1 data[%0d] bit%0d + P1 bit%0d ---",
                             test_num, i, b0, b1);
                    apply_syndromes(s0_exp, s1_exp);

                    if (dbe_w1_found !== 1'b1) begin
                        $display("FAIL Test %0d: dbe_w1_found=0 (expected 1)", test_num);
                        fail_count = fail_count + 1;
                    end
                    else if (dbe_w1_loc0 == i[4:0] && dbe_w1_err0 == e_data && dbe_w1_err1 == e_p1) begin
                        $display("PASS Test %0d: loc0=%0d err0=%h err1(P1)=%h",
                                 test_num, dbe_w1_loc0, dbe_w1_err0, dbe_w1_err1);
                        pass_count = pass_count + 1;
                    end
                    else begin
                        $display("FAIL Test %0d: Wrong. loc0=%0d err0=%h err1=%h (exp data[%0d] e=%h p1e=%h)",
                                 test_num, dbe_w1_loc0, dbe_w1_err0, dbe_w1_err1, i, e_data, e_p1);
                        fail_count = fail_count + 1;
                    end
                    test_num = test_num + 1;
                end
            end
        end

        // =============================================================
        // GROUP 5: WEIGHT-0 (identical single-bit error in two data symbols)
        //
        // Same one-hot error e at symbols i and j.
        // S0 = e ^ e = 0   S1 = (T[i] ^ T[j]) * e
        // =============================================================
        $display("\n====== GROUP 5: WEIGHT-0 (identical errors, two data) ======");

        for (i = 0; i < 17; i = i + 4) begin
            for (j = i + 1; j < 17; j = j + 4) begin
                for (b0 = 0; b0 < 16; b0 = b0 + 5) begin : grp5_test
                    reg [15:0] e_val, s1_exp;
                    e_val  = 16'h0001 << b0;
                    s1_exp = gf_mul(t_const(i), e_val) ^ gf_mul(t_const(j), e_val);

                    $display("--- Test %0d: W0 data[%0d]+data[%0d] bit%0d ---",
                             test_num, i, j, b0);
                    apply_syndromes(16'h0000, s1_exp);
                    check_w0(i, j, e_val);
                    test_num = test_num + 1;
                end
            end
        end

        // =============================================================
        // GROUP 6: WEIGHT-0 (identical single-bit error in data + P0)
        //
        // Same one-hot error e at data symbol i and P0 (loc 17).
        // S0 = 0   S1 = T[i]*e ^ 0 = T[i]*e   (P0 has no S1 contribution)
        // =============================================================
        $display("\n====== GROUP 6: WEIGHT-0 (identical error, data + P0) ======");

        for (i = 0; i < 17; i = i + 4) begin
            for (b0 = 0; b0 < 16; b0 = b0 + 5) begin : grp6_test
                reg [15:0] e_val, s1_exp;
                e_val  = 16'h0001 << b0;
                s1_exp = gf_mul(t_const(i), e_val);

                $display("--- Test %0d: W0 data[%0d]+P0 bit%0d ---",
                         test_num, i, b0);
                apply_syndromes(16'h0000, s1_exp);
                check_w0(i, 17, e_val);
                test_num = test_num + 1;
            end
        end

        // =============================================================
        // GROUP 7: VALID_OUT TRACKS VALID_IN (combinational)
        // =============================================================
        $display("\n====== GROUP 7: VALID_OUT BEHAVIOR ======");

        $display("--- Test %0d: valid_out follows valid_in ---", test_num);
        valid_in = 1'b0;
        S0 = 16'h0000;
        S1 = 16'h0000;
        #1;
        if (valid_out !== 1'b0) begin
            $display("FAIL Test %0d: valid_out=%b when valid_in=0", test_num, valid_out);
            fail_count = fail_count + 1;
        end else begin
            valid_in = 1'b1;
            #1;
            if (valid_out !== 1'b1) begin
                $display("FAIL Test %0d: valid_out=%b when valid_in=1", test_num, valid_out);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS Test %0d: valid_out tracks valid_in combinationally", test_num);
                pass_count = pass_count + 1;
            end
        end
        valid_in = 1'b0;
        test_num = test_num + 1;

        // =============================================================
        // GROUP 8: NO FALSE POSITIVES
        // =============================================================
        $display("\n====== GROUP 8: NO FALSE POSITIVES ======");

        // S0 weight > 2 — no path should claim found
        $display("--- Test %0d: S0 weight=3 (no DBE match expected) ---", test_num);
        apply_syndromes(16'h0007, 16'hABCD);
        if (dbe_w0_found === 1'b0 && dbe_w1_found === 1'b0 && dbe_w2_found === 1'b0) begin
            $display("PASS Test %0d: No false positive for weight-3 S0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: False positive! w0=%b w1=%b w2=%b",
                     test_num, dbe_w0_found, dbe_w1_found, dbe_w2_found);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // S0 weight=16 (all bits set)
        $display("--- Test %0d: S0=0xFFFF (no DBE match expected) ---", test_num);
        apply_syndromes(16'hFFFF, 16'h1234);
        if (dbe_w0_found === 1'b0 && dbe_w1_found === 1'b0 && dbe_w2_found === 1'b0) begin
            $display("PASS Test %0d: No false positive for S0=FFFF", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: False positive! w0=%b w1=%b w2=%b",
                     test_num, dbe_w0_found, dbe_w1_found, dbe_w2_found);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // S0=0, S1=0 should be no_error, not w0
        $display("--- Test %0d: S0=0 S1=0 should NOT trigger w0 ---", test_num);
        apply_syndromes(16'h0000, 16'h0000);
        if (dbe_w0_found === 1'b0 && no_error === 1'b1) begin
            $display("PASS Test %0d: No w0 false positive on zero syndromes", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: w0_found=%b no_error=%b", test_num, dbe_w0_found, no_error);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // Weight-2 S0 with mismatched S1 — no valid pair should exist
        $display("--- Test %0d: W2 S0 with bogus S1 ---", test_num);
        apply_syndromes(16'h0003, 16'h0000);
        if (dbe_w2_found === 1'b0) begin
            $display("PASS Test %0d: No false positive for mismatched W2 syndromes", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: dbe_w2_found=1 with bogus S1", test_num);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // Weight-1 S0 with bogus S1 — inferred P1 error should not be one-hot
        $display("--- Test %0d: W1 S0 with bogus S1 ---", test_num);
        apply_syndromes(16'h0001, 16'h0000);
        if (dbe_w1_found === 1'b0) begin
            $display("PASS Test %0d: No false positive for mismatched W1 syndromes", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL Test %0d: dbe_w1_found=1 with bogus S1", test_num);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;

        // =============================================================
        // GROUP 9: EDGE CASES
        // =============================================================
        $display("\n====== GROUP 9: EDGE CASES ======");

        // Adjacent symbols (0,1) with adjacent bits (0,1)
        $display("--- Test %0d: W2 adjacent data[0] bit0 + data[1] bit1 ---", test_num);
        begin : edge_adj
            reg [15:0] e0_e, e1_e, s0_e, s1_e;
            e0_e = 16'h0001;
            e1_e = 16'h0002;
            s0_e = e0_e ^ e1_e;
            s1_e = gf_mul(t_const(0), e0_e) ^ gf_mul(t_const(1), e1_e);
            apply_syndromes(s0_e, s1_e);
            check_w2(0, 1, e0_e, e1_e);
        end
        test_num = test_num + 1;

        // Last two data symbols (15,16) with MSB bits
        $display("--- Test %0d: W2 data[15] bit15 + data[16] bit14 ---", test_num);
        begin : edge_last
            reg [15:0] e0_l, e1_l, s0_l, s1_l;
            e0_l = 16'h8000;
            e1_l = 16'h4000;
            s0_l = e0_l ^ e1_l;
            s1_l = gf_mul(t_const(15), e0_l) ^ gf_mul(t_const(16), e1_l);
            apply_syndromes(s0_l, s1_l);
            check_w2(15, 16, e0_l, e1_l);
        end
        test_num = test_num + 1;

        // Weight-0: same bit in symbols 0 and 16 (max distance)
        $display("--- Test %0d: W0 data[0]+data[16] bit0 ---", test_num);
        begin : edge_w0_far
            reg [15:0] e_f, s1_f;
            e_f  = 16'h0001;
            s1_f = gf_mul(t_const(0), e_f) ^ gf_mul(t_const(16), e_f);
            apply_syndromes(16'h0000, s1_f);
            check_w0(0, 16, e_f);
        end
        test_num = test_num + 1;

        // Weight-0: MSB error in two adjacent symbols
        $display("--- Test %0d: W0 data[7]+data[8] bit15 (MSB) ---", test_num);
        begin : edge_w0_msb
            reg [15:0] e_m, s1_m;
            e_m  = 16'h8000;
            s1_m = gf_mul(t_const(7), e_m) ^ gf_mul(t_const(8), e_m);
            apply_syndromes(16'h0000, s1_m);
            check_w0(7, 8, e_m);
        end
        test_num = test_num + 1;

        // Weight-1: data[0] bit0 + P1 bit15
        $display("--- Test %0d: W1 data[0] bit0 + P1 bit15 ---", test_num);
        begin : edge_w1_corners
            reg [15:0] e_d, e_p, s0_c, s1_c;
            e_d  = 16'h0001;
            e_p  = 16'h8000;
            s0_c = e_d;
            s1_c = gf_mul(t_const(0), e_d) ^ e_p;
            apply_syndromes(s0_c, s1_c);
            if (dbe_w1_found === 1'b1 &&
                dbe_w1_loc0 == 5'd0 &&
                dbe_w1_err0 == e_d &&
                dbe_w1_err1 == e_p) begin
                $display("PASS Test %0d: loc0=%0d err0=%h err1=%h",
                         test_num, dbe_w1_loc0, dbe_w1_err0, dbe_w1_err1);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL Test %0d: w1_found=%b loc0=%0d err0=%h err1=%h",
                         test_num, dbe_w1_found, dbe_w1_loc0, dbe_w1_err0, dbe_w1_err1);
                fail_count = fail_count + 1;
            end
        end
        test_num = test_num + 1;

        // Weight-2: data[16] + P0 (boundary locations)
        $display("--- Test %0d: W2 data[16] bit0 + P0 bit3 ---", test_num);
        begin : edge_w2_p0_boundary
            reg [15:0] e_d2, e_p2, s0_b, s1_b;
            e_d2 = 16'h0001;
            e_p2 = 16'h0008;
            s0_b = e_d2 ^ e_p2;
            s1_b = gf_mul(t_const(16), e_d2);
            apply_syndromes(s0_b, s1_b);
            check_w2(16, 17, e_d2, e_p2);
        end
        test_num = test_num + 1;

        // Weight-0: data[0] + P0 (loc 17) with bit0
        $display("--- Test %0d: W0 data[0]+P0 bit0 ---", test_num);
        begin : edge_w0_p0
            reg [15:0] e_x, s1_x;
            e_x  = 16'h0001;
            s1_x = gf_mul(t_const(0), e_x);
            apply_syndromes(16'h0000, s1_x);
            check_w0(0, 17, e_x);
        end
        test_num = test_num + 1;

        // =============================================================
        // SUMMARY
        // =============================================================
        repeat (5) @(posedge clk);
        $display("\n========================================");
        $display("  RESULTS: %0d PASSED, %0d FAILED out of %0d tests",
                 pass_count, fail_count, pass_count + fail_count);
        $display("========================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    initial begin
        #500000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
