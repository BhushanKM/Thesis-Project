`timescale 1ns / 1ps

module gf_mul_16_opt #(
    parameter REGISTERED      = 1,   // 0 = combinational, 1 = registered output
    parameter CLOCK_GATING    = 1,   // 1 = update output reg only when valid_in=1
    parameter OPERAND_ISOLATE = 1    // 1 = gate inputs when invalid
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire        valid_out,
    output wire [15:0] p
);

    // Primitive polynomial: x^16 + x^5 + x^3 + x + 1
    localparam [15:0] POLY = 16'h002B;

    // -------------------------------------------------------------------------
    // Operand isolation
    // -------------------------------------------------------------------------
    wire [15:0] a_gated;
    wire [15:0] b_gated;

    generate
        if (OPERAND_ISOLATE && REGISTERED) begin : gen_isolate
            assign a_gated = valid_in ? a : 16'h0000;
            assign b_gated = valid_in ? b : 16'h0000;
        end else begin : gen_no_isolate
            assign a_gated = a;
            assign b_gated = b;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Zero operand bypass
    // -------------------------------------------------------------------------
    wire a_is_zero;
    wire b_is_zero;
    wire zero_bypass;

    assign a_is_zero  = (a_gated == 16'h0000);
    assign b_is_zero  = (b_gated == 16'h0000);
    assign zero_bypass = a_is_zero | b_is_zero;

    // -------------------------------------------------------------------------
    // GF shift-and-add core
    //
    // tmp_a[i] = a * x^i mod POLY
    // term[i]  = tmp_a[i] if b[i]=1 else 0
    // -------------------------------------------------------------------------
    wire [15:0] tmp_a [0:15];
    wire [15:0] term  [0:15];
    wire [15:0] partial [0:15];

    assign tmp_a[0] = a_gated;
    assign term[0]  = b_gated[0] ? tmp_a[0] : 16'h0000;
    assign partial[0] = term[0];

    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_shift_add
            assign tmp_a[i] = tmp_a[i-1][15] ?
                              ({tmp_a[i-1][14:0], 1'b0} ^ POLY) :
                              {tmp_a[i-1][14:0], 1'b0};

            assign term[i] = b_gated[i] ? tmp_a[i] : 16'h0000;

            assign partial[i] = partial[i-1] ^ term[i];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Balanced XOR tree
    // Same result as partial[15], but lower XOR depth
    // -------------------------------------------------------------------------
    wire [15:0] tree_l0 [0:7];
    wire [15:0] tree_l1 [0:3];
    wire [15:0] tree_l2 [0:1];
    wire [15:0] tree_result;

    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_tree_l0
            assign tree_l0[i] = term[2*i] ^ term[2*i+1];
        end

        for (i = 0; i < 4; i = i + 1) begin : gen_tree_l1
            assign tree_l1[i] = tree_l0[2*i] ^ tree_l0[2*i+1];
        end

        for (i = 0; i < 2; i = i + 1) begin : gen_tree_l2
            assign tree_l2[i] = tree_l1[2*i] ^ tree_l1[2*i+1];
        end
    endgenerate

    assign tree_result = tree_l2[0] ^ tree_l2[1];

    // -------------------------------------------------------------------------
    // Final multiplication result selection
    // -------------------------------------------------------------------------
    wire [15:0] mul_result;

    generate
        if (REGISTERED) begin : gen_use_tree
            assign mul_result = zero_bypass ? 16'h0000 : tree_result;
        end else begin : gen_use_chain
            assign mul_result = zero_bypass ? 16'h0000 : partial[15];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Output stage
    // -------------------------------------------------------------------------
    generate
        if (REGISTERED) begin : gen_registered
            reg [15:0] p_reg;
            reg        valid_reg;

            if (CLOCK_GATING) begin : gen_clk_gate
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        p_reg     <= 16'h0000;
                        valid_reg <= 1'b0;
                    end else begin
                        valid_reg <= valid_in;
                        if (valid_in) begin
                            p_reg <= mul_result;
                        end
                    end
                end
            end else begin : gen_no_clk_gate
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        p_reg     <= 16'h0000;
                        valid_reg <= 1'b0;
                    end else begin
                        valid_reg <= valid_in;
                        p_reg     <= mul_result;
                    end
                end
            end

            assign p         = p_reg;
            assign valid_out = valid_reg;

        end else begin : gen_combinational
            assign p         = mul_result;
            assign valid_out = valid_in;
        end
    endgenerate

endmodule
