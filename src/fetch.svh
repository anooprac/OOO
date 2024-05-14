`ifndef FETCH_SVH
`define FETCH_SVH

`include "opcodes.svh"

function opcodes_t decode_opcode(logic [31:0] current_insn);
// $display("curr insn = %h", current_insn);

  if (current_insn[31:21] == 11'b11111000010 && current_insn[11:10] == 2'b00) return OP_LDUR;
  if (current_insn[31:22] == 10'b1010100101) return OP_LDP;
  if (current_insn[31] == 1'b1 && current_insn[29:21] == 9'b111000000 && current_insn[11:10] == 2'b00) return OP_STUR;
  if (current_insn[31:22] == 10'b1010100100) return OP_STP;

  if (current_insn[31:23] == 9'b111100101) return OP_MOVK;
  if (current_insn[31:23] == 9'b110100101) return OP_MOVZ;
  if (current_insn[31] == 1'b0 && current_insn[28:24] == 5'b10000) return OP_ADR;
  if (current_insn[31] == 1'b1 && current_insn[28:24] == 5'b10000) return OP_ADRP;

  if (current_insn[31:16] == 16'b1001101010011111 && current_insn[11:5] == 7'b0111111) return OP_CSET;
  if (current_insn[31:16] == 16'b1101101010011111 && current_insn[11:5] == 7'b0011111) return OP_CSETM;
  if (current_insn[31:21] == 11'b10011010100 && current_insn[11:10] == 2'b01) return OP_CINC;
  if (current_insn[31:21] == 11'b11011010100 && current_insn[11:10] == 2'b00) return OP_CINV;
  if (current_insn[31:21] == 11'b11011010100 && current_insn[11:10] == 2'b01) return OP_CNEG;
  if (current_insn[31:21] == 11'b10011010100 && current_insn[11:10] == 2'b00) return OP_CSEL;
  if (current_insn[31:16] == 11'b10011010100 && current_insn[11:10] == 2'b01) return OP_CSINC;
  if (current_insn[31:21] == 11'b11011010100 && current_insn[11:10] == 2'b00) return OP_CSINV;
  if (current_insn[31:21] == 11'b11011010100 && current_insn[11:10] == 2'b01) return OP_CSNEG;

  if (current_insn[31:21] == 11'b11101011000 && current_insn[15:10] == 6'b000000 && current_insn[4:0] == 5'b11111) return OP_CMP;
  if (current_insn[31:21] == 11'b11101010000 && current_insn[15:10] == 6'b000000 && current_insn[4:0] == 5'b11111) return OP_TST;
  if (current_insn[31:21] == 11'b10101011000 && current_insn[15:10] == 6'b000000) return OP_ADDS;
  if (current_insn[31:21] == 11'b11101011000 && current_insn[15:10] == 6'b000000) return OP_SUBS;
  if (current_insn[31:21] == 11'b10101010001 && current_insn[15:5] == 11'b00000011111) return OP_MVN;
  if (current_insn[31:21] == 11'b10101010000 && current_insn[15:10] == 6'b000000) return OP_ORR;
  if (current_insn[31:21] == 11'b11001010000 && current_insn[15:10] == 6'b000000) return OP_EOR;
  if (current_insn[31:21] == 11'b11101010000 && current_insn[15:10] == 6'b000000) return OP_ANDS;
  if (current_insn[31:22] == 10'b1101001101 && current_insn[15:10] == 6'b111111) return OP_LSR;
  if (current_insn[31:22] == 10'b1001001101 && current_insn[15:10] == 6'b111111) return OP_ASR;
  if (current_insn[31:21] == 11'b10010001000) return OP_ADD;
  if (current_insn[31:22] == 10'b1101000100) return OP_SUB;
  if (current_insn[31:23] == 9'b100100100) return OP_AND; // TODO: Spreadsheet says 9'b100100100, but that doesn't work with testcase and conflicts manual
  if (current_insn[31:22] == 10'b1101001101) return OP_LSL;
  if (current_insn[31:23] == 9'b100100110) return OP_SBFM;
  if (current_insn[31:23] == 9'b110100110) return OP_UBFM;

  if (current_insn[31:26] == 6'b000101) return OP_B;
  if (current_insn[31:10] == 22'b1101011000011111000000 && current_insn[4:0] == 5'b00000) return OP_BR;
  if (current_insn[31:24] == 8'b01010100 && current_insn[4] == 0) return OP_Bcond;
  if (current_insn[31:26] == 6'b100101) return OP_BL;
  if (current_insn[31:10] == 22'b1101011000111111000000 && current_insn[4:0] == 5'b00000) return OP_BLR;
  if (current_insn[31:24] == 8'b10110101) return OP_CBNZ;
  if (current_insn[31:24] == 8'b10110100) return OP_CBZ;
  if (current_insn[31:10] == 22'b1101011001011111000000 && current_insn[4:0] == 5'b00000) return OP_RET;
  if (current_insn == 32'b11010101000000110010000000011111) return OP_NOP;
  if (current_insn[31:21] == 11'b11010100010 && current_insn[4:0] == 5'b00000) return OP_HLT;
  return OP_ERR;	
  // Everyone else v															
endfunction

function opcodes_t decide_alias_op(opcodes_t current_op);
  case (current_op)
    OP_CINC: return OP_CSINC;
    OP_CINV: return OP_CSINV;
    OP_CNEG: return OP_CSNEG;
    OP_CSET: return OP_CSINC;
    OP_CSETM: return OP_CSINV;
    OP_CMP: return OP_SUBS;
    OP_TST: return OP_ANDS;
    OP_LSL: return OP_UBFM;
    OP_LSR: return OP_UBFM;
    OP_ASR: return OP_SBFM;
    default: return current_op;
  endcase
endfunction

`endif