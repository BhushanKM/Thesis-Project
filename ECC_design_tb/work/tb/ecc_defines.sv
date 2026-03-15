//////////////////////////////////////////////////////////////////////////////////
// ECC Defines - Constants and Parameters for RS16(19,17) ECC Engine
// Target: HBM3/HBM4 Memory Systems
//////////////////////////////////////////////////////////////////////////////////

`ifndef ECC_DEFINES_SV
`define ECC_DEFINES_SV

// Data and Codeword Widths
`define DATA_WIDTH       272    // 17 symbols x 16 bits
`define CODEWORD_WIDTH   304    // 19 symbols x 16 bits
`define SYMBOL_WIDTH     16     // GF(2^16) symbol size
`define NUM_DATA_SYMBOLS 17
`define NUM_PARITY_SYMBOLS 2
`define NUM_TOTAL_SYMBOLS 19

// GF(2^16) Parameters
`define GF_PRIMITIVE_POLY 16'h002B  // x^16 + x^5 + x^3 + x + 1

// T-values for H-matrix (alpha^(n-1-i) where n=19)
`define T0  16'h00AC   // alpha^18
`define T1  16'h0056   // alpha^17
`define T2  16'h002B   // alpha^16
`define T3  16'h8000   // alpha^15
`define T4  16'h4000   // alpha^14
`define T5  16'h2000   // alpha^13
`define T6  16'h1000   // alpha^12
`define T7  16'h0800   // alpha^11
`define T8  16'h0400   // alpha^10
`define T9  16'h0200   // alpha^9
`define T10 16'h0100   // alpha^8
`define T11 16'h0080   // alpha^7
`define T12 16'h0040   // alpha^6
`define T13 16'h0020   // alpha^5
`define T14 16'h0010   // alpha^4
`define T15 16'h0008   // alpha^3
`define T16 16'h0004   // alpha^2
`define T17 16'h0002   // alpha^1 (P0)
`define T18 16'h0001   // alpha^0 (P1)

// Severity Encoding (JEDEC HBM4)
`define SEV_NE  2'b00  // No Error
`define SEV_CEs 2'b01  // Corrected single-bit error
`define SEV_UE  2'b10  // Uncorrectable Error
`define SEV_CEm 2'b11  // Corrected multi-bit error

// Error Types
typedef enum bit [2:0] {
    NO_ERROR = 3'b000,
    SBE      = 3'b001,  // Single Bit Error
    DBE      = 3'b010,  // Double Bit Error (different symbols)
    SSE      = 3'b011,  // Single Symbol Error (≤16 bits in one symbol)
    DASE     = 3'b100,  // Double Adjacent Symbol Error (detectable only)
    RANDOM   = 3'b101   // Random error pattern
} error_type_e;

`endif
