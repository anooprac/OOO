`ifndef DECODE_SVH
`define DECODE_SVH

`include "opcodes.svh"
`include "utils.svh"
typedef enum {
  C_EQ,
  C_NE,
  C_CS,
  C_CC,
  C_MI,
  C_PL,
  C_VS,
  C_VC,
  C_HI,
  C_LS,
  C_GE,
  C_LT,
  C_GT,
  C_LE,
  C_AL,
  C_NV,
  C_ERROR = -1
} cond_t;

// Define a struct to encapsulate all necessary outputs of the decoding process
typedef struct packed {
    logic [$clog2(NUM_REGS)-1:0] reg_a_idx;
    logic [$clog2(NUM_REGS)-1:0] reg_b_idx;
    logic [$clog2(NUM_REGS)-1:0] reg_c_idx;
    logic [$clog2(NUM_REGS)-1:0] dest_reg_idx;
    logic [$clog2(NUM_REGS)-1:0] dest2_reg_idx;
    logic [63:0] val_imm;
    logic [3:0] cond;
    logic goto_alu_rs;
    logic [2:0] D_X_sigs = 3'b000;
    logic [2:0] D_M_sigs = 3'b000;
    logic [2:0] D_W_sigs = 3'b000;
    logic [5:0] hw;
} decode_outputs_t;

typedef struct packed {
  logic[63:0] wmask;
  logic[63:0] tmask;
} decode_bitmask_outputs_t;



function decode_outputs_t decode_instruction(
    opcodes_t D_current_op,
    logic [31:0] D_current_insn
);
    decode_outputs_t out;

    if (D_current_op == OP_Bcond) begin
      // setup conds
      out.cond = D_current_insn[3:0];
    end else if (
      D_current_op == OP_CINC ||
      D_current_op == OP_CINV ||
      D_current_op == OP_CNEG ||
      D_current_op == OP_CSEL ||
      D_current_op == OP_CSET ||
      D_current_op == OP_CSETM ||
      D_current_op == OP_CSINC ||
      D_current_op == OP_CSINV
    ) begin
      out.cond = D_current_insn[15:12];
    end 


    // halfword
    if (D_current_op == OP_MOVK || D_current_op == OP_MOVZ) begin
      out.hw[1] = D_current_insn[22];
      out.hw[0] = D_current_insn[21];
    end

    // source nzcv
    out.D_X_sigs[2] = (
      D_current_op == OP_CINC ||
      D_current_op == OP_CINV ||
      D_current_op == OP_CNEG ||
      D_current_op == OP_CSEL ||
      D_current_op == OP_CSET ||
      D_current_op == OP_CSETM ||
      D_current_op == OP_CSINC ||
      D_current_op == OP_CSINV ||
      D_current_op == OP_CSNEG ||
      D_current_op == OP_Bcond 
      // D_current_op == OP_CBNZ ||
      // D_current_op == OP_CBZ
    );
    // register?
    out.D_X_sigs[1] = (
      D_current_op == OP_CINC ||
      D_current_op == OP_CINV ||
      D_current_op == OP_CNEG ||
      D_current_op == OP_CSEL ||
      D_current_op == OP_CSET ||
      D_current_op == OP_CSETM ||
      D_current_op == OP_CSINC ||
      D_current_op == OP_CSINV ||
      D_current_op == OP_CSNEG ||
      D_current_op == OP_ADDS ||
      D_current_op == OP_SUBS ||
      D_current_op == OP_CMP ||
      D_current_op == OP_MVN ||
      D_current_op == OP_ORR ||
      D_current_op == OP_EOR ||
      D_current_op == OP_ANDS 
    );

    //set nzcv?
    out.D_X_sigs[0] = (D_current_op == OP_ADDS || D_current_op == OP_ANDS || D_current_op == OP_SUBS || D_current_op == OP_CMP || D_current_op == OP_TST);

    out.D_M_sigs[2] = (D_current_op == OP_STP || D_current_op == OP_LDP);
    // read?
    out.D_M_sigs[1] = (D_current_op == OP_LDUR || D_current_op == OP_LDP);
    // write
    out.D_M_sigs[0] = (D_current_op == OP_STUR || D_current_op == OP_STP);

    // LR?
    out.D_W_sigs[2] = (D_current_op == OP_BL || D_current_op == OP_BLR);
    // i have no clue what this is for but they set it if LDUR (maybe LDP also needs to set this?)
    out.D_W_sigs[1] = (D_current_op == OP_LDUR || D_current_op == OP_LDP);
  
    //write? 
    out.D_W_sigs[0] = !(
      D_current_op == OP_STUR ||
      D_current_op == OP_STP ||
      D_current_op == OP_B ||
      D_current_op == OP_Bcond ||
      D_current_op == OP_RET ||
      D_current_op == OP_NOP ||
      D_current_op == OP_HLT ||
      D_current_op == OP_CMP ||
      D_current_op == OP_TST ||
      D_current_op == OP_CBZ ||
      D_current_op == OP_CBNZ ||
      D_current_op == OP_BR
    );

    out.goto_alu_rs = !(
      D_current_op == LDUR ||
      D_current_op == LDP ||
      D_current_op == STUR ||
      D_current_op == STP
      );

  // $display("in decode op: %s", D_current_op.name());
  // extract regs
  if (
    D_current_op != OP_MOVK && D_current_op != OP_MOVZ && D_current_op != OP_B && D_current_op != OP_Bcond &&
    D_current_op != OP_BL && D_current_op != OP_NOP && D_current_op != OP_HLT && 
    D_current_op != OP_CBZ && D_current_op != OP_CBNZ
  ) begin 
      out.reg_a_idx = D_current_insn[9:5]; //Rn - address register for memory instructions
  end
  else if (D_current_op == OP_CBZ || D_current_op == OP_CBNZ) begin
      out.reg_a_idx = D_current_insn[4:0];
  end

  if ((out.reg_a_idx == SP_NUM) && !(D_current_op == OP_LDUR || D_current_op == OP_STUR || D_current_op == OP_ADD || D_current_op == OP_SUB || D_current_op == OP_STP || D_current_op == OP_LDP)) begin
    out.reg_a_idx = XZR_NUM;
  end

  if (D_current_op == OP_STUR || D_current_op == OP_STP) begin
    out.reg_b_idx = D_current_insn[4:0]; // Rt
  end
  else if (D_current_op == OP_ADD || D_current_op == OP_ADDS || D_current_op == OP_SUB || 
    D_current_op == OP_SUBS || D_current_op == OP_CMP || D_current_op == OP_MVN || 
    D_current_op == OP_ORR || D_current_op == OP_EOR || D_current_op == OP_ANDS || 
    D_current_op == OP_TST || D_current_op == OP_CSEL || D_current_op == OP_CSINV ||
    D_current_op == OP_CSINC || D_current_op == OP_CSNEG || D_current_op == OP_AND || D_current_op == OP_SBFM) begin
      out.reg_b_idx = D_current_insn[20:16];
  end

  if (out.reg_b_idx == SP_NUM) out.reg_b_idx = XZR_NUM;

  if (D_current_op == OP_LDP) begin
    out.dest2_reg_idx = D_current_insn[14:10]; //Rt
  end

  if (D_current_op != OP_B && D_current_op != OP_Bcond &&  D_current_op != OP_NOP && D_current_op != OP_HLT && D_current_op != OP_RET && D_current_op != OP_BL 
  && D_current_op != OP_CBZ && D_current_op != OP_CBNZ && D_current_op != OP_BLR) begin
    out.dest_reg_idx = D_current_insn[4:0];
  end     
  else if (D_current_op == OP_BL || D_current_op == OP_BLR) begin
    out.dest_reg_idx = 30;
  end else if (D_current_op == OP_CBNZ || D_current_op == OP_CBZ || D_current_op == OP_Bcond)
    out.dest_reg_idx = 32;

  
  if (D_current_op == OP_MOVK) begin

     out.reg_a_idx = out.dest_reg_idx;
  end


  if(D_current_op == OP_MOVZ) out.reg_a_idx = XZR_NUM;

  if (D_current_op == OP_STP) begin
    out.reg_c_idx = D_current_insn[14:10]; //Rt2
  end

  if ((SP_NUM ==  out.dest_reg_idx) && !((D_current_op == OP_ADD || D_current_op == OP_SUB))) out.dest_reg_idx = XZR_NUM;
          
