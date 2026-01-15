module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic clk, rst_n;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #20 rst_n = 1;
    end

    // Interface instantiation
    rs_if inf(clk, rst_n);

    // RTL Instantiation
    rs_encoder dut (
        .clk(inf.clk),
        .rst_n(inf.rst_n),
        .din(inf.data_in),
        .din_valid(inf.data_in_valid),
        .dout(inf.data_out),
        .dout_valid(inf.data_out_valid),
        .ready(inf.ready)
    );

    initial begin
        // Pass the interface to UVM database
        uvm_config_db#(virtual rs_if)::set(null, "*", "vif", inf);
        run_test("rs_base_test"); // Start the test
    end
endmodule