`timescale 1ns / 1ps

module ecc_encoder_tb;

    reg          clk;
    reg          rst_n;
    reg          valid_in;
    reg  [271:0] data_in;
    wire         valid_out;
    wire [303:0] codeword_out;

    ecc_encoder uut (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (valid_in),
        .data_in      (data_in),
        .valid_out    (valid_out),
        .codeword_out (codeword_out)
    );

    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk = ~clk;

    wire [271:0] cw_data = codeword_out[303:32];
    wire [15:0]  cw_P0   = codeword_out[31:16];
    wire [15:0]  cw_P1   = codeword_out[15:0];

    localparam [15:0] POLY = 16'h002B;

    integer pass_count;
    integer fail_count;
    integer test_num;

    // -----------------------------------------------------------------
    // Standalone GF multiplier instance for direct verification
    // -----------------------------------------------------------------
    reg          gf_valid_in;
    reg  [15:0]  gf_a;
    reg  [15:0]  gf_b;
    wire         gf_valid_out;
    wire [15:0]  gf_p;

    gf_mul_16_opt u_gf_mul_tb (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (gf_valid_in),
        .a         (gf_a),
        .b         (gf_b),
        .valid_out (gf_valid_out),
        .p         (gf_p)
    );

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

    reg [15:0] T_COEFFS [0:16];
    initial begin
        T_COEFFS[0]  = 16'h00AC;
        T_COEFFS[1]  = 16'h0056;
        T_COEFFS[2]  = 16'h002B;
        T_COEFFS[3]  = 16'h8000;
        T_COEFFS[4]  = 16'h4000;
        T_COEFFS[5]  = 16'h2000;
        T_COEFFS[6]  = 16'h1000;
        T_COEFFS[7]  = 16'h0800;
        T_COEFFS[8]  = 16'h0400;
        T_COEFFS[9]  = 16'h0200;
        T_COEFFS[10] = 16'h0100;
        T_COEFFS[11] = 16'h0080;
        T_COEFFS[12] = 16'h0040;
        T_COEFFS[13] = 16'h0020;
        T_COEFFS[14] = 16'h0010;
        T_COEFFS[15] = 16'h0008;
        T_COEFFS[16] = 16'h0004;
    end

    task check_gf_mul;
        input [15:0] a_val;
        input [15:0] b_val;
        reg [15:0] expected;
        begin
            expected = gf_mul(a_val, b_val);
            @(posedge clk);
            gf_valid_in <= 1'b1;
            gf_a        <= a_val;
            gf_b        <= b_val;
            @(posedge clk);
            gf_valid_in <= 1'b0;
            @(posedge clk);
            if (gf_p !== expected) begin
                $display("FAIL Test %0d: GF_MUL(%h * %h) Expected %h, Got %h",
                         test_num, a_val, b_val, expected, gf_p);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS Test %0d: GF_MUL(%h * %h) = %h",
                         test_num, a_val, b_val, gf_p);
                pass_count = pass_count + 1;
            end
            test_num = test_num + 1;
        end
    endtask

    task apply_input;
        input [271:0] din;
        begin
            @(posedge clk);
            valid_in <= 1'b1;
            data_in  <= din;
            @(posedge clk);
            valid_in <= 1'b0;
            data_in  <= 272'd0;
        end
    endtask

    task wait_for_valid_out;
        integer timeout;
        begin
            timeout = 0;
            while (!valid_out && timeout < 20) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout == 20) begin
                $display("ERROR: Timeout waiting for valid_out");
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_output;
        input [271:0] din;
        reg [15:0] D [0:16];
        reg [15:0] exp_P0;
        reg [15:0] exp_P1;
        integer j;
        begin
            for (j = 0; j < 17; j = j + 1)
                D[j] = din[271 - j*16 -: 16];

            exp_P0 = 16'h0000;
            exp_P1 = 16'h0000;
            for (j = 0; j < 17; j = j + 1) begin
                exp_P0 = exp_P0 ^ D[j];
                exp_P1 = exp_P1 ^ gf_mul(T_COEFFS[j], D[j]);
            end

            if (cw_data !== din) begin
                $display("FAIL Test %0d: Data mismatch. Expected %h, Got %h", test_num, din, cw_data);
                fail_count = fail_count + 1;
            end else if (cw_P0 !== exp_P0) begin
                $display("FAIL Test %0d: P0 mismatch. Expected %h, Got %h", test_num, exp_P0, cw_P0);
                fail_count = fail_count + 1;
            end else if (cw_P1 !== exp_P1) begin
                $display("FAIL Test %0d: P1 mismatch. Expected %h, Got %h", test_num, exp_P1, cw_P1);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS Test %0d", test_num);
                pass_count = pass_count + 1;
            end
            test_num = test_num + 1;
        end
    endtask

    reg [271:0] saved_data;
    integer i;

    initial begin
        $dumpfile("ecc_encoder_tb.vcd");
        $dumpvars(0, ecc_encoder_tb);

        clk        = 0;
        rst_n      = 0;
        valid_in   = 0;
        gf_valid_in = 0;
        gf_a       = 16'h0000;
        gf_b       = 16'h0000;
        data_in    = 272'd0;
        pass_count = 0;
        fail_count = 0;
        test_num   = 1;

        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // =============================================================
        // GF(2^16) MULTIPLIER DIRECT VERIFICATION
        // =============================================================
        $display("\n====== GF_MUL_16 VERIFICATION ======");

        // -- Identity: a * 1 = a --
        $display("\n--- Test %0d: GF_MUL identity (a * 1 = a) ---", test_num);
        check_gf_mul(16'h00AC, 16'h0001);
        check_gf_mul(16'hFFFF, 16'h0001);
        check_gf_mul(16'h8000, 16'h0001);
        check_gf_mul(16'h0001, 16'h0001);

        // -- Zero: a * 0 = 0 --
        $display("\n--- Test %0d: GF_MUL zero (a * 0 = 0) ---", test_num);
        check_gf_mul(16'h00AC, 16'h0000);
        check_gf_mul(16'hFFFF, 16'h0000);
        check_gf_mul(16'h0000, 16'h0000);

        // -- Commutativity: a * b = b * a --
        $display("\n--- Test %0d: GF_MUL commutativity ---", test_num);
        check_gf_mul(16'h00AC, 16'h0056);
        check_gf_mul(16'h0056, 16'h00AC);

        check_gf_mul(16'hABCD, 16'h1234);
        check_gf_mul(16'h1234, 16'hABCD);

        // -- Each encoder coefficient T[i] * 0x0001 = T[i] --
        $display("\n--- Test %0d: GF_MUL T[i] * 1 = T[i] ---", test_num);
        for (i = 0; i < 17; i = i + 1) begin
            check_gf_mul(T_COEFFS[i], 16'h0001);
        end

        // -- Powers of alpha: alpha * alpha = alpha^2 --
        // alpha = 0x0002 (x), alpha^2 = 0x0004
        $display("\n--- Test %0d: GF_MUL alpha powers ---", test_num);
        check_gf_mul(16'h0002, 16'h0002);

        // alpha^2 * alpha = alpha^3 = 0x0008
        check_gf_mul(16'h0004, 16'h0002);

        // alpha^3 * alpha = alpha^4 = 0x0010
        check_gf_mul(16'h0008, 16'h0002);

        // alpha^15 * alpha = alpha^16 = 0x002B (reduction by poly)
        check_gf_mul(16'h8000, 16'h0002);

        // -- Self-multiply (squaring) --
        $display("\n--- Test %0d: GF_MUL squaring ---", test_num);
        check_gf_mul(16'h0002, 16'h0002);
        check_gf_mul(16'h00AC, 16'h00AC);
        check_gf_mul(16'hFFFF, 16'hFFFF);
        check_gf_mul(16'h8000, 16'h8000);

        // -- Polynomial reduction boundary --
        // MSB set in both operands forces reduction
        $display("\n--- Test %0d: GF_MUL reduction cases ---", test_num);
        check_gf_mul(16'h8000, 16'h8000);
        check_gf_mul(16'hC000, 16'hC000);
        check_gf_mul(16'hFFFF, 16'hFFFF);
        check_gf_mul(16'h8001, 16'h8001);

        // -- Walking one in operand a --
        $display("\n--- Test %0d: GF_MUL walking one in a ---", test_num);
        for (i = 0; i < 16; i = i + 1) begin
            check_gf_mul(16'h0001 << i, 16'hABCD);
        end

        // -- Walking one in operand b --
        $display("\n--- Test %0d: GF_MUL walking one in b ---", test_num);
        for (i = 0; i < 16; i = i + 1) begin
            check_gf_mul(16'hABCD, 16'h0001 << i);
        end

        // -- Random GF multiplications --
        $display("\n--- Test %0d: GF_MUL random pairs ---", test_num);
        for (i = 0; i < 20; i = i + 1) begin
            check_gf_mul($random, $random);
        end

//        // =============================================================
//        // ECC ENCODER VERIFICATION
//        // =============================================================
//        $display("\n====== ECC ENCODER VERIFICATION ======");

//        // ---- All zeros ----
//        $display("\n--- Test %0d: All zeros ---", test_num);
//        saved_data = 272'd0;
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- All ones ----
//        $display("\n--- Test %0d: All ones ---", test_num);
//        saved_data = {272{1'b1}};
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Single symbol non-zero (symbol 0 = 0x0001) ----
//        $display("\n--- Test %0d: Single symbol D[0]=1 ---", test_num);
//        saved_data = 272'd0;
//        saved_data[271:256] = 16'h0001;
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Single symbol non-zero (last symbol D[16] = 0xABCD) ----
//        $display("\n--- Test %0d: Single symbol D[16]=ABCD ---", test_num);
//        saved_data = 272'd0;
//        saved_data[15:0] = 16'hABCD;
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Walking one across each symbol position ----
//        for (i = 0; i < 17; i = i + 1) begin
//            $display("\n--- Test %0d: Walking one symbol %0d ---", test_num, i);
//            saved_data = 272'd0;
//            saved_data[271 - i*16 -: 16] = 16'h0001;
//            apply_input(saved_data);
//            wait_for_valid_out;
//            @(posedge clk);
//            check_output(saved_data);
//        end

//        // ---- Test 22: All symbols = 0x5555 ----
//        $display("\n--- Test %0d: All symbols = 0x5555 ---", test_num);
//        saved_data = {17{16'h5555}};
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Test 23: All symbols = 0xAAAA ----
//        $display("\n--- Test %0d: All symbols = 0xAAAA ---", test_num);
//        saved_data = {17{16'hAAAA}};
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Test 24: Incrementing symbols D[i] = i+1 ----
//        $display("\n--- Test %0d: Incrementing symbols ---", test_num);
//        saved_data = {16'h0001, 16'h0002, 16'h0003, 16'h0004,
//                      16'h0005, 16'h0006, 16'h0007, 16'h0008,
//                      16'h0009, 16'h000A, 16'h000B, 16'h000C,
//                      16'h000D, 16'h000E, 16'h000F, 16'h0010,
//                      16'h0011};
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Test 25: Max value in each symbol ----
//        $display("\n--- Test %0d: All symbols = 0xFFFF ---", test_num);
//        saved_data = {17{16'hFFFF}};
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        // ---- Test 26-35: Random data ----
//        for (i = 0; i < 10; i = i + 1) begin
//            $display("\n--- Test %0d: Random %0d ---", test_num, i);
//            saved_data[271:256] = $random;
//            saved_data[255:224] = $random;
//            saved_data[223:192] = $random;
//            saved_data[191:160] = $random;
//            saved_data[159:128] = $random;
//            saved_data[127:96]  = $random;
//            saved_data[95:64]   = $random;
//            saved_data[63:32]   = $random;
//            saved_data[31:0]    = $random;
//            apply_input(saved_data);
//            wait_for_valid_out;
//            @(posedge clk);
//            check_output(saved_data);
//        end

//        // ---- Test 36: Back-to-back valid inputs ----
//        $display("\n--- Test %0d & %0d: Back-to-back ---", test_num, test_num+1);
//        begin : back_to_back
//            reg [271:0] data_a, data_b;
//            data_a = {17{16'h1234}};
//            data_b = {17{16'h5678}};

//            @(posedge clk);
//            valid_in <= 1'b1;
//            data_in  <= data_a;
//            @(posedge clk);
//            data_in  <= data_b;
//            @(posedge clk);
//            valid_in <= 1'b0;
//            data_in  <= 272'd0;

//            wait_for_valid_out;
//            @(posedge clk);
//            check_output(data_a);
//            @(posedge clk);
//            check_output(data_b);
//        end

//        // ---- Test 38: Reset mid-operation ----
//        $display("\n--- Test %0d: Reset during operation ---", test_num);
//        saved_data = {17{16'hDEAD}};
//        @(posedge clk);
//        valid_in <= 1'b1;
//        data_in  <= saved_data;
//        @(posedge clk);
//        valid_in <= 1'b0;
//        rst_n    <= 1'b0;
//        @(posedge clk);
//        @(posedge clk);
//        rst_n <= 1'b1;
//        repeat (5) @(posedge clk);
//        if (valid_out === 1'b0 && codeword_out === 304'd0) begin
//            $display("PASS Test %0d: Reset clears output", test_num);
//            pass_count = pass_count + 1;
//        end else begin
//            $display("FAIL Test %0d: Output not cleared after reset. valid_out=%b codeword=%h",
//                     test_num, valid_out, codeword_out);
//            fail_count = fail_count + 1;
//        end
//        test_num = test_num + 1;

//        // ---- Test 39: No valid_in - output should stay low ----
//        $display("\n--- Test %0d: No valid_in ---", test_num);
//        valid_in <= 1'b0;
//        data_in  <= {17{16'hBEEF}};
//        repeat (5) @(posedge clk);
//        if (valid_out === 1'b0) begin
//            $display("PASS Test %0d: No spurious valid_out", test_num);
//            pass_count = pass_count + 1;
//        end else begin
//            $display("FAIL Test %0d: Spurious valid_out detected", test_num);
//            fail_count = fail_count + 1;
//        end
//        test_num = test_num + 1;

//        // ---- Test 40: Single bit set in data ----
//        $display("\n--- Test %0d: Single bit set (bit 0) ---", test_num);
//        saved_data = 272'd1;
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

//        $display("\n--- Test %0d: Single bit set (MSB) ---", test_num);
//        saved_data = 272'd0;
//        saved_data[271] = 1'b1;
//        apply_input(saved_data);
//        wait_for_valid_out;
//        @(posedge clk);
//        check_output(saved_data);

        // ---- Summary ----
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
        #100000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule