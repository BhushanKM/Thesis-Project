//////////////////////////////////////////////////////////////////////////////////
// ECC Sequencer - Transaction Sequencer
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_sequencer_c extends uvm_sequencer #(ecc_transaction);

    `uvm_component_utils(ecc_sequencer_c)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
