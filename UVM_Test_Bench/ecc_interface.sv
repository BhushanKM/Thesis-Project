//////////////////////////////////////////////////////////////////////////////////
// ECC Interface - DUT Interface with Clocking Blocks
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

`include "ecc_defines.sv"

interface ecc_interface (input logic clk, input logic rst_n);

    // Control signals
    logic        test_mode_en;
    logic        cw_sel;

    // Write path
    logic        wr_valid;
    logic [`DATA_WIDTH-1:0] wr_data;
    logic        wr_ready;

    // Read path
    logic        rd_valid;
    logic [`CODEWORD_WIDTH-1:0] rd_codeword;
    logic        burst_start;
    logic        rd_out_valid;
    logic [`DATA_WIDTH-1:0] rd_data_out;
    logic [1:0]  sev_out;

    // Encoder output
    logic        enc_valid_out;
    logic [`CODEWORD_WIDTH-1:0] enc_codeword_out;

    // Status flags
    logic        error_detected;
    logic        error_corrected;
    logic        uncorrectable;

    // Driver clocking block
    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output test_mode_en;
        output cw_sel;
        output wr_valid;
        output wr_data;
        input  wr_ready;
        output rd_valid;
        output rd_codeword;
        output burst_start;
        input  rd_out_valid;
        input  rd_data_out;
        input  sev_out;
        input  enc_valid_out;
        input  enc_codeword_out;
        input  error_detected;
        input  error_corrected;
        input  uncorrectable;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        default input #1step;
        input test_mode_en;
        input cw_sel;
        input wr_valid;
        input wr_data;
        input wr_ready;
        input rd_valid;
        input rd_codeword;
        input burst_start;
        input rd_out_valid;
        input rd_data_out;
        input sev_out;
        input enc_valid_out;
        input enc_codeword_out;
        input error_detected;
        input error_corrected;
        input uncorrectable;
    endclocking

    // Modports
    modport DRV (clocking drv_cb, input clk, input rst_n);
    modport MON (clocking mon_cb, input clk, input rst_n);

    // Assertions
    property p_wr_ready_stable;
        @(posedge clk) disable iff (!rst_n)
        wr_valid |-> wr_ready;
    endproperty
    assert property (p_wr_ready_stable) else
        $error("wr_ready should be high when wr_valid is asserted");

    property p_enc_valid_follows_wr;
        @(posedge clk) disable iff (!rst_n)
        (wr_valid && !test_mode_en) |-> ##1 enc_valid_out;
    endproperty
    assert property (p_enc_valid_follows_wr) else
        $error("enc_valid_out should follow wr_valid in normal mode");

    property p_rd_out_follows_rd_in;
        @(posedge clk) disable iff (!rst_n)
        rd_valid |-> ##1 rd_out_valid;
    endproperty
    assert property (p_rd_out_follows_rd_in) else
        $error("rd_out_valid should follow rd_valid");

    // Severity encoding check
    property p_sev_encoding_valid;
        @(posedge clk) disable iff (!rst_n)
        rd_out_valid |-> (sev_out inside {`SEV_NE, `SEV_CEs, `SEV_UE, `SEV_CEm});
    endproperty
    assert property (p_sev_encoding_valid) else
        $error("Invalid severity encoding");

endinterface
