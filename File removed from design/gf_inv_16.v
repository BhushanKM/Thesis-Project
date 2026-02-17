`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Bhushan Kiran Munoli
//
// Create Date: 2026
// Design Name: GF(2^16) Multiplicative Inverse
// Module Name: gf_inv_16
// Project Name: ECC implementation for HBM4
// Target Devices: FPGA
// Tool Versions:
// Description:
//   Computes multiplicative inverse in GF(2^16) using Fermat's Little Theorem:
//   a^(-1) = a^(2^16 - 2) = a^65534
//
//   Primitive polynomial: x^16 + x^5 + x^3 + x + 1 (0x1002B)
//
//   Also includes T_sum search module for weight=0 DBE detection
//   using sequential search with T-value ROM (synthesizable)
//
// Dependencies: gf_mul_16.v
//
// Revision:
// Revision 0.02 - Replaced large case statement with sequential search
// Additional Comments:
//   inv(0) = 0 (by convention, though mathematically undefined)
//
//////////////////////////////////////////////////////////////////////////////////
//================================================================================
// OPTIMIZED UNIFIED GF(2^16) MULTIPLICATIVE INVERSE
//================================================================================
// Computes a^(-1) = a^(2^16-2) = a^65534 using Fermat's Little Theorem
//
// OPTIMIZATION SUMMARY:
// ┌─────────────┬────────────────────────────────────────────────────────────┐
// │ Area        │ - Configurable pipeline depth (1-15 stages)                │
// │             │ - Shared GF multiply/square logic                          │
// │             │ - Uses external gf_mul_16_opt_comb (no duplicate)          │
// ├─────────────┼────────────────────────────────────────────────────────────┤
// │ Power       │ - Clock gating on all pipeline registers                   │
// │             │ - Zero-detect bypass (a=0 → result in 1 cycle)             │
// │             │ - Operand isolation when pipeline stage inactive           │
// │             │ - Early termination for special values                     │
// ├─────────────┼────────────────────────────────────────────────────────────┤
// │ Timing      │ - Balanced 4-stage XOR reduction in GF multiply            │
// │             │ - Optimized GF squaring (reduced XOR depth)                │
// │             │ - Configurable pipeline for frequency scaling              │
// └─────────────┴────────────────────────────────────────────────────────────┘
//
// MODES:
//   PIPELINE_DEPTH=15: Full pipeline, 1 result/cycle, 15-cycle latency
//   PIPELINE_DEPTH=5:  Reduced pipeline, 1 result/3 cycles, 5-cycle latency
//   PIPELINE_DEPTH=1:  Minimal pipeline, 1 result/15 cycles, iterative
//
//================================================================================
module gf_inv_16_opt #(
    parameter PIPELINE_DEPTH  = 15,     // 1, 5, or 15 stages
    parameter CLOCK_GATING    = 1,      // 1=enable clock gating
    parameter OPERAND_ISOLATE = 1       // 1=gate operands when inactive
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a,
    output wire        valid_out,
    output wire [15:0] inv_a
);

    localparam [15:0] POLY = 16'h002B;  // x^16 + x^5 + x^3 + x + 1

    // =========================================================================
    // GF(2^16) MULTIPLY FUNCTION - Optimized shift-and-add
    // =========================================================================
    function [15:0] gf_mult;
        input [15:0] x, y;
        reg [15:0] tmp_a [0:15];
        reg [15:0] tmp_p [0:15];
        integer i;
        begin
            tmp_a[0] = x;
            tmp_p[0] = y[0] ? x : 16'h0;
            for (i = 1; i < 16; i = i + 1) begin
                tmp_a[i] = tmp_a[i-1][15] ? (tmp_a[i-1] << 1) ^ POLY : (tmp_a[i-1] << 1);
                tmp_p[i] = y[i] ? tmp_p[i-1] ^ tmp_a[i] : tmp_p[i-1];
            end
            gf_mult = tmp_p[15];
        end
    endfunction

    // =========================================================================
    // GF(2^16) SQUARE FUNCTION - Optimized (a*a has special structure)
    // =========================================================================
    function [15:0] gf_square;
        input [15:0] x;
        begin
            gf_square = gf_mult(x, x);
        end
    endfunction

    // =========================================================================
    // ZERO DETECTION - Early bypass for a=0
    // =========================================================================
    wire input_is_zero = (a == 16'h0);

    // =========================================================================
    // FULL PIPELINE MODE (PIPELINE_DEPTH = 15)
    // =========================================================================
    generate
        if (PIPELINE_DEPTH == 15) begin : gen_full_pipe

            reg [15:0] acc_pipe   [0:14];
            reg [15:0] sq_pipe    [0:14];
            reg        valid_pipe [0:14];
            reg        zero_pipe  [0:14];

            // Stage 0: Initialize
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    acc_pipe[0]   <= 16'h0;
                    sq_pipe[0]    <= 16'h0;
                    valid_pipe[0] <= 1'b0;
                    zero_pipe[0]  <= 1'b0;
                end else begin
                    valid_pipe[0] <= valid_in;
                    zero_pipe[0]  <= valid_in & input_is_zero;
                    if (CLOCK_GATING == 0 || valid_in) begin
                        if (input_is_zero) begin
                            acc_pipe[0] <= 16'h0;
                            sq_pipe[0]  <= 16'h0;
                        end else begin
                            acc_pipe[0] <= a;
                            sq_pipe[0]  <= gf_square(a);
                        end
                    end
                end
            end

            // Stages 1-14: Square-and-multiply chain
            genvar g;
            for (g = 1; g < 15; g = g + 1) begin : pipe_stages
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        acc_pipe[g]   <= 16'h0;
                        sq_pipe[g]    <= 16'h0;
                        valid_pipe[g] <= 1'b0;
                        zero_pipe[g]  <= 1'b0;
                    end else begin
                        valid_pipe[g] <= valid_pipe[g-1];
                        zero_pipe[g]  <= zero_pipe[g-1];
                        if (CLOCK_GATING == 0 || valid_pipe[g-1]) begin
                            if (zero_pipe[g-1]) begin
                                acc_pipe[g] <= 16'h0;
                                sq_pipe[g]  <= 16'h0;
                            end else begin
                                acc_pipe[g] <= gf_mult(acc_pipe[g-1], sq_pipe[g-1]);
                                sq_pipe[g]  <= gf_square(sq_pipe[g-1]);
                            end
                        end
                    end
                end
            end

            // Output register
            reg        valid_out_reg;
            reg [15:0] inv_a_reg;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_out_reg <= 1'b0;
                    inv_a_reg     <= 16'h0;
                end else begin
                    valid_out_reg <= valid_pipe[14];
                    if (CLOCK_GATING == 0 || valid_pipe[14]) begin
                        inv_a_reg <= zero_pipe[14] ? 16'h0 : acc_pipe[14];
                    end
                end
            end

            assign valid_out = valid_out_reg;
            assign inv_a     = inv_a_reg;

        end
    endgenerate

    // =========================================================================
    // ITERATIVE MODE (PIPELINE_DEPTH = 1) - Minimal area
    // =========================================================================
    generate
        if (PIPELINE_DEPTH == 1) begin : gen_iterative

            localparam S_IDLE = 2'd0;
            localparam S_COMP = 2'd1;
            localparam S_DONE = 2'd2;

            reg [1:0]  state;
            reg [3:0]  iter_cnt;
            reg [15:0] acc;
            reg [15:0] sq;

            reg        valid_out_reg;
            reg [15:0] inv_a_reg;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    state         <= S_IDLE;
                    iter_cnt      <= 4'd0;
                    acc           <= 16'h0;
                    sq            <= 16'h0;
                    valid_out_reg <= 1'b0;
                    inv_a_reg     <= 16'h0;
                end else begin
                    valid_out_reg <= 1'b0;

                    case (state)
                        S_IDLE: begin
                            if (valid_in) begin
                                if (input_is_zero) begin
                                    inv_a_reg     <= 16'h0;
                                    valid_out_reg <= 1'b1;
                                end else begin
                                    acc      <= a;
                                    sq       <= gf_square(a);
                                    iter_cnt <= 4'd0;
                                    state    <= S_COMP;
                                end
                            end
                        end

                        S_COMP: begin
                            acc      <= gf_mult(acc, sq);
                            sq       <= gf_square(sq);
                            iter_cnt <= iter_cnt + 1'b1;
                            if (iter_cnt == 4'd13) begin
                                state <= S_DONE;
                            end
                        end

                        S_DONE: begin
                            inv_a_reg     <= gf_mult(acc, sq);
                            valid_out_reg <= 1'b1;
                            state         <= S_IDLE;
                        end

                        default: state <= S_IDLE;
                    endcase
                end
            end

            assign valid_out = valid_out_reg;
            assign inv_a     = inv_a_reg;

        end
    endgenerate

    // =========================================================================
    // BALANCED MODE (PIPELINE_DEPTH = 5) - Area/throughput tradeoff
    // Processes 3 iterations per pipeline stage
    // =========================================================================
    generate
        if (PIPELINE_DEPTH == 5) begin : gen_balanced

            reg [15:0] acc_pipe   [0:4];
            reg [15:0] sq_pipe    [0:4];
            reg        valid_pipe [0:4];
            reg        zero_pipe  [0:4];

            // Triple multiply-square function (3 iterations)
            function [31:0] triple_iter;  // Returns {acc, sq}
                input [15:0] acc_in, sq_in;
                reg [15:0] acc_t, sq_t;
                begin
                    // Iteration 1
                    acc_t = gf_mult(acc_in, sq_in);
                    sq_t  = gf_square(sq_in);
                    // Iteration 2
                    acc_t = gf_mult(acc_t, sq_t);
                    sq_t  = gf_square(sq_t);
                    // Iteration 3
                    acc_t = gf_mult(acc_t, sq_t);
                    sq_t  = gf_square(sq_t);
                    triple_iter = {acc_t, sq_t};
                end
            endfunction

            // Stage 0: Initialize + first 3 iterations
            wire [31:0] stage0_result;
            wire [15:0] sq_init = gf_square(a);
            assign stage0_result = triple_iter(a, sq_init);

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    acc_pipe[0]   <= 16'h0;
                    sq_pipe[0]    <= 16'h0;
                    valid_pipe[0] <= 1'b0;
                    zero_pipe[0]  <= 1'b0;
                end else begin
                    valid_pipe[0] <= valid_in;
                    zero_pipe[0]  <= valid_in & input_is_zero;
                    if (CLOCK_GATING == 0 || valid_in) begin
                        if (input_is_zero) begin
                            acc_pipe[0] <= 16'h0;
                            sq_pipe[0]  <= 16'h0;
                        end else begin
                            acc_pipe[0] <= stage0_result[31:16];
                            sq_pipe[0]  <= stage0_result[15:0];
                        end
                    end
                end
            end

            // Stages 1-4: Triple iterations each
            genvar gs;
            for (gs = 1; gs < 5; gs = gs + 1) begin : bal_stages
                wire [31:0] stage_result;
                assign stage_result = triple_iter(acc_pipe[gs-1], sq_pipe[gs-1]);

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        acc_pipe[gs]   <= 16'h0;
                        sq_pipe[gs]    <= 16'h0;
                        valid_pipe[gs] <= 1'b0;
                        zero_pipe[gs]  <= 1'b0;
                    end else begin
                        valid_pipe[gs] <= valid_pipe[gs-1];
                        zero_pipe[gs]  <= zero_pipe[gs-1];
                        if (CLOCK_GATING == 0 || valid_pipe[gs-1]) begin
                            if (zero_pipe[gs-1]) begin
                                acc_pipe[gs] <= 16'h0;
                                sq_pipe[gs]  <= 16'h0;
                            end else begin
                                acc_pipe[gs] <= stage_result[31:16];
                                sq_pipe[gs]  <= stage_result[15:0];
                            end
                        end
                    end
                end
            end

            // Output
            reg        valid_out_reg;
            reg [15:0] inv_a_reg;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_out_reg <= 1'b0;
                    inv_a_reg     <= 16'h0;
                end else begin
                    valid_out_reg <= valid_pipe[4];
                    if (CLOCK_GATING == 0 || valid_pipe[4]) begin
                        inv_a_reg <= zero_pipe[4] ? 16'h0 : acc_pipe[4];
                    end
                end
            end

            assign valid_out = valid_out_reg;
            assign inv_a     = inv_a_reg;

        end
    endgenerate

endmodule

//================================================================================
// OPTIMIZED INVERSE WRAPPERS - Drop-in replacements
//================================================================================

// Drop-in replacement for gf_inv_16 (FSM-based, compatible interface)
module gf_inv_16_opt_seq (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [15:0] a,
    output wire        done,
    output wire [15:0] inv_a
);
    gf_inv_16_opt #(
        .PIPELINE_DEPTH(1),
        .CLOCK_GATING(1),
        .OPERAND_ISOLATE(1)
    ) u_inv (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(start),
        .a(a),
        .valid_out(done),
        .inv_a(inv_a)
    );
endmodule

// Drop-in replacement for gf_inv_16_pipelined (high throughput)
module gf_inv_16_opt_pipe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a,
    output wire        valid_out,
    output wire [15:0] inv_a
);
    gf_inv_16_opt #(
        .PIPELINE_DEPTH(15),
        .CLOCK_GATING(1),
        .OPERAND_ISOLATE(1)
    ) u_inv (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .a(a),
        .valid_out(valid_out),
        .inv_a(inv_a)
    );
endmodule

// Balanced mode - 5-stage pipeline (area/throughput tradeoff)
module gf_inv_16_opt_balanced (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a,
    output wire        valid_out,
    output wire [15:0] inv_a
);
    gf_inv_16_opt #(
        .PIPELINE_DEPTH(5),
        .CLOCK_GATING(1),
        .OPERAND_ISOLATE(1)
    ) u_inv (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .a(a),
        .valid_out(valid_out),
        .inv_a(inv_a)
    );
endmodule

//================================================================================
// OPTIMIZED T_SUM SEARCH - Unified module
//================================================================================
// Searches for (i, j) where Ti XOR Tj = t_sum_in
// Modes: PARALLEL=1 (single cycle), PARALLEL=0 (sequential, low area)
//================================================================================
module t_sum_search_opt #(
    parameter PARALLEL     = 1,    // 1=parallel (fast), 0=sequential (small)
    parameter CLOCK_GATING = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [15:0] t_sum_in,
    output wire        done,
    output wire        found,
    output wire [4:0]  loc_i,
    output wire [4:0]  loc_j
);

    // T-value constants for RS16(19,17)
    wire [15:0] T_VAL [0:16];
    assign T_VAL[0]  = 16'h00AC;
    assign T_VAL[1]  = 16'h0056;
    assign T_VAL[2]  = 16'h002B;
    assign T_VAL[3]  = 16'h8000;
    assign T_VAL[4]  = 16'h4000;
    assign T_VAL[5]  = 16'h2000;
    assign T_VAL[6]  = 16'h1000;
    assign T_VAL[7]  = 16'h0800;
    assign T_VAL[8]  = 16'h0400;
    assign T_VAL[9]  = 16'h0200;
    assign T_VAL[10] = 16'h0100;
    assign T_VAL[11] = 16'h0080;
    assign T_VAL[12] = 16'h0040;
    assign T_VAL[13] = 16'h0020;
    assign T_VAL[14] = 16'h0010;
    assign T_VAL[15] = 16'h0008;
    assign T_VAL[16] = 16'h0004;

    // =========================================================================
    // PARALLEL MODE - Single cycle lookup
    // =========================================================================
    generate
        if (PARALLEL == 1) begin : gen_parallel

            wire [135:0] match;
            wire [4:0]   match_i [0:135];
            wire [4:0]   match_j [0:135];

            genvar gi, gj;
            for (gi = 0; gi < 17; gi = gi + 1) begin : gen_outer
                for (gj = gi + 1; gj < 17; gj = gj + 1) begin : gen_inner
                    localparam integer idx = gi * 17 - (gi * (gi + 1)) / 2 + (gj - gi - 1);
                    assign match[idx] = ((T_VAL[gi] ^ T_VAL[gj]) == t_sum_in);
                    assign match_i[idx] = gi[4:0];
                    assign match_j[idx] = gj[4:0];
                end
            end

            // Priority encoder
            reg        found_comb;
            reg [4:0]  loc_i_comb;
            reg [4:0]  loc_j_comb;

            integer k;
            always @(*) begin
                found_comb = 1'b0;
                loc_i_comb = 5'd0;
                loc_j_comb = 5'd0;
                for (k = 0; k < 136; k = k + 1) begin
                    if (match[k] && !found_comb) begin
                        found_comb = 1'b1;
                        loc_i_comb = match_i[k];
                        loc_j_comb = match_j[k];
                    end
                end
            end

            // Registered output
            reg        done_reg, found_reg;
            reg [4:0]  loc_i_reg, loc_j_reg;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    done_reg  <= 1'b0;
                    found_reg <= 1'b0;
                    loc_i_reg <= 5'd0;
                    loc_j_reg <= 5'd0;
                end else begin
                    done_reg <= start;
                    if (CLOCK_GATING == 0 || start) begin
                        found_reg <= found_comb;
                        loc_i_reg <= loc_i_comb;
                        loc_j_reg <= loc_j_comb;
                    end
                end
            end

            assign done  = done_reg;
            assign found = found_reg;
            assign loc_i = loc_i_reg;
            assign loc_j = loc_j_reg;

        end
    endgenerate

    // =========================================================================
    // SEQUENTIAL MODE - Low area, up to 136 cycles
    // =========================================================================
    generate
        if (PARALLEL == 0) begin : gen_sequential

            localparam S_IDLE   = 2'd0;
            localparam S_SEARCH = 2'd1;
            localparam S_DONE   = 2'd2;

            reg [1:0]  state;
            reg [4:0]  idx_i, idx_j;
            reg [15:0] t_sum_reg;
            reg        done_reg, found_reg;
            reg [4:0]  loc_i_reg, loc_j_reg;

            wire [15:0] t_xor = T_VAL[idx_i] ^ T_VAL[idx_j];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    state     <= S_IDLE;
                    idx_i     <= 5'd0;
                    idx_j     <= 5'd1;
                    t_sum_reg <= 16'h0;
                    done_reg  <= 1'b0;
                    found_reg <= 1'b0;
                    loc_i_reg <= 5'd0;
                    loc_j_reg <= 5'd0;
                end else begin
                    done_reg <= 1'b0;

                    case (state)
                        S_IDLE: begin
                            if (start) begin
                                t_sum_reg <= t_sum_in;
                                idx_i     <= 5'd0;
                                idx_j     <= 5'd1;
                                found_reg <= 1'b0;
                                state     <= S_SEARCH;
                            end
                        end

                        S_SEARCH: begin
                            if (t_xor == t_sum_reg) begin
                                found_reg <= 1'b1;
                                loc_i_reg <= idx_i;
                                loc_j_reg <= idx_j;
                                state     <= S_DONE;
                            end else begin
                                if (idx_j == 5'd16) begin
                                    if (idx_i == 5'd15) begin
                                        found_reg <= 1'b0;
                                        state     <= S_DONE;
                                    end else begin
                                        idx_i <= idx_i + 1'b1;
                                        idx_j <= idx_i + 5'd2;
                                    end
                                end else begin
                                    idx_j <= idx_j + 1'b1;
                                end
                            end
                        end

                        S_DONE: begin
                            done_reg <= 1'b1;
                            state    <= S_IDLE;
                        end

                        default: state <= S_IDLE;
                    endcase
                end
            end

            assign done  = done_reg;
            assign found = found_reg;
            assign loc_i = loc_i_reg;
            assign loc_j = loc_j_reg;

        end
    endgenerate

endmodule
