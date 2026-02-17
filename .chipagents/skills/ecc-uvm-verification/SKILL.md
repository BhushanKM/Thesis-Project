---
name: ecc-uvm-verification
description: UVM testbench development for Galois Field ECC engines targeting HBM3/HBM4 memory systems
keywords: ecc uvm testbench galois reed-solomon hbm verification error-correction gf16
---

# ECC UVM Verification Skill

Use this skill to develop UVM testbenches for Error Correction Code (ECC) engines, specifically RS16(19,17) codes used in HBM3/HBM4 memory systems.

## Architecture Overview

### ECC Engine Components
- **Encoder:** RS16(19,17) - 272-bit data → 304-bit codeword (32-bit parity)
- **Decoder:** DBB-ECC with SSE/DBE correction capability
- **GF Arithmetic:** GF(2^16) with primitive polynomial x^16 + x^5 + x^3 + x + 1

### Error Types Supported
| Type | Description | Correction |
|------|-------------|------------|
| SBE | Single Bit Error | ✓ Correctable |
| DBE | Double Bit Error (different symbols) | ✓ Correctable |
| SSE | Single Symbol Error (≤16 bits in one symbol) | ✓ Correctable |
| DASE | Double Adjacent Symbol Error | Detectable only |

## UVM Testbench Structure

```
ecc_tb/
├── ecc_defines.sv      # Constants: DATA_WIDTH=272, CODEWORD_WIDTH=304
├── ecc_interface.sv    # Clocking blocks, modports, assertions
├── ecc_transaction.sv  # Sequence item with error injection fields
├── ecc_driver_c.sv     # Drives transactions with error injection
├── ecc_monitor_c.sv    # Monitors and collects coverage
├── ecc_scoreboard_c.sv # Reference model comparison
├── ecc_agent_c.sv      # Agent packaging
├── ecc_env.sv          # Environment with coverage
├── ecc_seqs.sv         # Error injection sequences
├── ecc_test.sv         # Test scenarios
├── ecc_pkg.sv          # Package compilation order
└── ecc_top.sv          # Top module with DUT instantiation
```

## Key Implementation Patterns

### 1. Transaction with Error Injection
```systemverilog
class ecc_transaction extends uvm_sequence_item;
    rand bit [271:0] data;
    rand error_type_e error_type;  // NO_ERROR, SBE, DBE, SSE, DASE
    rand bit [4:0] error_symbol_0; // 0-16 for data, 17-18 for parity
    rand bit [4:0] error_symbol_1;
    rand bit [15:0] error_pattern_0;
    rand bit [15:0] error_pattern_1;

    constraint valid_symbols {
        error_symbol_0 inside {[0:18]};
        error_symbol_1 inside {[0:18]};
        error_symbol_0 != error_symbol_1;
    }

    constraint sbe_constraint {
        error_type == SBE -> $countones(error_pattern_0) == 1;
    }
endclass
```

### 2. Reference Model in Scoreboard
```systemverilog
// GF(2^16) multiplication for reference model
function bit [15:0] gf_mul(bit [15:0] a, bit [15:0] b);
    bit [15:0] result = 0;
    bit [15:0] temp_a = a;
    for (int i = 0; i < 16; i++) begin
        if (b[i]) result ^= temp_a;
        if (temp_a[15]) temp_a = (temp_a << 1) ^ 16'h002B;
        else temp_a = temp_a << 1;
    end
    return result;
endfunction

// Syndrome computation
function void compute_syndromes(bit [303:0] codeword, output bit [15:0] s0, s1);
    s0 = 0; s1 = 0;
    for (int i = 0; i < 19; i++) begin
        bit [15:0] symbol = codeword[i*16 +: 16];
        s0 ^= symbol;
        s1 ^= gf_mul(T_VALUES[i], symbol);
    end
endfunction
```

### 3. Error Injection Sequences
```systemverilog
// Single Bit Error sequence
class sbe_sequence extends uvm_sequence #(ecc_transaction);
    task body();
        repeat(1000) begin
            `uvm_do_with(req, {
                error_type == SBE;
                $countones(error_pattern_0) == 1;
            })
        end
    endtask
endclass

// Double Bit Error sequence (different symbols)
class dbe_sequence extends uvm_sequence #(ecc_transaction);
    task body();
        repeat(1000) begin
            `uvm_do_with(req, {
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
                error_symbol_0 != error_symbol_1;
            })
        end
    endtask
endclass
```

### 4. Functional Coverage
```systemverilog
covergroup error_coverage;
    error_type_cp: coverpoint txn.error_type {
        bins no_error = {NO_ERROR};
        bins sbe = {SBE};
        bins dbe = {DBE};
        bins sse = {SSE};
    }

    symbol_position_cp: coverpoint txn.error_symbol_0 {
        bins data_symbols[] = {[0:16]};
        bins parity_p0 = {17};
        bins parity_p1 = {18};
    }

    bit_position_cp: coverpoint $clog2(txn.error_pattern_0) {
        bins bit_pos[] = {[0:15]};
    }

    // Cross coverage
    error_x_symbol: cross error_type_cp, symbol_position_cp;
endgroup
```

### 5. JEDEC Severity Encoding Check
```systemverilog
// Expected severity based on error type
function bit [1:0] expected_severity(error_type_e err_type, bit correctable);
    case (err_type)
        NO_ERROR: return 2'b00;  // NE: No Error
        SBE:      return 2'b01;  // CEs: Corrected single-bit
        DBE, SSE: return correctable ? 2'b11 : 2'b10;  // CEm or UE
        default:  return 2'b10;  // UE: Uncorrectable
    endcase
endfunction
```

## Test Scenarios

1. **Basic Functionality:** No-error encode/decode
2. **SBE Coverage:** All 304 bit positions
3. **DBE Coverage:** Random symbol pairs with single-bit errors
4. **SSE Coverage:** Multi-bit errors within single symbol
5. **Boundary Cases:** All-zeros, all-ones, alternating patterns
6. **Stress Test:** Back-to-back transactions
7. **Corner Cases:** Errors in parity symbols

## GF(2^16) Arithmetic Reference

```
Primitive Polynomial: x^16 + x^5 + x^3 + x + 1 (0x1002B)
Reduction mask: 0x002B

T-values for H-matrix (RS16 19,17):
T[0]=0x00AC, T[1]=0x0056, T[2]=0x002B
T[3..16] = 0x8000, 0x4000, ..., 0x0004 (powers of 2)
```

## Running the Testbench

```bash
# Compile and run with VCS
vcs -sverilog -ntb_opts uvm-1.2 \
    ecc_pkg.sv ecc_top.sv \
    -top ecc_top -o simv
./simv +UVM_TESTNAME=ecc_comprehensive_test

# Compile and run with Questa
vlog -sv +incdir+$UVM_HOME/src ecc_pkg.sv ecc_top.sv
vsim -c ecc_top +UVM_TESTNAME=ecc_comprehensive_test -do "run -all"
```

## Files Reference

See `ECC_1bit/ECC_1bit.srcs/sim_1/new/` for complete implementation:
- RTL: `sources_1/new/ecc_encoder.v`, `ecc_decoder.v`, `gf_mul_16.v`
- TB: `sim_1/new/ecc_*.sv`
