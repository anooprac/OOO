// `ifndef STRUCTURES_SVH
// `define STRUCTURES_SVH

// `include "opcodes.svh"
// //***MEMORY***//
// parameter ADDR_WIDTH = 64;
// parameter ADDR_SIZE = 4096*3;
// parameter DATA_WIDTH = 8;

// module Memory();

//     static logic [ADDR_WIDTH-1:0] text_start_addr;
//     static logic [ADDR_WIDTH-1:0] text_size;
//     static logic [ADDR_WIDTH-1:0] data_start_addr;
//     static logic [ADDR_WIDTH-1:0] data_size;
//     static logic [ADDR_WIDTH-1:0] entry;

//     static reg [DATA_WIDTH-1:0] mem [ADDR_SIZE]; 


//     integer idx;
//     initial begin
//         // $dumpfile("out/mem.vcd");
//         // $dumpvars(0, Memory);
//         //for (idx = 0; idx < ADDR_SIZE; idx = idx + 1) $dumpvars(0, mem[idx]);
//     end
 
//     function [DATA_WIDTH-1:0] getMemory([ADDR_WIDTH-1:0] addr);
//         return mem[translation(addr)];
//     endfunction 

//     function void setMemory([ADDR_WIDTH-1:0] addr, [DATA_WIDTH-1:0] data);
//         mem[translation(addr)] = data;
//     endfunction

//     function [ADDR_WIDTH-1:0] translation([ADDR_WIDTH-1:0] addr);
//         if (addr >= text_start_addr && addr < text_start_addr + text_size) begin
//             return addr - text_start_addr;
//         end else if (addr >= data_start_addr && addr < data_start_addr + data_size) begin
//             return addr - data_start_addr;
//         end 
//     endfunction
    
// endmodule

// //***INSTRUCTION BUFFER***//
// parameter INSTRUCTION_BUFFER_SIZE = 8;

// typedef struct packed {
//     logic [INSN_WIDTH-1:0] insn;
//     opcodes_t op;
//     logic [ADDR_WIDTH-1:0] seq_succ_pc;
//     logic [ADDR_WIDTH-1:0] pc;
// } ib_t;


// module Instruction_Buffer();

//     static logic [INSN_WIDTH-1:0] ib_insnbits [INSTRUCTION_BUFFER_SIZE-1:0];
//     static opcodes_t ib_op [INSTRUCTION_BUFFER_SIZE-1:0];
//     static logic [ADDR_WIDTH-1:0] ib_seq_succ_pc [INSTRUCTION_BUFFER_SIZE-1:0];
//     static logic [ADDR_WIDTH-1:0] ib_pc [INSTRUCTION_BUFFER_SIZE-1:0];
//     static int Instruction_Buffer_Head = 0;
//     static int Instruction_Buffer_Tail = 0;
//     static int Instruction_Buffer_Size = 0;

//     initial begin
//          $dumpfile("out/ooo_cpu.vcd");
//         $dumpvars(0, Instruction_Buffer);
//     end

//     function logic is_full();
//         return (Instruction_Buffer_Size == INSTRUCTION_BUFFER_SIZE);
//     endfunction
  

//     function void enqueue([INSN_WIDTH-1:0] insn, opcodes_t op, [ADDR_WIDTH-1:0] seq_succ_pc, [ADDR_WIDTH-1:0] pc);
//         if (!is_full()) begin
//             $display("calling IB enqueue on op %h", insn);
//             ib_insnbits[Instruction_Buffer_Head] = insn;
//             ib_op[Instruction_Buffer_Head] = op;
//             ib_seq_succ_pc[Instruction_Buffer_Head] = seq_succ_pc;
//             ib_pc[Instruction_Buffer_Head] = pc;
            
//             Instruction_Buffer_Head = (Instruction_Buffer_Head + 1) % INSTRUCTION_BUFFER_SIZE;
//             Instruction_Buffer_Size = Instruction_Buffer_Size + 1;
//         end
//     endfunction

