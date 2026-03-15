//////////////////////////////////////////////////////////////////////////////////
// ECC Package - UVM Package with Compilation Order
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

package ecc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Include defines
    `include "ecc_defines.sv"

    // Include UVM components in dependency order
    `include "ecc_transaction.sv"
    `include "ecc_sequencer_c.sv"
    `include "ecc_driver_c.sv"
    `include "ecc_monitor_c.sv"
    `include "ecc_scoreboard_c.sv"
    `include "ecc_agent_c.sv"
    `include "ecc_env.sv"
    `include "ecc_seqs.sv"
    `include "ecc_test.sv"

    // Include additional test files from ../test/ folder (only unique ones)
    `include "../test/ecc_simple_random_test.sv"
    `include "../test/ecc_no_error_test.sv"
    `include "../test/ecc_sbe_random_test.sv"
    `include "../test/ecc_sbe_exhaustive_test.sv"
    `include "../test/ecc_dbe_random_test.sv"
    `include "../test/ecc_sse_random_test.sv"
    `include "../test/ecc_dase_detection_test.sv"
    `include "../test/ecc_parity_error_test.sv"

endpackage
