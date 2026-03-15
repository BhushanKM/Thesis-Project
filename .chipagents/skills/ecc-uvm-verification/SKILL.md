---
name: ecc-uvm-verification
description: UVM testbench development for Galois Field ECC engines targeting HBM3/HBM4 memory systems
keywords: ecc uvm testbench galois reed-solomon hbm verification error-correction gf16 dbb-ecc jedec
---

# ECC UVM Verification Skill

Use this skill to develop UVM testbenches for Error Correction Code (ECC) engines, specifically RS16(19,17) codes used in HBM3/HBM4 memory systems.

## Project Structure

```
thesis_project/
├── Design/                    # RTL implementation
│   ├── ecc_engine_top.v       # Top-level with JEDEC test mode & severity
│   ├── ecc_encoder.v          # RS16(19,17) encoder
│   ├── ecc_decoder.v          # DBB-ECC decoder with SSE/DBE correction
│   ├── gf_mul_16.v            # Optimized GF(2^16) multiplier
│   ├── ecc_timing.sdc         # Timing constraints
│   └── ECC_1bit_netlist.v     # Synthesized netlist
│
└── UVM_Test_Bench/            # UVM verification environment
    ├── ecc_defines.sv         # Constants & parameters
    ├── ecc_interface.sv       # Clocking blocks, modports
    ├── ecc_transaction.sv     # Sequence item with error injection
    ├── ecc_driver_c.sv        # Transaction driver
    ├── ecc_monitor_c.sv       # Output monitor
    ├── ecc_scoreboard_c.sv    # Reference model & checking
    ├── ecc_agent_c.sv         # Agent packaging
    ├── ecc_sequencer_c.sv     # Sequencer
    ├── ecc_env.sv             # Environment
    ├── ecc_seqs.sv            # Error injection sequences
    ├── ecc_test.sv            # Test scenarios
    ├── ecc_pkg.sv             # Package compilation
    ├── ecc_top.sv             # Top module with DUT
    ├── tests/                 # Additional test files
    └── Makefile               # Build automation
```

## Architecture Overview

### ECC Engine Components
- **Encoder:** RS16(19,17) - 272-bit data → 304-bit codeword (32-bit parity)
- **Decoder:** DBB-ECC with syndrome-based SSE/DBE correction
- **GF Arithmetic:** GF(2^16) with primitive polynomial x^16 + x^5 + x^3 + x + 1
- **Test Mode:** JEDEC HBM4 compliant (MR9 OP2/OP3) with CW0/CW1 patterns
- **Severity Output:** BL8 burst-timed SEV[1:0] encoding