//     function ib_t dequeue(); 
//         ib_t ib;
//         if (Instruction_Buffer_Size > 0) begin
//             ib.insn = ib_insnbits[Instruction_Buffer_Tail];
//             ib.op = ib_op[Instruction_Buffer_Tail];
//             // $display("Calling IB dequeue on op %s", ib_op[Instruction_Buffer_Tail].name());
//             $display("insn bits: %h", ib.insn);
//             ib.seq_succ_pc = ib_seq_succ_pc[Instruction_Buffer_Tail];
//             ib.pc = ib_pc[Instruction_Buffer_Tail];

//             Instruction_Buffer_Tail = (Instruction_Buffer_Tail + 1) % INSTRUCTION_BUFFER_SIZE;
//             Instruction_Buffer_Size = Instruction_Buffer_Size - 1;
//         end
//         return ib;
//     endfunction

// endmodule

// //***REGISTER FILE***//
// // DO NOT WRITE TO THE $zero
// parameter NUM_REGS = 34; //0-31 is General Purpose, 31 is both XZR, SP, 32 is NZCV
// parameter SP_NUM = 31;
// parameter LR_NUM = 30;
// parameter XZR_NUM= 32;
// parameter NZCV_NUM = 33;
// parameter REG_SIZE = 64;

// parameter ROB_SIZE = 16;

// module Register_File();
//     static logic rf_valid [NUM_REGS-1:0];
//     static logic [REG_SIZE-1:0] rf_value [NUM_REGS-1:0];
//     static logic [$clog2(ROB_SIZE)-1:0] rf_robPt [NUM_REGS-1:0];
//     // static logic nzcv_valid; 
//     // static logic [3:0] nzcv_value;
//     // static logic [ROB_SIZE-1:0] nzcv_robPt;

//     function logic is_valid(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
//         if (reg_idx == XZR_NUM) return 1'b1;
//         else return rf_valid[reg_idx];
//     endfunction

//     function void invalidate(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
//         if (reg_idx == XZR_NUM) return;
//         rf_valid[reg_idx] = 0;
//     endfunction

//     function logic [REG_SIZE - 1:0] get_regval(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
//         if (reg_idx == XZR_NUM) return {64{1'b0}};
//         return rf_value[reg_idx];
//     endfunction

//     function logic [$clog2(ROB_SIZE) - 1:0] get_rob_ptr(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
//         return rf_robPt[reg_idx];
//     endfunction

//     function void set_value(logic [$clog2(NUM_REGS) - 1:0] reg_idx, logic [REG_SIZE - 1:0] reg_val);
//         rf_value[reg_idx] = reg_val;
//         rf_valid[reg_idx] = 1'b1;
//     endfunction
// endmodule

// //***REORDER BUFFER***//

// module Reorder_Buffer();
//     logic [ROB_SIZE - 1:0] val_ready;
//     logic [INSN_WIDTH - 1:0] instruction [ROB_SIZE - 1:0];
//     logic [$clog2(NUM_REGS) - 1:0] dest_idx [ROB_SIZE - 1:0];
//     logic [REG_SIZE - 1:0] dest_val [ROB_SIZE - 1:0];
//     logic [ROB_SIZE - 1:0] modified_nzcv;
//     logic [REG_SIZE - 1:0] nzcv_val [ROB_SIZE - 1:0]; // 4 bits for NZCV, zero-pad to REG_SIZE
//     int ROB_Head = 0;
//     int ROB_Tail = 0;
//     int ROB_Size = 0;


//     function logic is_full();
//         return (ROB_Size == ROB_SIZE) ? 1'b1 : 1'b0;
//     endfunction
    
//     function logic is_entry_valid(logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
//         return val_ready[rob_idx];
//     endfunction
    
//     function logic[REG_SIZE - 1:0] get_val([$clog2(ROB_SIZE) - 1:0] rob_idx);
//         return dest_val[rob_idx];
//     endfunction

