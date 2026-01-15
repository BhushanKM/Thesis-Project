`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2026 02:48:03 PM
// Design Name: 
// Module Name: gf_mul_16
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rs_decoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] rx_in,
    input  logic        rx_valid,
    output logic [15:0] dec_out,
    output logic        dec_valid
);
    // Constants
    localparam [15:0] ALPHA1 = 16'h0002;
    localparam [15:0] ALPHA2 = 16'h0004;
    localparam [15:0] ALPHAINV = 16'h8016; // alpha^-1 in GF(2^16)
    localparam [15:0] ALPHASTART = 16'h0004; // alpha^(19-1) = alpha^18 (Precompute this)

    typedef enum {IDLE, SYNDROME, SOLVE, CORRECT} state_t;
    state_t state;

    logic [15:0] buffer [0:18];
    logic [15:0] s1, s2, s1_inv, x_loc, e_mag, x_inv;
    logic [4:0]  cnt;

    // Arithmetic Units
    logic [15:0] m_s1, m_s2, m_x, m_e, m_chien;
    gf_mul_16 mul_s1 (.a(s1), .b(ALPHA1), .p(m_s1));
    gf_mul_16 mul_s2 (.a(s2), .b(ALPHA2), .p(m_s2));
    
    // Inverter using BRAM (User must provide ROM content)
    // In Vivado, initialize this with a .COE file
    (* rom_style = "block" *) logic [15:0] inv_rom [0:65535];
    assign s1_inv = inv_rom[s1];
    assign x_inv  = inv_rom[x_loc];

    gf_mul_16 mul_solve_x (.a(s2),     .b(s1_inv), .p(x_loc));
    gf_mul_16 mul_solve_e (.a(s1),     .b(x_inv),  .p(e_mag));
    
    logic [15:0] current_alpha;
    gf_mul_16 mul_chien   (.a(current_alpha), .b(ALPHAINV), .p(m_chien));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else case (state)
            IDLE: if (rx_valid) begin
                s1 <= rx_in; s2 <= rx_in;
                buffer[0] <= rx_in;
                cnt <= 1;
                state <= SYNDROME;
            end
            
            SYNDROME: if (rx_valid) begin
                s1 <= m_s1 ^ rx_in;
                s2 <= m_s2 ^ rx_in;
                buffer[cnt] <= rx_in;
                cnt <= cnt + 1;
                if (cnt == 18) state <= SOLVE;
            end

            SOLVE: begin
                // Give 2 cycles for Inverter and Multipliers to settle
                cnt <= 0;
                current_alpha <= ALPHASTART; 
                state <= CORRECT;
            end

            CORRECT: begin
                // If S1=0 and S2=0, no error. Else XOR e_mag if alpha^(n-j) == x_loc
                if (s1 != 0 && current_alpha == x_loc)
                    dec_out <= buffer[cnt] ^ e_mag;
                else
                    dec_out <= buffer[cnt];
                
                current_alpha <= m_chien;
                dec_valid <= 1;
                cnt <= cnt + 1;
                if (cnt == 18) state <= IDLE;
            end
        endcase
    end
endmodule