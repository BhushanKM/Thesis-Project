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

endpackage