### Error Types Supported
| Type | Description | Correction | Severity |
|------|-------------|------------|----------|
| SBE | Single Bit Error | ✓ Correctable | CEs (2'b01) |
| DBE | Double Bit Error (different symbols) | ✓ Correctable | CEm (2'b11) |
| SSE | Single Symbol Error (≤16 bits in one symbol) | ✓ Correctable | CEm (2'b11) |
| DASE | Double Adjacent Symbol Error | Detectable only | UE (2'b10) |

### Decoder Architecture (Weight-Based DBE Locator)
The decoder uses S0 Hamming weight to classify and locate errors:

| S0 Weight | Error Type | Detection Method |
|-----------|------------|------------------|
| 0 | No error OR identical SBEs | S1=0 → no error; S1≠0 → DBE Type 1/2 |
| 1 | SBE in data + SBE in P1 | Type 3: Ti*S0 ⊕ Ep1 ⊕ S1 = 0 |
| 2 | Two SBEs in different symbols | Type 1/2: Ti*Ej0 ⊕ Tj*Ej1 ⊕ S1 = 0 |
| >2 | SSE (multi-bit in one symbol) | Standard RS: Ti*S0 ⊕ S1 = 0 |

## RTL Implementation Details

### Top-Level Ports (ecc_engine_top)
```verilog
module ecc_engine_top (
    input  wire         clk,
    input  wire         rst_n,
    // Control
    input  wire         test_mode_en,     // MR9 OP2
    input  wire         cw_sel,           // MR9 OP3: 0=CW0, 1=CW1
    // Write path
    input  wire         wr_valid,
    input  wire [271:0] wr_data,
    output wire         wr_ready,
    // Read path
    input  wire         rd_valid,
    input  wire [303:0] rd_codeword,
    input  wire         burst_start,
    output reg          rd_out_valid,
    output reg  [271:0] rd_data_out,
    output wire [1:0]   sev_out,          // JEDEC severity
    // Encoder output
    output wire         enc_valid_out,
    output wire [303:0] enc_codeword_out,
    // Status
    output reg          error_detected,
    output reg          error_corrected,
    output reg          uncorrectable
);
```

### GF Multiplier Optimization Features
```verilog
module gf_mul_16_opt #(
    parameter REGISTERED      = 1,  // 0=comb, 1=registered
    parameter PIPELINE_STAGES = 0,  // For high-frequency
    parameter CLOCK_GATING    = 1,  // Power savings
    parameter OPERAND_ISOLATE = 1   // Gate inputs when invalid
);
// Features:
// - Zero-operand bypass (a=0 or b=0 → p=0)
// - Balanced 4-level XOR tree for timing
// - Clock gating on output register
// - Operand isolation for power
```

## UVM Testbench Implementation

### Transaction Class
```systemverilog
class ecc_transaction extends uvm_sequence_item;
    rand bit [`DATA_WIDTH-1:0]     data;
    rand bit [`CODEWORD_WIDTH-1:0] codeword;
    rand error_type_e error_type;      // NO_ERROR, SBE, DBE, SSE, DASE, RANDOM
    rand bit [4:0]    error_symbol_0;  // 0-16 data, 17=P0, 18=P1
    rand bit [4:0]    error_symbol_1;
    rand bit [15:0]   error_pattern_0;
    rand bit [15:0]   error_pattern_1;
    rand bit          test_mode;
    rand bit          cw_sel;
    rand int unsigned delay;

    // Expected outputs for scoreboard
    bit [`DATA_WIDTH-1:0] expected_data;
    bit [1:0]             expected_severity;
    bit                   expected_error_detected;
    bit                   expected_error_corrected;
    bit                   expected_uncorrectable;

    // Key constraints
    constraint c_sbe { error_type == SBE -> $countones(error_pattern_0) == 1; }
    constraint c_dbe { error_type == DBE -> {
        $countones(error_pattern_0) == 1;
        $countones(error_pattern_1) == 1;
        error_symbol_0 != error_symbol_1;
    }}
    constraint c_sse { error_type == SSE -> $countones(error_pattern_0) inside {[2:16]}; }
    constraint c_dase { error_type == DASE -> {
        (error_symbol_1 == error_symbol_0 + 1) || (error_symbol_0 == error_symbol_1 + 1);
    }}

    // Error injection function
    function bit [`CODEWORD_WIDTH-1:0] inject_error(bit [`CODEWORD_WIDTH-1:0] clean_cw);
    // Compute expected outputs
    function void compute_expected();
endclass
```

### Reference Model (Scoreboard)
```systemverilog
class ecc_scoreboard_c extends uvm_scoreboard;
    // T-values for reference model
    bit [15:0] T_VALUES[19] = '{
        16'h00AC, 16'h0056, 16'h002B,  // T0-T2 (alpha^18, alpha^17, alpha^16)
        16'h8000, 16'h4000, 16'h2000, 16'h1000,  // T3-T6
        16'h0800, 16'h0400, 16'h0200, 16'h0100,  // T7-T10
        16'h0080, 16'h0040, 16'h0020, 16'h0010,  // T11-T14
        16'h0008, 16'h0004, 16'h0002, 16'h0001   // T15-T18
    };

    // GF(2^16) multiplication
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
    function void compute_syndromes(bit [303:0] codeword, output bit [15:0] S0, S1);
        bit [15:0] symbols[19];
        for (int i = 0; i < 19; i++)
            symbols[i] = codeword[(`CODEWORD_WIDTH - 1 - i*16) -: 16];
        S0 = 0; S1 = 0;
        for (int i = 0; i < 19; i++) begin
            S0 ^= symbols[i];
            S1 ^= gf_mul(T_VALUES[i], symbols[i]);
        end
    endfunction
endclass
```

### Available Sequences
| Sequence | Description | Transactions |
|----------|-------------|--------------|
| `no_error_seq` | Basic functionality | 10-50 |
| `sbe_seq` | Random SBE injection | 100-500 |
| `sbe_exhaustive_seq` | All 304 bit positions | 304 |
| `dbe_seq` | Double bit errors | 100-500 |
| `sse_seq` | Multi-bit symbol errors | 100-500 |
| `dase_seq` | Adjacent symbol errors (UE) | 20-100 |
| `boundary_seq` | Edge cases (0s, 1s, alternating) | ~25 |
| `mixed_error_seq` | Weighted random mix | 200-1000 |
| `stress_seq` | Back-to-back, no delay | 500-2000 |
| `test_mode_seq` | JEDEC test mode CW0/CW1 | 40 |

### Available Tests
| Test | Description |
|------|-------------|
| `ecc_sanity_test` | Quick functionality check |
| `ecc_sbe_test` | Exhaustive SBE (304 positions) |
| `ecc_dbe_test` | DBE correction |
| `ecc_sse_test` | SSE correction |
| `ecc_dase_test` | DASE detection (uncorrectable) |
| `ecc_boundary_test` | Edge cases |
| `ecc_comprehensive_test` | All error types |
| `ecc_stress_test` | High throughput |
| `ecc_test_mode_test` | JEDEC test mode |
| `ecc_regression_test` | Full regression suite |

## GF(2^16) Arithmetic Reference

```
Primitive Polynomial: x^16 + x^5 + x^3 + x + 1
Reduction constant:   0x002B

T-values for H-matrix (RS16 19,17):
  T[0]  = 0x00AC  (alpha^18)
  T[1]  = 0x0056  (alpha^17)
  T[2]  = 0x002B  (alpha^16)
  T[3]  = 0x8000  (alpha^15)
  T[4]  = 0x4000  (alpha^14)
  T[5]  = 0x2000  (alpha^13)
  T[6]  = 0x1000  (alpha^12)
  T[7]  = 0x0800  (alpha^11)
  T[8]  = 0x0400  (alpha^10)
  T[9]  = 0x0200  (alpha^9)
  T[10] = 0x0100  (alpha^8)
  T[11] = 0x0080  (alpha^7)
  T[12] = 0x0040  (alpha^6)
  T[13] = 0x0020  (alpha^5)
  T[14] = 0x0010  (alpha^4)
  T[15] = 0x0008  (alpha^3)
  T[16] = 0x0004  (alpha^2)
  T[17] = 0x0002  (alpha^1) - P0
  T[18] = 0x0001  (alpha^0) - P1

Parity Generation:
  P0 = D0 ⊕ D1 ⊕ ... ⊕ D16
  P1 = T0·D0 ⊕ T1·D1 ⊕ ... ⊕ T16·D16
```

## JEDEC Severity Encoding

```
SEV[1:0] Encoding (per JEDEC Standard No. 270-4 Section 6.9.6):
  2'b00 = NE  (No Error)
  2'b01 = CEs (Corrected single-bit error)
  2'b11 = CEm (Corrected multi-bit error within symbol)
  2'b10 = UE  (Uncorrectable Error)

BL8 Burst Timing:
  Positions 0-3: SEV = 2'b00 (inactive)
  Positions 4-7: SEV = actual severity
```

## Running the Testbench

```bash
# Using Makefile in UVM_Test_Bench/
cd UVM_Test_Bench
make compile
make run TEST=ecc_sanity_test
make run TEST=ecc_comprehensive_test
make run TEST=ecc_regression_test

# Manual VCS
vcs -sverilog -ntb_opts uvm-1.2 \
    -f filelist.f \
    -top ecc_top -o simv
./simv +UVM_TESTNAME=ecc_comprehensive_test +UVM_VERBOSITY=UVM_MEDIUM

# Manual Questa
vlog -sv +incdir+$UVM_HOME/src -f filelist.f
vsim -c ecc_top +UVM_TESTNAME=ecc_regression_test -do "run -all"

# Xcelium
xrun -uvm -uvmhome CDNS-1.2 \
    -f filelist.f \
    +UVM_TESTNAME=ecc_stress_test
```

## Coverage Goals

| Coverage Type | Target |
|---------------|--------|
| Error types (NO_ERROR, SBE, DBE, SSE, DASE) | 100% |
| Symbol positions (0-18) | 100% |
| Bit positions (0-15) per symbol | 100% |
| Error type × Symbol cross | 95%+ |
| Parity symbol errors (P0, P1) | 100% |
| Boundary patterns | 100% |
| Test mode (CW0, CW1) | 100% |

## Files Reference

**RTL (Design/):**
- `ecc_engine_top.v` - Top-level with test mode, severity burst generator
- `ecc_encoder.v` - H-matrix based encoder with 17 GF multipliers
- `ecc_decoder.v` - DBB-ECC decoder (~100 GF multipliers for parallel locators)
- `gf_mul_16.v` - Parameterized GF multiplier (comb/registered variants)

**UVM (UVM_Test_Bench/):**
- `ecc_pkg.sv` - Package with all class includes
- `ecc_top.sv` - Top module, DUT instantiation, config_db setup
- `ecc_test.sv` - 10 test scenarios
- `ecc_seqs.sv` - 9 sequence types
- `ecc_scoreboard_c.sv` - Reference model with pass/fail reporting
