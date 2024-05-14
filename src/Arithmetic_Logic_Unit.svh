`ifndef ARITHMETIC_LOGIC_UNIT_SVH
`define ARITHMETIC_LOGIC_UNIT_SVH

`include "Reservation_Stations.svh"
`include "opcodes.svh"

module Arithmetic_Logic_Unit();




initial begin
    $dumpfile("out/ooo_cpu.vcd");
    $dumpvars(0, Arithmetic_Logic_Unit);
end

function logic cond_holds(cond_t cond, logic[3:0] NZCV);
    // $display("In cond_hold nzcv: %4b", NZCV);
    case(cond)
        C_EQ: return get_ZF(NZCV);
        C_NE: return ~get_ZF(NZCV);
        C_CS: return get_CF(NZCV);
        C_CC: return ~get_CF(NZCV);
        C_MI: return get_NF(NZCV);
        C_PL: return ~get_NF(NZCV);
        C_VS: return get_VF(NZCV);
        C_VC: return ~get_VF(NZCV);
        C_HI: return get_CF(NZCV) && get_ZF(NZCV);
        C_LS: return ~(get_CF(NZCV) && get_ZF(NZCV));
        C_GE: return get_NF(NZCV) == get_VF(NZCV);
        C_LT: return ~(get_NF(NZCV) == get_VF(NZCV));
        C_GT: return ~get_ZF(NZCV) && (get_NF(NZCV) == get_VF(NZCV));
        C_LE: return ~get_ZF(NZCV) && ~(get_NF(NZCV) == get_VF(NZCV));
        C_AL: return 1;
        C_NV: return 1;
        C_ERROR: return 0;  //impossible
    endcase
endfunction



function void execute(dispatch_outputs_t record);

endfunction


