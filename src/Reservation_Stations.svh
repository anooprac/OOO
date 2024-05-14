`ifndef RESERVATION_STATIONS_SVH
`define RESERVATION_STATIONS_SVH

`include "opcodes.svh"
`include "decode.svh"
`include "Reorder_Buffer.svh"
`include "Register_File.svh"

parameter RES_SIZE = 4;
//***RESERVATION STATIONS***//

// ALU RESERVATION STATION
typedef struct packed {
    logic valid;
    logic [3:0] res_cond;
    logic [$clog2(NUM_REGS) - 1:0] res_reg_a_idx;
    logic [REG_SIZE-1:0] res_val_a_value;

    logic [$clog2(NUM_REGS) - 1:0] res_reg_b_idx;
    logic [REG_SIZE-1:0] res_val_b_value;    
    logic res_val_b_is_imm;
    logic [MAX_IMM-1:0] res_val_imm;
    logic [5:0] res_val_hw;

    logic [INSN_WIDTH-1:0] res_insnbits;

    logic [REG_SIZE - 1:0] res_val_nzcv_value;

    logic [$clog2(ROB_SIZE)-1:0] res_dest_rob_ptr;

    opcodes_t res_op;
    logic [ADDR_WIDTH-1:0] res_other_pc;
    logic [ADDR_WIDTH-1:0] res_pc;
    logic res_prediction;
    logic [2:0] res_X_sigs;
    logic [2:0] res_M_sigs;
    logic [2:0] res_W_sigs;
} dispatch_outputs_t;
    

