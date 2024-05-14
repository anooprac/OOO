`ifndef REORDER_BUFFER_SVH
`define REORDER_BUFFER_SVH

`include "opcodes.svh"
`include "fetch.svh"
`include "Register_File.svh"
`include "Reorder_Buffer.svh"
`include "Reservation_Stations.svh"
`include "Instruction_Buffer.svh"
`include "Memory.svh"

parameter ROB_SIZE = 8;

typedef struct packed {
    logic [$clog2(NUM_REGS) - 1:0] dest_idx;
    logic [INSN_WIDTH - 1:0] instruction;
    logic [REG_SIZE - 1:0] dest_val;
    logic valid;
    logic [REG_SIZE - 1:0] nzcv_val;
    logic modified_nzcv;
    logic modified_pc;
    logic [63:0] pc_val;
    logic store;
    logic [ADDR_WIDTH - 1:0] addr;
    logic addr_valid;

} rob_entry_t;

//***REORDER BUFFER***//
module Reorder_Buffer();



    static logic [ROB_SIZE - 1:0] val_ready;
    static logic [INSN_WIDTH - 1:0] instruction [ROB_SIZE - 1:0];
    static logic [$clog2(NUM_REGS) - 1:0] dest_idx [ROB_SIZE - 1:0];
    static logic [REG_SIZE - 1:0] dest_val [ROB_SIZE - 1:0];
    static logic [ROB_SIZE - 1:0] modified_nzcv;
    static logic [REG_SIZE - 1:0] nzcv_val [ROB_SIZE - 1:0]; // 4 bits for NZCV, zero-pad to REG_SIZE
    static logic [ROB_SIZE - 1:0] modified_pc;
    static logic [REG_SIZE - 1:0] pc_val [ROB_SIZE - 1:0];
    static logic [ROB_SIZE - 1:0] store;
    static logic [ADDR_WIDTH - 1:0] addr [ROB_SIZE - 1:0];
    static logic [ROB_SIZE - 1:0] addr_valid;
    static int ROB_Head = 0;
    static int ROB_Tail = 0;
    static int ROB_Size = 0;
    
    
    initial begin
        $dumpfile("out/ooo_cpu.vcd");        
        $dumpvars(0, Reorder_Buffer);
        for (int i = 0; i < ROB_SIZE; i ++) begin
            $dumpvars(0, instruction[i], dest_idx[i], dest_val[i], nzcv_val[i], pc_val[i], addr[i]);
        end

    end

    function void init_rob();
        for (int i = 0; i < ROB_SIZE; i++) begin
            store[i] = 1'b0;
        end
    endfunction
    function logic is_full();
        return (ROB_Size == ROB_SIZE - 2) ? 1'b1 : 1'b0;
    endfunction

    function logic is_empty();
        return (ROB_Size == 0) ? 1'b1 : 1'b0;
    endfunction
    
    function logic is_entry_valid(logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
        return val_ready[rob_idx];
    endfunction
    
    function logic[REG_SIZE - 1:0] get_val([$clog2(ROB_SIZE) - 1:0] rob_idx);
        return dest_val[rob_idx];
    endfunction

    function logic is_nzcv_modified([$clog2(ROB_SIZE) - 1:0] rob_idx);
        return modified_nzcv[rob_idx];
    endfunction
    
    function logic[REG_SIZE - 1:0] get_nzcv([$clog2(ROB_SIZE) - 1:0] rob_idx);
        return nzcv_val[rob_idx];
    endfunction


    

    // append to the ROB when decode stage is done
    function automatic logic [$clog2(ROB_SIZE) - 1:0] enqueue(logic [$clog2(NUM_REGS) - 1:0] dest, logic [INSN_WIDTH - 1:0] insn, logic md_nzcv);
        logic [$clog2(ROB_SIZE) - 1:0] OG_head;
        OG_head = -1;
        if (!is_full()) begin
            val_ready[ROB_Head] = 1'b0;
            instruction[ROB_Head] = insn;
            dest_idx[ROB_Head] = dest;
            modified_nzcv[ROB_Head] = md_nzcv;

            OG_head = ROB_Head;

            ROB_Head = (ROB_Head + 1)% ROB_SIZE;
            // $display("Adding to rob");
            ROB_Size = ROB_Size + 1;
        end
        return OG_head;
    endfunction

    
    function  automatic logic [$clog2(ROB_SIZE) - 1:0] enqueue_store(logic [INSN_WIDTH - 1:0] insn);
        logic [$clog2(ROB_SIZE) - 1:0] OG_head;
        OG_head = -1;
        if (!is_full()) begin
            val_ready[ROB_Head] = 1'b0;
            instruction[ROB_Head] = insn;
            store[ROB_Head] = 1'b1;
            addr_valid[ROB_Head] = 1'b0;

            OG_head = ROB_Head;

            ROB_Head = (ROB_Head + 1)% ROB_SIZE;
            ROB_Size = ROB_Size + 1;

        end
        return OG_head;
    endfunction

    function void set_addr(logic [$clog2(ROB_SIZE) - 1:0] rob_idx, logic [ADDR_WIDTH - 1:0] dest_addr);
        addr_valid[rob_idx] = 1'b1;
        addr[rob_idx] = dest_addr;
    endfunction

    function automatic logic [$clog2(ROB_SIZE):0] get_newest_rob_idx_of_addr(logic [ADDR_WIDTH - 1:0] dest_addr);
        logic [$clog2(ROB_SIZE) - 1:0] idx = ROB_Head;
        for(int i = 0; i < ROB_SIZE; i++) begin
            if (store[idx] && addr_valid[idx] && addr[idx] == dest_addr) begin
                return {1'b1, idx};
            end
            idx = (idx - 1) % ROB_SIZE;
        end
        return {1'b0, idx};
    endfunction

    function  logic [REG_SIZE - 1:0] get_dest_val(logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
        return dest_val[rob_idx];
    endfunction



    function rob_entry_t write_entry(logic [$clog2(ROB_SIZE) - 1:0] rob_idx, logic [REG_SIZE - 1:0] val, logic [3:0] nzcv, logic mod_nzcv, logic mod_pc, logic [63:0] pc);
        // add the data to the ROB entry
        rob_entry_t entry;
        dest_val[rob_idx] = val;
        if (mod_nzcv) nzcv_val[rob_idx] = {{60{1'b0}}, nzcv};
        modified_nzcv[rob_idx] = mod_nzcv;
        pc_val[rob_idx] = pc;
        modified_pc[rob_idx] = mod_pc;
        val_ready[rob_idx] = 1'b1;
        entry.dest_idx = dest_idx[rob_idx];
        entry.instruction = instruction[rob_idx];
        entry.dest_val = dest_val[rob_idx];
        entry.valid = val_ready[rob_idx];
        entry.nzcv_val = nzcv_val[rob_idx];
        entry.modified_nzcv = modified_nzcv[rob_idx];
        entry.modified_pc = modified_pc[rob_idx];
        entry.pc_val = pc_val[rob_idx];
        return entry;
    endfunction

    function void write_store_entry(logic [$clog2(ROB_SIZE) - 1:0] rob_idx, logic [REG_SIZE - 1:0] val);
        dest_val[rob_idx] = val;
        val_ready[rob_idx] = 1'b1;
     endfunction

    function logic [63:0] get_tail_pc();
        // $display("Rob tail pc: %h", pc_val[ROB_Tail]);
        return pc_val[ROB_Tail];
    endfunction

    function void zero_rob_entry(logic [$clog2(ROB_SIZE)-1:0] idx);
        val_ready[idx] = 1'bx;
        instruction[idx] = {INSN_WIDTH{1'bx}};
        dest_idx[idx] = {$clog2(NUM_REGS){1'bx}};
        dest_val[idx] = {REG_SIZE{1'bx}};
        modified_nzcv = 1'bx;
        nzcv_val[idx] = {REG_SIZE{1'bx}}; // 4 bits for NZCV, zero-pad to REG_SIZE
        modified_pc[idx] = 1'bx;
        pc_val[idx] = {REG_SIZE{1'bx}};
        store[idx] = 1'bx;
        addr[idx] = {ADDR_WIDTH{1'bx}};
        addr_valid[idx] = 1'bx;
    endfunction

    function void flush();
        ROB_Head = 0;
        ROB_Tail = 0;
        ROB_Size = 0;
        for (int i = 0; i < ROB_SIZE; i++)
            zero_rob_entry(i);
    endfunction


    function logic commit();
        // $display("Rob size before commit: %d, tail: %d, head: %d, op: %d", ROB_Size, ROB_Tail, ROB_Head, decode_opcode(instruction[ROB_Tail]));
        if (val_ready[ROB_Tail]) begin
            // Normal Instruction
            // Mispredicted branch
            // Store

            if (modified_pc[ROB_Tail]) begin
                // need to flush everything
                $display("Flushing everything");
                flush();
                ib.flush();
                alu_rs.flush();
                ls_rs.flush();
                rf.set_all_valid();
                return 1'b1;
            end 
            if (store[ROB_Tail]) begin
                if (!addr_valid[ROB_Tail])
                    $display("WARNING: address not valid for commiting store.");
                // if (addr[ROB_Tail]==12256 && dest_val[ROB_Tail][7:0]==0) $display("ERROR!!");
                mem.setMemory(addr[ROB_Tail], dest_val[ROB_Tail][7:0]);
                mem.setMemory(addr[ROB_Tail]+1, dest_val[ROB_Tail][15:8]);
                mem.setMemory(addr[ROB_Tail]+2, dest_val[ROB_Tail][23:16]);
                mem.setMemory(addr[ROB_Tail]+3, dest_val[ROB_Tail][31:24]);
                mem.setMemory(addr[ROB_Tail]+4, dest_val[ROB_Tail][39:32]);
                mem.setMemory(addr[ROB_Tail]+5, dest_val[ROB_Tail][47:40]);
                mem.setMemory(addr[ROB_Tail]+6, dest_val[ROB_Tail][55:48]);
                mem.setMemory(addr[ROB_Tail]+7, dest_val[ROB_Tail][63:56]);
                $display("COMMITTED TO MEMORY: ADDR: %h; VALUE: %d", addr[ROB_Tail], dest_val[ROB_Tail]);
                store[ROB_Tail] = 1'b0;
            end else begin
                // $display("Committing insn: %h, rob entry %d with addr: %h",instruction[ROB_Tail], ROB_Tail, addr[ROB_Tail]);
                // if instruction modified nzcv, write it now
                // set_value now needs rob_idx to make sure dest is not in use by later instructions
                // these instructions are guarenteed to be later due to in-order dequeue from ib
                if (modified_nzcv[ROB_Tail]) begin
                    $display("Writing NZCV val: %4b", nzcv_val[ROB_Tail]);
                    rf.set_value(NZCV_NUM, nzcv_val[ROB_Tail], ROB_Tail);
                end
                rf.set_value(dest_idx[ROB_Tail], dest_val[ROB_Tail], ROB_Tail);
            end



            zero_rob_entry(ROB_Tail);

            ROB_Tail = (ROB_Tail + 1) % ROB_SIZE;
            ROB_Size = ROB_Size - 1;
            return 1'b0;
        end 
        // $display("Rob size after commit: %d", ROB_Size);
    endfunction
    
endmodule


`endif
