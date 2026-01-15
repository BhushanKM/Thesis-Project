interface rs_if(input logic clk, input logic rst_n);
    logic [15:0] data_in;
    logic        data_in_valid;
    logic [15:0] data_out;
    logic        data_out_valid;
    logic        ready;

    // Clocking block for synchronous driving/sampling
    clocking drv_cb @(posedge clk);
        output data_in, data_in_valid;
        input  ready;
    endclocking

    clocking mon_cb @(posedge clk);
        input data_out, data_out_valid, data_in, data_in_valid;
    endclocking
endinterface