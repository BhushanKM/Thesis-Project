//////////////////////////////////////////////////////////////////////////////////
// ECC Top - Top Module with DUT Instantiation
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

`include "ecc_defines.sv"
`include "ecc_interface.sv"

module ecc_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ecc_pkg::*;

    // Clock and reset
    logic clk;
    logic rst_n;

    // Clock generation (100MHz)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
    end

    // Interface instantiation
    ecc_interface ecc_if (clk, rst_n);

    // DUT instantiation
    ecc_engine_top dut (
        .clk              (clk),
        .rst_n            (rst_n),

        // Control signals
        .test_mode_en     (ecc_if.test_mode_en),
        .cw_sel           (ecc_if.cw_sel),

        // Write path
        .wr_valid         (ecc_if.wr_valid),
        .wr_data          (ecc_if.wr_data),
        .wr_ready         (ecc_if.wr_ready),

        // Read path
        .rd_valid         (ecc_if.rd_valid),
        .rd_codeword      (ecc_if.rd_codeword),
        .burst_start      (ecc_if.burst_start),
        .rd_out_valid     (ecc_if.rd_out_valid),
        .rd_data_out      (ecc_if.rd_data_out),
        .sev_out          (ecc_if.sev_out),

        // Encoder output
        .enc_valid_out    (ecc_if.enc_valid_out),
        .enc_codeword_out (ecc_if.enc_codeword_out),

        // Status flags
        .error_detected   (ecc_if.error_detected),
        .error_corrected  (ecc_if.error_corrected),
        .uncorrectable    (ecc_if.uncorrectable)
    );

    // UVM configuration and test execution
    initial begin
        // Set virtual interface in config_db
        uvm_config_db#(virtual ecc_interface)::set(null, "*", "ecc_vif", ecc_if);

        // Dump waveforms
        $dumpfile("ecc_tb.vcd");
        $dumpvars(0, ecc_top);

        // Run test
        run_test();
    end

    // Timeout watchdog
    initial begin
        #10000000;  // 10ms timeout
        `uvm_fatal("TIMEOUT", "Simulation timeout - test did not complete")
    end

endmodule