//set COND
  if (D_current_op == OP_Bcond) begin
    out.cond = D_current_insn[3:0];
  end
  else if (D_current_op == OP_CSEL || D_current_op == OP_CSINC || D_current_op == OP_CSINV || D_current_op == OP_CSNEG) begin
    out.cond = D_current_insn[15:12];
  end  
  // $display("insnbits = %h", D_current_insn);
  // $display("curr op = %s", D_current_op.name());
  // $display("imm = %d\n", val_imm);
  out.val_imm = extract_immval(D_current_insn, D_current_op);
  if (D_current_op == OP_MOVK || D_current_op == OP_MOVZ) begin
    out.hw = {D_current_insn[22:21], 4'b0000};
    //TODO: In ALU, have to modify VAL_A for MOVK - can only do this in ALU
  end

  // $display("insn bits in decode is %h", D_current_insn);
  // $display("immediate is %d", out.val_imm);
  
  return out;
endfunction

function logic[63:0] extract_immval(logic[31:0] insnbits, opcodes_t op);
  decode_bitmask_outputs_t out;
  case (op)
  OP_LDUR:  return insnbits[20:12];
  OP_STUR:  return insnbits[20:12];
  OP_ADD:   return insnbits[21:10];
  OP_SUB:   return insnbits[21:10];
  OP_UBFM:  return insnbits[21:10];
  OP_SBFM:  return insnbits[21:10];
  OP_AND: begin
    out = decode_bitmasks(insnbits[22], insnbits[15:10], insnbits[21:16]);
    return out.wmask;
  end
  OP_LDP:   return {insnbits[21:15], 3'b000};
  OP_STP:   return {insnbits[21:15], 3'b000};
  OP_MOVK:  return insnbits[20:5];
  OP_MOVZ:  return insnbits[20:5];
  OP_ADR: return {insnbits[23:5], insnbits[30:29]};
  OP_ADRP: return {insnbits[23:5], insnbits[30:29], 12'b0000_0000_0000};
  //OP_LSL: 
  default: return 64'hdeadbeef;
  endcase
endfunction

function automatic decode_bitmask_outputs_t decode_bitmasks(logic immN, logic[5:0] imms, logic[5:0] immr);
  //sf opc      N  immr   imms    Rn   Rd
  //1 00 100100 1 000000 000010 10111 10110

  //TODO: PRANAV, YOU COCKSUCKER, YOU LIED TO ME
  //logic [6:0] highestBitInput = {immN, !(imms)};
  decode_bitmask_outputs_t out;

  integer len = highestSetBit({immN, ~(imms)});
  //integer len = $clog2({immN, ~(imms)} + 1);
  integer esize = 1 << len;
  logic[5:0] S;
  logic[5:0] R;
  logic[6:0] diff;
  logic[5:0] tmask_and, tmask_or;
  logic[5:0] wmask_and, wmask_or;

  logic[5:0] levels;
  logic[63:0] tmask = {64{1'b1}};
  logic[63:0] wmask = {64{1'b0}};


  for(integer i = 0; i < 6; i = i+1) begin
    if (i < len)
      levels[i] = 1'b1;
    else
      levels[i] = 1'b0;
  end

  //$display("highest bit input: %b", highestBitInput);
  //$display("DECODE BIT MASKS LEN: %d", len);
  //$display("DECODE BIT MASKS N: %b", immN);
  //$display("DECODE BIT MASKS imms: %b", imms);
  //$display("DECODE BIT MASKS immr: %b\n", immr);

  //$display("DECODE BIT MASKS LEVELS: %b", levels);


  S = imms & levels;
  R = immr & levels;
  diff = S-R;

  //$display("S: %b; %d", S, S);
  //$display("R: %b; %d", R, R);
  //$display("diff: %b; %d", diff, diff);


  tmask_and = diff[5:0] | ~(levels);
  tmask_or = diff[5:0] & levels;


  //Compute Top Mask
  tmask = (tmask & {32{{tmask_and[0], 1'b1}}}) | {32{1'b0, tmask_or[0]}};
  tmask = (tmask & {16{{{2{tmask_and[1]}}, {2{1'b1}}}}}) | {16{{2{1'b0}}, {2{tmask_or[1]}}}};
  tmask = (tmask & {8{{{4{tmask_and[2]}}, {4{1'b1}}}}}) | {8{{4{1'b0}}, {4{tmask_or[2]}}}};
  tmask = (tmask & {4{{{8{tmask_and[3]}}, {8{1'b1}}}}}) | {4{{8{1'b0}}, {8{tmask_or[3]}}}};
  tmask = (tmask & {2{{{16{tmask_and[4]}}, {16{1'b1}}}}}) | {2{{16{1'b0}}, {16{tmask_or[4]}}}};
  tmask = (tmask & {{32{tmask_and[5]}}, {32{1'b1}}}) | {{32{1'b0}}, {32{tmask_or[5]}}};

  //Compute Wraparound Mask
  wmask_and = immr | ~(levels);
  wmask_or = immr & levels;


  //Compute Top Mask
  wmask = (wmask & {32{{1'b1, wmask_and[0]}}}) | {32{wmask_or[0], 1'b0}};
  wmask = (wmask & {16{{{2{1'b1}}, {2{wmask_and[1]}}}}}) | {16{{2{wmask_or[1]}}, {2{1'b0}}}};
  wmask = (wmask & {8{{{4{1'b1}}, {4{wmask_and[2]}}}}}) | {8{{4{wmask_or[2]}}, {4{1'b0}}}};
  wmask = (wmask & {4{{{8{1'b1}}, {8{wmask_and[3]}}}}}) | {4{{8{wmask_or[3]}}, {8{1'b0}}}};
  wmask = (wmask & {2{{{16{1'b1}}, {16{wmask_and[4]}}}}}) | {2{{16{wmask_or[4]}}, {16{1'b0}}}};
  wmask = (wmask & {{32{1'b1}}, {32{wmask_and[5]}}}) | {{32{wmask_or[5]}}, {32{1'b0}}};

  /**
  for(integer i = 0; i < 6; i = i + 1) begin
    integer j = 2**i;
    integer k = 2**(5-i);

    tmask = (tmask & {k{{{j{tmask_and[i]}}, {j{1'b1}}}}});

  end 
  **/

  //$display("WMASK: %b", wmask);
  //$display("TMASK: %b", tmask);

  if(diff[6]) begin
    wmask = wmask & tmask;
  end else begin
    wmask = wmask | tmask;
  end

  out.wmask = wmask;
  out.tmask = tmask;

  return out;
 
endfunction

`endif
