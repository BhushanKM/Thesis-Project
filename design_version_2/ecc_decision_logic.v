module ecc_decision_logic(

input no_error,
input sse_found,
input dbe_w2_found,
input dbe_w1_found,
input dbe_w0_found,

output use_sse,
output use_dbe_w2,
output use_dbe_w1,
output use_dbe_w0,

output error_detected,
output error_corrected,
output multi_bit_error,
output uncorrectable
);

assign use_sse    = sse_found;
assign use_dbe_w2 = dbe_w2_found & ~use_sse;
assign use_dbe_w1 = dbe_w1_found & ~use_sse & ~use_dbe_w2;
assign use_dbe_w0 = dbe_w0_found & ~use_sse & ~use_dbe_w2 & ~use_dbe_w1;

assign error_detected  = ~no_error;
assign error_corrected = use_sse | use_dbe_w2 | use_dbe_w1 | use_dbe_w0;
assign multi_bit_error = use_dbe_w2 | use_dbe_w1 | use_dbe_w0;
assign uncorrectable   = ~no_error & ~error_corrected;

endmodule