module ALU_Reservation_Station();

    logic [RES_SIZE-1:0] res_bitmap ;
    logic [3:0] res_cond [RES_SIZE-1:0];

    logic [$clog2(NUM_REGS) - 1:0] res_reg_a_idx [RES_SIZE-1:0];
    logic [REG_SIZE-1:0] res_val_a_value [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] res_val_a_valid;
    logic [ROB_SIZE-1:0] res_val_a_robPt_src [RES_SIZE-1:0];


    logic [$clog2(NUM_REGS) - 1:0] res_reg_b_idx [RES_SIZE-1:0];
    logic [REG_SIZE-1:0] res_val_b_value [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] res_val_b_valid;
    logic [RES_SIZE-1:0]res_val_b_is_imm;
    logic [ROB_SIZE-1:0] res_val_b_robPt_src [RES_SIZE-1:0];
    logic [MAX_IMM-1:0] res_val_imm [RES_SIZE-1:0];
    logic [5:0] res_val_hw [RES_SIZE-1:0];

    logic [INSN_WIDTH-1:0] res_insnbits [RES_SIZE-1:0];


    logic [REG_SIZE - 1:0] res_val_nzcv_value [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] res_val_nzcv_valid;
    logic [RES_SIZE - 1:0] res_val_requires_nzcv;
    logic [ROB_SIZE-1:0] res_val_nzcv_robPt_src [RES_SIZE-1:0];


    logic [$clog2(ROB_SIZE)-1:0] res_dest_rob_ptr [RES_SIZE-1:0];

    //Reservation Station
    opcodes_t res_op [RES_SIZE-1:0];
    logic [ADDR_WIDTH-1:0] res_other_pc [RES_SIZE-1:0];
    logic [ADDR_WIDTH-1:0] res_pc [RES_SIZE-1:0];
    logic res_prediction [RES_SIZE-1:0];


    // [2] nzcv source?: 0 for no, 1 for yes.
    // [1] valb selector: 0 for immediate, 1 for register.
    // [0] Whether to set condition flags: 0 for no, 1 for yes.
    logic [2:0] res_X_sigs [RES_SIZE-1:0]; 

    // [2] if pair
    // [1] 1 if memory access is a read, 0 if not. (load)
    // [0] 1 if memory access is a write, 0 if not. (store)
    logic [2:0] res_M_sigs [RES_SIZE-1:0];

    // [2] dst selector: 1 for X30 (in BL), 0 otherwise.
    // [1] wval selector: 1 for LDUR, 0 otherwise.
    // [0] Whether to perform a write: 0 for no, 1 for yes.
    logic [2:0] res_W_sigs [RES_SIZE-1:0];



    int alu_rs_size = 0;


    initial begin
        $dumpfile("out/ooo_cpu.vcd");
        $dumpvars(0, ALU_Reservation_Station);
        for (int i = 0; i < RES_SIZE; i++) begin
           $dumpvars(0, res_cond[i], res_reg_a_idx[i], res_val_a_value[i], res_val_a_robPt_src[i], res_reg_b_idx[i], res_val_b_value[i], res_val_b_robPt_src[i], res_val_imm[i], res_val_hw[i], res_insnbits[i], res_val_nzcv_value[i], res_val_nzcv_robPt_src[i], res_dest_rob_ptr[i], res_other_pc[i], res_X_sigs[i], res_M_sigs[i], res_W_sigs[i]);
        end
    end 

    function logic is_empty();
        return (alu_rs_size == 0);
    endfunction

    function logic [$clog2(RES_SIZE)-1:0] find_free_slot();
        for (int i = 0; i < RES_SIZE; i++) begin
            if (res_bitmap[i] == 0) begin
                res_bitmap[i] = 1;
                return i;
            end
        end
    endfunction


    function void enqueue(
        decode_outputs_t decoded,
        logic [INSN_WIDTH-1:0] insnbits,
        opcodes_t op,
        logic [$clog2(ROB_SIZE) - 1:0] rob_ptr,
        logic [ADDR_WIDTH-1:0] other_pc,
        logic [ADDR_WIDTH-1:0] pc,
        logic prediction
    );
        static logic [$clog2(RES_SIZE) - 1:0] head; 
        // print when called

        head = find_free_slot();

        //$display("calling ALU enqueue on op %h", insnbits);
        // store insn bits
        res_insnbits[head] = insnbits;

        //store reg a idx for debugging purposes
        res_reg_a_idx[head] = decoded.reg_a_idx;

        //store reg b idx for debugging purposes
        if (decoded.D_X_sigs[1]) res_reg_b_idx[head] = decoded.reg_b_idx;

        // store rob pointer
        res_dest_rob_ptr[head] = rob_ptr;

        // store the control signals
        res_X_sigs[head] = decoded.D_X_sigs;
        res_M_sigs[head] = decoded.D_M_sigs;
        res_W_sigs[head] = decoded.D_W_sigs;

        // store op
        res_op[head] = op;

        // store other_pc
        if (op==OP_Bcond)
        // $display("Enqueue other pc: %d", other_pc);
        res_other_pc[head] = other_pc;
        res_pc[head] = pc;
        res_prediction[head] = prediction;

        // store hw
        res_val_hw[head]= decoded.hw;
        

        //handle reg a first
        if (rf.is_valid(decoded.reg_a_idx)) begin
            // if (op==OP_LSL) $display("LSL found val a in RF");
            res_val_a_valid[head] = 1'b1;
            res_val_a_value[head] = rf.get_regval(decoded.reg_a_idx);
        end
        else if (rob.is_entry_valid(rf.get_rob_ptr(decoded.reg_a_idx))) begin
            // if (op==OP_LSL) $display("LSL found val a in ROB");
            res_val_a_valid[head] = 1'b1;
            res_val_a_value[head] = rob.get_val(rf.get_rob_ptr(decoded.reg_a_idx));
        end
        else begin
            // if (op==OP_LSL) $display("LSL did not found val a");
            res_val_a_valid[head] = 1'b0;
            res_val_a_robPt_src[head] = rf.get_rob_ptr(decoded.reg_a_idx);
        end

        //handle reg b next
        // $display("in enqueue decoded.D_X_sigs[1]: %b", decoded.D_X_sigs[1]);
        if (!decoded.D_X_sigs[1]) begin
            res_val_b_is_imm[head] = 1'b1;
            res_val_imm[head] = decoded.val_imm;
        end
        else if (rf.is_valid(decoded.reg_b_idx)) begin
            res_val_b_is_imm[head] = 1'b0;
            res_val_b_valid[head] = 1'b1;
            res_val_b_value[head] = rf.get_regval(decoded.reg_b_idx);
        end
        else if (rob.is_entry_valid(rf.get_rob_ptr(decoded.reg_b_idx))) begin
            res_val_b_is_imm[head] = 1'b0;
            res_val_b_valid[head] = 1'b1;
            res_val_b_value[head] = rob.get_val(rf.get_rob_ptr(decoded.reg_b_idx));
        end
        else begin
            res_val_b_is_imm[head] = 1'b0;
            res_val_b_valid[head] = 1'b0;
            res_val_b_robPt_src[head] = rf.get_rob_ptr(decoded.reg_b_idx);
        end

        //handle nzcv dependencies
        res_val_requires_nzcv[head] = 1'b0;
        if (decoded.D_X_sigs[2]) begin
            res_val_requires_nzcv[head] = 1'b1;
            if (rf.is_valid(NZCV_NUM)) begin
                // if (op==OP_Bcond) $display("Found NZCV in rf");
                res_val_nzcv_value[head] = rf.get_regval(NZCV_NUM);
                res_val_nzcv_valid[head] = 1'b1;
            end
            else if (rob.is_entry_valid(rf.get_rob_ptr(NZCV_NUM))) begin
                res_val_nzcv_value[head] = rob.get_nzcv(rf.get_rob_ptr(NZCV_NUM));
                // if (op==OP_Bcond) $display("Found NZCV in rob, val %h", rob.get_nzcv(rf.get_rob_ptr(NZCV_NUM)));
                res_val_nzcv_valid[head] = 1'b1;
            end
            else begin
                // if (op==OP_Bcond) $display("Not Found NZCV");
                res_val_nzcv_valid[head] = 1'b0;
                res_val_nzcv_robPt_src[head] = rf.get_rob_ptr(NZCV_NUM);
            end
        end
        res_cond[head] = decoded.cond;

        head = (head + 1) % RES_SIZE;
        alu_rs_size = alu_rs_size + 1;
    endfunction

    function logic is_full(opcodes_t op);
        if (op != OP_LDUR && op != OP_STUR && op != OP_LDP && op != OP_STP) begin
            return alu_rs_size == RES_SIZE;
        end
        return 1'b0;
    endfunction

    function void zero_alu_entry(logic [$clog2(RES_SIZE-1):0] idx);
        res_bitmap[idx] = 0;

        res_cond[idx] = 4'b0;

        res_reg_a_idx[idx] = {$clog2(NUM_REGS){1'b0}};
        res_val_a_value[idx] = {REG_SIZE{1'b0}};
        res_val_a_valid[idx] = 1'b0;
        res_val_a_robPt_src[idx] = {ROB_SIZE{1'b0}};

        res_reg_b_idx[idx] = {$clog2(NUM_REGS){1'b0}};
        res_val_b_value[idx] = {REG_SIZE{1'b0}};
        res_val_b_valid[idx] = 1'b0;
        res_val_b_is_imm[idx] = 1'b0;
        res_val_imm[idx] = {MAX_IMM{1'b0}};
        res_val_hw[idx] = {6{1'b0}};
        res_val_b_robPt_src[idx] = {ROB_SIZE{1'b0}};


        res_insnbits[idx] = {INSN_WIDTH{1'b0}};
        res_val_nzcv_value[idx] = {REG_SIZE{1'b0}};
        res_val_nzcv_valid[idx] = 1'b0;
        res_val_nzcv_robPt_src[idx] = {ROB_SIZE{1'b0}};
        res_dest_rob_ptr[idx] = {$clog2(ROB_SIZE){1'b0}};

        res_op[idx] = OP_ERR;
        res_other_pc[idx] = {ADDR_WIDTH{1'b0}};
        res_pc[idx] = {ADDR_WIDTH{1'b0}};
        res_prediction[idx] = 1'b0;

        res_X_sigs[idx] = 3'b0;
        res_M_sigs[idx] = 3'b0;
        res_W_sigs[idx] = 3'b0;

    endfunction

    function dispatch_outputs_t dispatch();
    dispatch_outputs_t dispatch_outputs;
    dispatch_outputs.valid = 0;
        for (int i = 0; i < RES_SIZE; i ++) begin
            if (res_bitmap[i] == 1) begin
                if (res_op[i]==OP_SUBS) begin
                    //$display("SUBS in RS: val a: %s, val b: %s", res_val_a_valid[i] ? "valid" : "not valid", res_val_b_valid[i] ? "valid" : "not valid");
                end
               if (res_val_a_valid[i] && (res_val_b_valid[i] || res_val_b_is_imm[i])) begin
                    if ((res_val_requires_nzcv[i] && res_val_nzcv_valid[i]) || !res_val_requires_nzcv[i] ) begin
                        
                        alu_rs_size = alu_rs_size - 1;
                        dispatch_outputs.valid = 1;
                        dispatch_outputs.res_cond = res_cond[i];
                        dispatch_outputs.res_reg_a_idx = res_reg_a_idx[i];
                        dispatch_outputs.res_val_a_value = res_val_a_value[i];
                        dispatch_outputs.res_reg_b_idx = res_reg_b_idx[i];
                        dispatch_outputs.res_val_b_value = res_val_b_value[i];
                        dispatch_outputs.res_val_b_is_imm = res_val_b_is_imm[i];
                        dispatch_outputs.res_val_imm = res_val_imm[i];
                        dispatch_outputs.res_val_hw = res_val_hw[i];
                        dispatch_outputs.res_insnbits = res_insnbits[i];
                        dispatch_outputs.res_val_nzcv_value = res_val_nzcv_value[i];
                        dispatch_outputs.res_dest_rob_ptr = res_dest_rob_ptr[i];
                        dispatch_outputs.res_op = res_op[i];
                        dispatch_outputs.res_other_pc = res_other_pc[i];
                        dispatch_outputs.res_pc = res_pc[i];
                        dispatch_outputs.res_prediction = res_prediction[i];
                        dispatch_outputs.res_X_sigs = res_X_sigs[i];
                        dispatch_outputs.res_M_sigs = res_M_sigs[i];
                        dispatch_outputs.res_W_sigs = res_W_sigs[i];

                        zero_alu_entry(i);
                        
                        return dispatch_outputs;
                    end
                end
            end
        end
        return dispatch_outputs;
    endfunction

    
function void broadcast(rob_entry_t entry, logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
    for (int i = 0; i < RES_SIZE; i++) begin
        if (res_bitmap[i] == 1) begin
            // $display("For instruction = %h", res_insnbits[i]);
            // $display("val b is imm = %b, val b valid = %b, rob idx = %d", res_val_b_is_imm[i], res_val_b_valid[i], res_val_b_robPt_src[i]);
            if (!res_val_a_valid[i] && res_val_a_robPt_src[i] == rob_idx) begin
                res_val_a_value[i] = entry.dest_val;
                res_val_a_valid[i] = 1'b1;
            end
            if (!res_val_b_is_imm[i] && !res_val_b_valid[i] && res_val_b_robPt_src[i] == rob_idx) begin
                res_val_b_value[i] = entry.dest_val;
                res_val_b_valid[i] = 1'b1;
            end
            if (res_val_requires_nzcv[i] && !res_val_nzcv_valid[i] && res_val_nzcv_robPt_src[i] == rob_idx && entry.modified_nzcv) begin
                res_val_nzcv_value[i] = entry.nzcv_val;
                res_val_nzcv_valid[i] = 1'b1;
            end
        end
    end
endfunction

function void init_bitmap();
    for (int i = 0; i < RES_SIZE; i++) begin
            res_bitmap[i] = 1'b0;
        end
endfunction


function void flush();
    for (int i = 0; i < RES_SIZE; i++) begin
        zero_alu_entry(i);
    end
    alu_rs_size = 0;
endfunction

endmodule;


//L/S RESERVATION STATION
typedef struct packed {
    logic valid;
    logic [$clog2(NUM_REGS) - 1:0] ls_res_src_a_idx;
    logic [REG_SIZE-1:0] ls_res_src_a_value;
    logic ls_res_src_a_valid;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_src_a_robPt;

    logic [$clog2(NUM_REGS) - 1:0] ls_res_src_b_idx;
    logic [REG_SIZE-1:0] ls_res_src_b_value;
    logic ls_res_src_b_valid;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_src_b_robPt;

    logic [MAX_IMM-1:0] ls_res_offset;
    logic [$clog2(NUM_REGS) - 1:0] ls_res_addr_idx;
    logic [REG_SIZE-1:0] ls_res_addr_value;
    logic ls_res_addr_valid;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_addr_robPt;

    logic [$clog2(NUM_REGS) - 1:0] ls_res_dest_a_idx;
    logic les_res_dest_a_mod;

    logic [$clog2(NUM_REGS) - 1:0] ls_res_dest_b_idx;
    logic  les_res_dest_b_mod;

    logic [INSN_WIDTH-1:0] ls_res_insnbits;
    opcodes_t ls_res_op;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_dest_rob_ptr;

    // [2] if pair
    // [1] 1 if memory access is a read, 0 if not. load
    // [0] 1 if memory access is a write, 0 if not. store
    logic [2:0] ls_res_M_sigs;

    // [2] dst selector: 1 for X30 (in BL), 0 otherwise.
    // [1] wval selector: 1 for LDUR, 0 otherwise.
    // [0] Whether to perform a write: 0 for no, 1 for yes.
    logic [2:0] ls_res_W_sigs;

} ls_dispatch_outputs_t;

module LS_Reservation_Station();
    //LOAD STORE RESERVATION STATION
    logic [$clog2(NUM_REGS) - 1:0] ls_res_src_a_idx [RES_SIZE-1:0];
    logic [REG_SIZE-1:0] ls_res_src_a_value [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] ls_res_src_a_valid;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_src_a_robPt [RES_SIZE-1:0];

    logic [$clog2(NUM_REGS) - 1:0] ls_res_src_b_idx [RES_SIZE-1:0];
    logic [REG_SIZE-1:0] ls_res_src_b_value [RES_SIZE-1:0];
    logic ls_res_src_b_valid [RES_SIZE-1:0];
    logic [$clog2(ROB_SIZE)-1:0] ls_res_src_b_robPt [RES_SIZE-1:0];

    logic [MAX_IMM-1:0] ls_res_offset [RES_SIZE-1:0];
    logic [$clog2(NUM_REGS) - 1:0] ls_res_addr_idx [RES_SIZE-1:0];
    logic [ADDR_WIDTH-1:0] ls_res_addr_value [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] ls_res_addr_valid;
    logic [$clog2(ROB_SIZE)-1:0] ls_res_addr_robPt [RES_SIZE-1:0];

    logic [$clog2(NUM_REGS) - 1:0] ls_res_dest_a_idx [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] ls_res_dest_a_mod;

    logic [$clog2(NUM_REGS) - 1:0] ls_res_dest_b_idx [RES_SIZE-1:0];
    logic [RES_SIZE-1:0] ls_res_dest_b_mod;

    logic [INSN_WIDTH-1:0] ls_res_insnbits [RES_SIZE-1:0];
    opcodes_t ls_res_op [RES_SIZE-1:0];
    logic [$clog2(ROB_SIZE)-1:0] ls_res_dest_rob_ptr [RES_SIZE-1:0];

    // [2] if pair
    // [1] 1 if memory access is a read, 0 if not.
    // [0] 1 if memory access is a write, 0 if not.
    logic [2:0] ls_res_M_sigs [RES_SIZE-1:0];

    // [2] dst selector: 1 for X30 (in BL), 0 otherwise.
    // [1] wval selector: 1 for LDUR, 0 otherwise.
    // [0] Whether to perform a write: 0 for no, 1 for yes.
    logic [2:0] ls_res_W_sigs [RES_SIZE-1:0];





    int ls_rs_head = 0;
    int ls_rs_tail = 0;
    int ls_rs_size = 0;

     initial begin
        $dumpfile("out/ooo_cpu.vcd");
        $dumpvars(0, LS_Reservation_Station);
        for (int i = 0; i < RES_SIZE; i++) begin
            $dumpvars(0, ls_res_src_a_idx[i], ls_res_src_a_value[i], ls_res_src_a_robPt[i], ls_res_src_b_idx[i], ls_res_src_b_value[i], ls_res_src_b_robPt[i], ls_res_offset[i], ls_res_addr_idx[i], ls_res_addr_value[i], ls_res_addr_robPt[i], ls_res_dest_a_idx[i], ls_res_dest_b_idx[i], ls_res_insnbits[i], ls_res_dest_rob_ptr[i], ls_res_M_sigs[i], ls_res_W_sigs[i]);
        end
    end 

    function logic is_full(opcodes_t op);
        if (op == OP_LDUR || op == OP_STUR || op == OP_LDP || op == OP_STP) begin
            return ls_rs_size == RES_SIZE;
        end
        return 1'b0;
    endfunction


    function logic is_empty();
        return (ls_rs_size == 0);
    endfunction

    function void enqueue(
        decode_outputs_t decoded,
        logic [INSN_WIDTH-1:0] insnbits,
        opcodes_t op,
        logic [$clog2(ROB_SIZE) - 1:0] rob_ptr
    );
    if (is_full(op)) begin
        return;
    end
    ls_res_insnbits[ls_rs_head] = insnbits;
    ls_res_op[ls_rs_head] = op;

    ls_res_offset[ls_rs_head] = decoded.val_imm;
    // $display("IN ENQUEUE insnbits are %h", insnbits);
    // $display("imm is %h", decoded.val_imm);
    ls_res_dest_rob_ptr[ls_rs_head] = rob_ptr;

    ls_res_M_sigs[ls_rs_head] = decoded.D_M_sigs;
    ls_res_W_sigs[ls_rs_head] = decoded.D_W_sigs;


    // if load; dest_a = reg_b
    if (decoded.D_M_sigs[1]) begin
        ls_res_addr_idx[ls_rs_head] = decoded.reg_a_idx;
        ls_res_dest_a_idx[ls_rs_head] = decoded.dest_reg_idx;
        ls_res_dest_b_idx[ls_rs_head] = decoded.dest2_reg_idx;

        ls_res_dest_a_mod[ls_rs_head] = 1'b1;
        ls_res_dest_b_mod[ls_rs_head] = decoded.D_W_sigs[2];
    end
    else if (decoded.D_M_sigs[0]) begin
        ls_res_addr_idx[ls_rs_head] = decoded.reg_a_idx;
        ls_res_src_a_idx[ls_rs_head] = decoded.reg_b_idx;
        ls_res_src_b_idx[ls_rs_head] = decoded.reg_c_idx;
        ls_res_dest_a_idx[ls_rs_head] = XZR_NUM;
        ls_res_dest_b_idx[ls_rs_head] = XZR_NUM;

        //check if src_a reg is valid
        // $display("Reg b idx: %d", decoded.reg_b_idx);
        if (rf.is_valid(decoded.reg_b_idx)) begin
            // $display("Store found src a in RF");
            ls_res_src_a_valid[ls_rs_head] = 1'b1;
            ls_res_src_a_value[ls_rs_head] = rf.get_regval(decoded.reg_b_idx);
        end
        else if (rob.is_entry_valid(rf.get_rob_ptr(decoded.reg_b_idx))) begin
            // $display("Store found src a in ROB");
            ls_res_src_a_valid[ls_rs_head] = 1'b1;
            ls_res_src_a_value[ls_rs_head] = rob.get_val(rf.get_rob_ptr(decoded.reg_b_idx));
        end
        else begin
            // $display("Store src a unfound");
            ls_res_src_a_valid[ls_rs_head] = 1'b0;
            ls_res_src_a_robPt[ls_rs_head] = rf.get_rob_ptr(decoded.reg_b_idx);
        end

        //check if src_b reg is valid
        if (rf.is_valid(decoded.reg_c_idx)) begin
            ls_res_src_b_valid[ls_rs_head] = 1'b1;
            ls_res_src_b_value[ls_rs_head] = rf.get_regval(decoded.reg_c_idx);
        end
        else if (rob.is_entry_valid(rf.get_rob_ptr(decoded.reg_c_idx))) begin
            ls_res_src_b_valid[ls_rs_head] = 1'b1;
            ls_res_src_b_value[ls_rs_head] = rob.get_val(rf.get_rob_ptr(decoded.reg_c_idx));
        end
        else begin
            ls_res_src_b_valid[ls_rs_head] = 1'b0;
            ls_res_src_b_robPt[ls_rs_head] = rf.get_rob_ptr(decoded.reg_c_idx);
        end
        
    end

    // check if addr reg is valid
    if (rf.is_valid(decoded.reg_a_idx)) begin
        ls_res_addr_valid[ls_rs_head] = 1'b1;
        ls_res_addr_value[ls_rs_head] = compute_ls_addr(rf.get_regval(decoded.reg_a_idx), decoded.val_imm, op);
        // $display("In ls enqueue insn bits: %h", insnbits);
        // $display("Adding imm to sp. imm: %h, sp: %h", decoded.val_imm, rf.get_regval(decoded.reg_a_idx));
    end
    else if (rob.is_entry_valid(rf.get_rob_ptr(decoded.reg_a_idx))) begin
        ls_res_addr_valid[ls_rs_head] = 1'b1;
        ls_res_addr_value[ls_rs_head] = compute_ls_addr(rob.get_val(rf.get_rob_ptr(decoded.reg_a_idx)), decoded.val_imm, op);
    end
    else begin
        ls_res_addr_valid[ls_rs_head] = 1'b0;
        ls_res_addr_robPt[ls_rs_head] = rf.get_rob_ptr(decoded.reg_a_idx);
    end


    ls_rs_head = (ls_rs_head + 1) % RES_SIZE;
    ls_rs_size = ls_rs_size + 1;

    endfunction

    function logic [ADDR_WIDTH-1:0] compute_ls_addr(logic [ADDR_WIDTH-1:0] base_val, logic [MAX_IMM:0] imm_val, opcodes_t op);
        static logic [ADDR_WIDTH-1:0] ret;
        if ((op==OP_LDUR || op==OP_STUR) && imm_val[8]) begin
            // if imm is negative
            ret = base_val - ((~imm_val[8:0] & {9{1'b1}}) + 1);
        end else if ((op==OP_LDP || op==OP_STP) && imm_val[9]) begin
            ret = base_val - ((~imm_val[9:0] & {10{1'b1}}) + 1);
        end else 
            ret = base_val + imm_val;
            return ret;
    endfunction

    function void zero_entry(logic[$clog2(RES_SIZE) - 1:0] i);

        ls_res_src_a_idx[i] = {$clog2(NUM_REGS){1'b0}};
        ls_res_src_a_value[i] = {REG_SIZE{1'b0}};
        ls_res_src_a_valid[i] = 1'b0;
        ls_res_src_a_robPt[i] = {ROB_SIZE{1'b0}};

        ls_res_src_b_idx[i] = {$clog2(NUM_REGS){1'b0}};
        ls_res_src_b_value[i] = {REG_SIZE{1'b0}};
        ls_res_src_b_valid[i] = 1'b0;
        ls_res_src_b_robPt[i] = {ROB_SIZE{1'b0}};

        ls_res_offset[i] = {MAX_IMM{1'b0}};
        ls_res_addr_idx[i] = {$clog2(NUM_REGS){1'b0}};
        ls_res_addr_value[i] = {ADDR_WIDTH{1'b0}};
        ls_res_addr_valid[i] = 1'b0;
        ls_res_addr_robPt[i] = {$clog2(ROB_SIZE){1'b0}};


        ls_res_dest_a_idx[i] = {$clog2(NUM_REGS){1'b0}};
        ls_res_dest_a_mod[i] = 1'b0;

        ls_res_dest_b_idx[i] = {$clog2(NUM_REGS){1'b0}};
        ls_res_dest_b_mod[i] = 1'b0;

        ls_res_insnbits[i] = {INSN_WIDTH{1'b0}};

        ls_res_op[i] = OP_ERR;
        ls_res_dest_rob_ptr[i] = {$clog2(ROB_SIZE){1'b0}};

        ls_res_M_sigs[i] = 3'b0;
        ls_res_W_sigs[i] = 3'b0;
    endfunction


    function automatic ls_dispatch_outputs_t dispatch();
        ls_dispatch_outputs_t dispatch_outputs;
        dispatch_outputs.valid = 0;
        if (ls_rs_size == 0) begin
            return dispatch_outputs;
        end
        // only checking tail because FIFO
        dispatch_outputs.ls_res_src_a_idx = ls_res_src_a_idx[ls_rs_tail];
        dispatch_outputs.ls_res_src_a_value = ls_res_src_a_value[ls_rs_tail];
        dispatch_outputs.ls_res_src_a_valid = ls_res_src_a_valid[ls_rs_tail];
        dispatch_outputs.ls_res_src_a_robPt = ls_res_src_a_robPt[ls_rs_tail];

        dispatch_outputs.ls_res_src_b_idx = ls_res_src_b_idx[ls_rs_tail];
        dispatch_outputs.ls_res_src_b_value = ls_res_src_b_value[ls_rs_tail];
        dispatch_outputs.ls_res_src_b_valid = ls_res_src_b_valid[ls_rs_tail];
        dispatch_outputs.ls_res_src_b_robPt = ls_res_src_b_robPt[ls_rs_tail];

        dispatch_outputs.ls_res_offset = ls_res_offset[ls_rs_tail];
        dispatch_outputs.ls_res_addr_idx = ls_res_addr_idx[ls_rs_tail];
        dispatch_outputs.ls_res_addr_value = ls_res_addr_value[ls_rs_tail];
        dispatch_outputs.ls_res_addr_valid = ls_res_addr_valid[ls_rs_tail];
        dispatch_outputs.ls_res_addr_robPt = ls_res_addr_robPt[ls_rs_tail];

        dispatch_outputs.ls_res_dest_a_idx = ls_res_dest_a_idx[ls_rs_tail];
        dispatch_outputs.les_res_dest_a_mod = ls_res_dest_a_mod[ls_rs_tail];

        dispatch_outputs.ls_res_dest_b_idx = ls_res_dest_b_idx[ls_rs_tail];
        dispatch_outputs.les_res_dest_b_mod = ls_res_dest_b_mod[ls_rs_tail];

        dispatch_outputs.ls_res_insnbits = ls_res_insnbits[ls_rs_tail];
        dispatch_outputs.ls_res_op = ls_res_op[ls_rs_tail];
        dispatch_outputs.ls_res_dest_rob_ptr = ls_res_dest_rob_ptr[ls_rs_tail];

        dispatch_outputs.ls_res_M_sigs = ls_res_M_sigs[ls_rs_tail];
        dispatch_outputs.ls_res_W_sigs = ls_res_W_sigs[ls_rs_tail];

        if (ls_res_addr_valid[ls_rs_tail]) begin
            //load
            // $display("In ls dispatch insn bits: %h, addr: %h, setting rob idx: %d", ls_res_insnbits[ls_rs_tail], ls_res_addr_value[ls_rs_tail], ls_res_dest_rob_ptr[ls_rs_tail]);
    
            //display line number
            if (ls_res_M_sigs[ls_rs_tail][1]) begin
                dispatch_outputs.valid = 1'b1;
                zero_entry(ls_rs_tail);
                ls_rs_tail = (ls_rs_tail + 1) % RES_SIZE;
                ls_rs_size = ls_rs_size - 1;
                return dispatch_outputs;
            end
            //store
            else if (ls_res_M_sigs[ls_rs_tail][0] && ls_res_src_a_valid[ls_rs_tail]) begin
                // set addr in rob entry now that we know addr is valid
                rob.set_addr(ls_res_dest_rob_ptr[ls_rs_tail], ls_res_addr_value[ls_rs_tail]);
                
                //FOR STP and all operands ready
                if (ls_res_M_sigs[ls_rs_tail][2] && ls_res_src_b_valid[ls_rs_tail]) begin
                    rob.set_addr((ls_res_dest_rob_ptr[ls_rs_tail] + 1) % ROB_SIZE, ls_res_addr_value[ls_rs_tail] + 8);
                    dispatch_outputs.valid = 1'b1;
                    zero_entry(ls_rs_tail);
                    ls_rs_tail = (ls_rs_tail + 1) % RES_SIZE;
                    ls_rs_size = ls_rs_size - 1;
                    return dispatch_outputs;
                end
                //For STUR and all operands ready
                else if (!ls_res_M_sigs[ls_rs_tail][2]) begin
                    dispatch_outputs.valid = 1'b1;
                    zero_entry(ls_rs_tail);
                    ls_rs_tail = (ls_rs_tail + 1) % RES_SIZE;
                    ls_rs_size = ls_rs_size - 1;
                    return dispatch_outputs;
                end
            end
            
        end
        return dispatch_outputs;
    endfunction 

    function void broadcast(rob_entry_t entry, logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
        for (int i = 0; i < RES_SIZE; i++) begin
            if (!ls_res_src_a_valid[i] && ls_res_src_a_robPt[i] == rob_idx) begin
                ls_res_src_a_value[i] = entry.dest_val;
                ls_res_src_a_valid[i] = 1'b1;
            end
            if (!ls_res_src_b_valid[i] && ls_res_src_b_robPt[i] == rob_idx) begin
                ls_res_src_b_value[i] = entry.dest_val;
                ls_res_src_b_valid[i] = 1'b1;
            end
            if (!ls_res_addr_valid[i] && ls_res_addr_robPt[i] == rob_idx) begin
                ls_res_addr_value[i] = entry.dest_val;
                ls_res_addr_valid[i] = 1'b1;
            end
        end
    endfunction


    function void flush();
        for (int i =0; i < RES_SIZE; i++) begin
            zero_entry(i);
        end
        ls_rs_head = 0;
        ls_rs_tail = 0;
        ls_rs_size = 0;
    endfunction

endmodule;

`endif
