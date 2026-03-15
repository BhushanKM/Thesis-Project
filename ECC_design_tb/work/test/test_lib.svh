///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Test Library
// RS16(19,17) ECC Engine for HBM3/HBM4
// Based on Texas A&M CSCE 616 test structure
///////////////////////////////////////////////////////////////////////////

// Base test - must be included first
`include "ecc_base_test.sv"

// Individual error type tests
`include "ecc_no_error_test.sv"
`include "ecc_simple_random_test.sv"
`include "ecc_sbe_random_test.sv"
`include "ecc_sbe_exhaustive_test.sv"
`include "ecc_dbe_random_test.sv"
`include "ecc_sse_random_test.sv"
`include "ecc_dase_detection_test.sv"
`include "ecc_parity_error_test.sv"

// Special pattern tests
`include "ecc_boundary_test.sv"
`include "ecc_stress_test.sv"
`include "ecc_test_mode_test.sv"

// Combined tests
`include "ecc_comprehensive_test.sv"
`include "ecc_regression_test.sv"