function automatic logic [63:0] alu (dispatch_outputs_t record);
    decode_bitmask_outputs_t out;
    logic [63:0] src, bot, top;
    logic [63:0] mask, tmp;
    case(record.res_op) 
        OP_MOVK: begin
            logic[63:0] val_a = record.res_val_a_value;
            logic[63:0] val_mask = ~(64'h0000_0000_0000_FFFF << record.res_val_hw);
            logic[63:0] val_imm = (record.res_val_imm << record.res_val_hw);
            return (record.res_val_a_value & ~(64'h0000_0000_0000_FFFF << record.res_val_hw)) | (record.res_val_imm << record.res_val_hw);
        end
        OP_MOVZ: begin
            return record.res_val_a_value | (record.res_val_imm << record.res_val_hw);
        end
        OP_ADRP:
            return {record.res_pc[63:12], 12'b0} + record.res_val_imm;
        OP_ADR:
            return record.res_pc + record.res_val_imm;
        OP_CINC:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? record.res_val_a_value + 1 : record.res_val_a_value;
        OP_CINV:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? ~record.res_val_a_value : record.res_val_a_value;
        OP_CNEG:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? -record.res_val_a_value : record.res_val_a_value;
        OP_CSEL:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? record.res_val_b_value : record.res_val_a_value;
        OP_CSET:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? 1'b1 : 1'b0;
        OP_CSETM:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? {64{1'b1}} : 1'b0;
        OP_CSINC:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? record.res_val_a_value : record.res_val_b_value + 1;
        OP_CSINV:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? record.res_val_a_value : ~record.res_val_b_value;
        OP_CSNEG:
            return cond_holds(record.res_cond, record.res_val_nzcv_value) ? record.res_val_a_value : -record.res_val_b_value;
        OP_ADD: 
            return record.res_val_a_value + record.res_val_imm;
        OP_ADDS: begin
            // $display("ADD: %h + %h", record.res_val_a_value, record.res_val_b_value);
            return record.res_val_a_value + record.res_val_b_value;
        end
        OP_SUB:
            return record.res_val_a_value - record.res_val_imm;
        OP_SUBS:
            return record.res_val_a_value - record.res_val_b_value;
        OP_CMP:
            return record.res_val_a_value - record.res_val_b_value;
        OP_MVN:
            return ~record.res_val_a_value;
        OP_ORR:
            return record.res_val_a_value | record.res_val_b_value;
        OP_EOR:
            return record.res_val_a_value ^ record.res_val_b_value;
        OP_AND:
            return record.res_val_a_value & record.res_val_imm;
        OP_ANDS:
            return record.res_val_a_value & record.res_val_b_value;
        OP_TST:
            return record.res_val_a_value & record.res_val_b_value;
        OP_ASR, OP_SBFM: begin
           return sbfm(record, record.res_insnbits[22], record.res_insnbits[21:16], record.res_insnbits[15:10]);
        end
        OP_LSR, OP_LSL, OP_UBFM: begin
           return ubfm(record, record.res_insnbits[22], record.res_insnbits[21:16], record.res_insnbits[15:10]);
        end 
        OP_BL:
            return record.res_pc+4;
        OP_BLR:
            return record.res_pc+4;
        default: 
            return 64'hFEEDFACEDEADBEEF;
    endcase
endfunction

function logic[63:0] sbfm (dispatch_outputs_t record, logic N, logic[6:0] immr, logic[6:0] imms);
    decode_bitmask_outputs_t out;
    logic[63:0] src;
    logic[63:0] bot;
    logic[63:0] top;

    out = decode_bitmasks(N, imms, immr);
    src = record.res_val_a_value;
    bot = ((src >> immr) | (src << (64-immr))) & out.wmask;
    top = {64{src[imms]}};
    //$display("OUT: %b; %h", out, src);
    //$display("SRC: %b; %h", src, src);
    //$display("BOT: %b; %h", bot, bot);
    //$display("TOP: %b, %h", top, top);
    return (top & ~out.tmask) | (bot & out.wmask);

endfunction 

function logic[63:0] ubfm (dispatch_outputs_t record, logic N, logic[6:0] immr, logic[6:0] imms);
    decode_bitmask_outputs_t out;
    logic[63:0] src;
    logic[63:0] bot;

    out = decode_bitmasks(N, imms, immr);
    src = record.res_val_a_value;
    bot = ((src >> immr) | (src << (64-immr))) & out.wmask;
    return (bot & out.tmask);

endfunction

// -1 means midpredict, -2 means no branch address
function logic [63:0] branch_address (dispatch_outputs_t record);
    // if (record.res_op == OP_Bcond)
        // $display("cond_holds: %s, cond: %d, N: %b, V: %b", cond_holds(record.res_cond, record.res_val_nzcv_value)==record.res_prediction?"t":"f", record.res_cond, record.res_val_nzcv_value[0], record.res_val_nzcv_value[3]);
    case(record.res_op)
    OP_BR:
        return record.res_val_a_value;
    OP_Bcond: begin //NOT CORRECT JUST PLACEHOLDER
        return cond_holds(record.res_cond, record.res_val_nzcv_value)==record.res_prediction ? record.res_val_imm + record.res_pc+4 : -1;
    end
    OP_BLR:
        return record.res_val_a_value;
    OP_CBNZ:
        return (record.res_val_a_value != 0)==record.res_prediction ? record.res_val_imm + record.res_pc+4 : -1;
    OP_CBZ:
        return (record.res_val_a_value == 0)==record.res_prediction ? record.res_val_imm + record.res_pc+4 : -1;
    OP_RET:
        return record.res_val_a_value;
    default:
       return -2;
    endcase
endfunction

function logic [3:0] set_nzcv (dispatch_outputs_t record, logic [63:0] res);
    static logic N = 1'b0;
    static logic Z = 1'b0;
    static logic C = 1'b0;
    static logic V = 1'b0;
    case(record.res_op)
    OP_ADDS: begin
        N = (res & 64'h8000000000000000)!=0;
        Z = res==0;
        C = (res < record.res_val_a_value) || (res < record.res_val_b_value);
        V = (!(record.res_val_a_value & 64'h8000000000000000) && !(record.res_val_b_value & 64'h8000000000000000)) && N;
        V = V | ((record.res_val_a_value & 64'h8000000000000000) && (record.res_val_b_value & 64'h8000000000000000)) && !N;
    end
    OP_SUBS: begin
        N = (res & 64'h8000000000000000)!=0;
        Z = res==0;
        C = record.res_val_a_value >= record.res_val_a_value;
        V = (!(record.res_val_a_value & 64'h8000000000000000) && (record.res_val_b_value & 64'h8000000000000000)) && N;
        V = V | ((record.res_val_a_value & 64'h8000000000000000) && !(record.res_val_b_value & 64'h8000000000000000)) && !N;
    end
    OP_CMP: begin
        N = (res & 64'h8000000000000000)!=0;
        Z = res==0;
        C = record.res_val_a_value >= record.res_val_a_value;
        V = (!(record.res_val_a_value & 64'h8000000000000000) && (record.res_val_b_value & 64'h8000000000000000)) && N;
        V = V | ((record.res_val_a_value & 64'h8000000000000000) && !(record.res_val_b_value & 64'h8000000000000000)) && !N;
    end
    default:
        return 4'b0000;
    endcase
    return {V, C, Z, N};
endfunction


function logic get_NF(logic [3:0] nzcv);
    return nzcv[0];
endfunction

function logic get_ZF(logic [3:0] nzcv);
    return nzcv[1];
endfunction

function logic get_CF(logic [3:0] nzcv);
    return nzcv[2];
endfunction

function logic get_VF(logic [3:0] nzcv);
    return nzcv[3];
endfunction

endmodule

`endif
