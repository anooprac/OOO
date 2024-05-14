`ifndef OPCODES_SVH
`define OPCODES_SVH

parameter MAX_OP_WIDTH = 11;
parameter INSN_WIDTH = 32;
parameter MAX_IMM = 64;

parameter LDP =	    11'b10101000110;
parameter LDUR =	11'b11111000010;
parameter STUR =	11'b11111000000;
parameter STP =	    11'b10101000100;
parameter MOVK =	11'b11110010100;
parameter MOVZ =	11'b11010010100;
parameter ADR =	    11'b00010000000;
parameter ADRP =	11'b10010000000;
parameter CINC =	11'b10011010100;
parameter CINV =	11'b11011010100;
parameter CNEG =	11'b11011010100;
parameter CSEL =	11'b10011010100;
parameter CSET =	11'b10011010100;
parameter CSETM =	11'b11011010100;
parameter CSINC =	11'b10011010100;
parameter CSINV =	11'b11011010100;
parameter CSNEG =	11'b11011010100;
parameter ADD =	    11'b10010001000;
parameter ADDS =	11'b10101011000;
parameter SUB =	    11'b11010001000;
parameter SUBS =	11'b11101011000;
parameter CMP =	    11'b11101011000;
parameter MVN =	    11'b10101010001;
parameter ORR =	    11'b10101010000;
parameter EOR =	    11'b11001010000;
parameter AND =	    11'b10010010000;
parameter ANDS =	11'b11101010000;
parameter TST =	    11'b11101010000;
parameter LSL =	    11'b11010011010;
parameter LSR =	    11'b11010011010;
parameter SBFM =	11'b10010011100;
parameter UBFM =	11'b11010011000;
parameter ASR =	    11'b10010011010;
parameter B =	    11'b00010100000;
parameter BR =	    11'b11010110000;
parameter Bcond =	11'b01010100000;
parameter BL =	    11'b10010100000;
parameter BLR =	    11'b11010110001;
parameter CBNZ =	11'b10110101000;
parameter CBZ =	    11'b10110100000;
parameter RET =	    11'b11010110010;
parameter NOP =	    11'b11010101000;
parameter HLT =	    11'b11010100010;

typedef enum {
OP_LDUR,  // M 0
OP_LDP, // M2 1
OP_STUR, // M 2
OP_STP, // M2 3
OP_MOVK, // I1 4
OP_MOVZ, // I1 5
OP_ADR, // I2 6
OP_ADRP, // I2 7
OP_CINC, // RC 8
OP_CINV, // RC 9
OP_CNEG, // RC 10
OP_CSEL, // RC 11
OP_CSET, // RC 12
OP_CSETM, //RC 13
OP_CSINC, //RC 14
OP_CSINV, //RC 15
OP_CSNEG, //RC 16
OP_ADD, // RI 17
OP_ADDS, // RR 18
OP_SUB, // RI 19
OP_SUBS, // RR 20
OP_CMP, // RR 21
OP_MVN, // RR 22
OP_ORR, // RR 23
OP_EOR, // RR 24
OP_AND, // RI 25
OP_ANDS, // RR 26
OP_TST, // RR 27
OP_LSL, // RI 28
OP_LSR, // RI 29
OP_SBFM, // RI 30
OP_UBFM, // RI 31
OP_ASR, // RI 32
OP_B, // B1 33
OP_BR, // B3 34
OP_Bcond, // B2 35
OP_BL, // B1 36
OP_BLR, // B3 37
OP_CBNZ, // I2 38
OP_CBZ, // I2 39
OP_RET, // B3 40
OP_NOP, // S 41
OP_HLT, // S 42
OP_ERR // 43
} opcodes_t;


`endif