//     function logic is_nzcv_modified([$clog2(ROB_SIZE) - 1:0] rob_idx);
//         return modified_nzcv[rob_idx];
//     endfunction
    
//     function logic[REG_SIZE - 1:0] get_nzcv([$clog2(ROB_SIZE) - 1:0] rob_idx);
//         return nzcv_val[rob_idx];
//     endfunction
    

//     // append to the ROB when decode stage is done
//     function void enqueue(logic [$clog2(NUM_REGS) - 1:0] dest, logic [INSN_WIDTH - 1:0] instruction, logic md_nzcv);
//         if (!is_full()) begin
//             val_ready[ROB_Head] = 1'b0;
//             instruction[ROB_Head] = instruction;
//             dest_idx[ROB_Head] = dest;
//             modified_nzcv[ROB_Head] = md_nzcv;

//             ROB_Head = (ROB_Head + 1)% ROB_Size;
//             ROB_Size = ROB_Size + 1;
//         end
//     endfunction

//     function void load_and_broadcast(logic [$clog2(ROB_SIZE) - 1:0] rob_idx, logic [REG_SIZE - 1:0] val, logic [REG_SIZE - 1:0] nzcv, logic mod_nzcv);
//         // add the data to the ROB entry
//         dest_val[rob_idx] = val;
//         if (mod_nzcv) nzcv_val[rob_idx] = nzcv;
//         val_ready[rob_idx] = 1'b1;
//         // TODO: send the data to CDB (or wherever it needs to go)
//     endfunction

//     function void commit();
//         // TODO: top of the ROB is ready to commit
//     endfunction
    
// endmodule

// parameter RES_SIZE = 4;
// //***RESERVATION STATIONS***//

// // ALU RESERVATION STATION

// module ALU_Reservation_Station();


//     cond_t res_cond [RES_SIZE-1:0];


//     logic [$clog2(NUM_REGS) - 1:0] res_reg_a_idx [RES_SIZE-1:0];
//     logic [REG_SIZE-1:0] res_val_a_value [RES_SIZE-1:0];
//     logic res_val_a_valid [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_val_a_robPt_src [RES_SIZE-1:0];


//     logic [$clog2(NUM_REGS) - 1:0] res_reg_b_idx [RES_SIZE-1:0];
//     logic [REG_SIZE-1:0] res_val_b_value [RES_SIZE-1:0];
//     logic res_val_b_valid [RES_SIZE-1:0];
//     logic res_val_b_is_imm;
//     logic [ROB_SIZE-1:0] res_val_b_robPt_src [RES_SIZE-1:0];
//     logic [MAX_IMM-1:0] res_val_imm [RES_SIZE-1:0];
//     logic [1:0] res_val_hw [RES_SIZE-1:0];


//     logic [REG_SIZE - 1:0] res_val_nzcv_value [RES_SIZE-1:0];
//     logic res_val_nzcv_valid [RES_SIZE-1:0];
//     logic res_val_requires_nzcv [RES_SIZE - 1:0];
//     logic [ROB_SIZE-1:0] res_val_nzcv_robPt_src [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_val_nzcv_robPt_dest [RES_SIZE-1:0];


//     logic [ROB_SIZE-1:0] res_dest [RES_SIZE-1:0];

//     //Reservation Station
//     opcodes_t res_op [INSTRUCTION_BUFFER_SIZE-1:0];
//     logic [ADDR_WIDTH-1:0] res_seq_succ_pc [RES_SIZE-1:0];

//     // [1] valb selector: 0 for immediate, 1 for register.
//     // [0] Whether to set condition flags: 0 for no, 1 for yes.
//     logic [1:0] res_X_sigs [RES_SIZE-1:0]; 

//     // [1] 1 if memory access is a read, 0 if not.
//     // [0] 1 if memory access is a write, 0 if not.
//     logic [1:0] res_M_sigs [RES_SIZE-1:0];

//     // [2] dst selector: 1 for X30 (in BL), 0 otherwise.
//     // [1] wval selector: 1 for LDUR, 0 otherwise.
//     // [0] Whether to perform a write: 0 for no, 1 for yes.
//     logic [2:0] res_W_sigs [RES_SIZE-1:0];

//     int head = 0;
//     int tail = 0;
//     int size = 0;

//     function void enqueue(logic[$clog2(NUM_REGS) - 1:0] reg_a_idx, logic val_b_is_imm, logic[$clog2(NUM_REGS) - 1:0] reg_b_idx,
//                             logic[MAX_IMM - 1:0] imm_val, logic requires_nscv, logic[$clog2(NUM_REGS) - 1:0] dest_reg_idx, opcodes_t op,
//                             logic[INSN_WIDTH - 1:0] insnbits, logic has_hw, logic[1:0] val_hw);

//         //handle reg a first
//         if (rf.is_valid(reg_a_idx)) begin
//             res_val_a_valid[head] = 1'b1;
//             res_val_a_value[head] = rf.get_regval(reg_a_idx);
//         end
//         else if (rob.is_entry_valid(rf.get_rob_ptr(reg_a_idx))) begin
//             res_val_a_valid[head] = 1'b1;
//             res_val_a_value[head] = rob.get_val(rf.get_rob_ptr(reg_a_idx));
//         end
//         else begin
//             res_val_a_robPt_src[head] = rf.get_rob_ptr(reg_a_idx);
//         end

//         //handle reg b next
//         if (val_b_is_imm) begin
//             res_val_b_is_imm = 1'b1;
//             res_val_imm = imm_val;
//         end
//         else if (rf.is_valid(reg_b_idx)) begin
//             res_val_b_valid[head] = 1'b1;
//             res_val_b_value[head] = rf.get_regval(reg_b_idx);
//         end
//         else if (rob.is_entry_valid(rf.get_rob_ptr(reg_b_idx))) begin
//             res_val_b_valid[head] = 1'b1;
//             res_val_b_value[head] = rob.get_val(rf.get_rob_ptr(reg_b_idx));
//         end
//         else begin
//             res_val_b_robPt_src[head] = rf.get_rob_ptr(reg_b_idx);
//         end

//         //handle nzcv dependencies
//         if (requires_nscv) begin
//             if (rf.is_valid(NZCV_NUM)) begin
//                 res_val_nzcv_value[head] = rf.get_regval(NZCV_NUM);
//             end

//         end
//     endfunction

//     initial begin
//         $dumpfile("out/ooo_cpu.vcd");
//        $dumpvars(0, Instruction_Buffer);
//     end
// endmodule;


// //L/S RESERVATION STATION

// module LS_Reservation_Station();
//     //LOAD STORE RESERVATION STATION
//     cond_t res_lsu_cond [RES_SIZE-1:0];
//     logic [REG_SIZE-1:0] res_lsu_val_a_value [RES_SIZE-1:0];
//     logic res_lsu_val_a_valid [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_a_robPt_src [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_a_robPt_dest [RES_SIZE-1:0];
//     logic [REG_SIZE-1:0] res_lsu_val_b_value [RES_SIZE-1:0];
//     logic res_lsu_val_b_valid [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_b_robPt_src [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_b_robPt_dest [RES_SIZE-1:0];
//     logic [MAX_IMM-1:0] res_lsu_val_imm [RES_SIZE-1:0];
//     logic [1:0] res_lsu_val_hw [RES_SIZE-1:0];
//     logic [3:0] res_lsu_val_nzcv_value [RES_SIZE-1:0];
//     logic res_lsu_val_nzcv_valid [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_nzcv_robPt_src [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_val_nzcv_robPt_dest [RES_SIZE-1:0];
//     logic [ROB_SIZE-1:0] res_lsu_dest [RES_SIZE-1:0];


//     int LS_Reservation_Station_Head = 0;
//     int LS_Reservation_Station_Tail = 0;
//     int size = 0;
// endmodule;

// `endif
