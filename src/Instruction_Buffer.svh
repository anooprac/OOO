`ifndef INSTRUCTION_BUFFER_SVH
`define INSTRUCTION_BUFFER_SVH

`include "opcodes.svh"
`include "Memory.svh"

//***INSTRUCTION BUFFER***//
parameter INSTRUCTION_BUFFER_SIZE = 8;

typedef struct packed {
    logic [INSN_WIDTH-1:0] insn;
    opcodes_t op;
    logic [ADDR_WIDTH-1:0] other_pc;
    logic [ADDR_WIDTH-1:0] pc;
    logic prediction;
} ib_entry_t;


module Instruction_Buffer();

    static logic [INSN_WIDTH-1:0] ib_insnbits [INSTRUCTION_BUFFER_SIZE-1:0];
    static opcodes_t ib_op [INSTRUCTION_BUFFER_SIZE-1:0];
    static logic [ADDR_WIDTH-1:0] ib_other_pc [INSTRUCTION_BUFFER_SIZE-1:0];
    static logic [ADDR_WIDTH-1:0] ib_pc [INSTRUCTION_BUFFER_SIZE-1:0];
    static logic ib_prediction [INSTRUCTION_BUFFER_SIZE-1:0];
    static int ib_head = 0;
    static int ib_tail = 0;
    static int ib_size = 0;

    initial begin
        $dumpfile("out/ooo_cpu.vcd");
        $dumpvars(0, Instruction_Buffer);
        for (int i = 0; i < INSTRUCTION_BUFFER_SIZE; i++) begin
            $dumpvars(0, ib_insnbits[i], ib_other_pc[i], ib_pc[i]);
        end
    end

    function logic is_full();
        return (ib_size == INSTRUCTION_BUFFER_SIZE - 1);
    endfunction

    function logic is_empty();
        return (ib_size == 0);  
    endfunction
  

    function void enqueue([INSN_WIDTH-1:0] insn, opcodes_t op, [ADDR_WIDTH-1:0] other_pc, [ADDR_WIDTH-1:0] pc, logic prediction);
        if (!is_full()) begin
            //$display("calling IB enqueue on op %h", insn);
            ib_insnbits[ib_head] = insn;
            ib_op[ib_head] = op;
            ib_other_pc[ib_head] = other_pc;
            ib_pc[ib_head] = pc;
            ib_prediction[ib_head] = prediction;
            
            ib_head = (ib_head + 1) % INSTRUCTION_BUFFER_SIZE;
            ib_size = ib_size + 1;
        end
    endfunction

    function ib_entry_t dequeue(); 
        ib_entry_t ib;
        ib.insn = ib_insnbits[ib_tail];
        ib.op = ib_op[ib_tail];
        // $display("Calling IB dequeue on op %s", ib_op[ib_tail].name());
        //$display("insn bits: %h", ib.insn);
        ib.other_pc = ib_other_pc[ib_tail];
        ib.pc = ib_pc[ib_tail];
        ib.prediction = ib_prediction[ib_tail];


        ib_insnbits[ib_tail] = {INSN_WIDTH{1'b0}};
        ib_op[ib_tail] = OP_ERR;
        ib_other_pc[ib_tail] = {ADDR_WIDTH{1'b0}};
        ib_pc[ib_tail] = {ADDR_WIDTH{1'b0}};
        ib_prediction[ib_tail] = 1'b0;
        
        ib_tail = (ib_tail + 1) % INSTRUCTION_BUFFER_SIZE;
        ib_size = ib_size - 1;

        return ib;
    endfunction

    function opcodes_t get_op();
        return ib_op[ib_tail];
    endfunction

    function void flush();
        for (int i = 0; i < INSTRUCTION_BUFFER_SIZE; i ++) begin
            ib_insnbits[i] = {INSN_WIDTH{1'b0}};
            ib_op[i] = OP_ERR;
            ib_other_pc[i] = {ADDR_WIDTH{1'b0}};
            ib_pc[i] = {ADDR_WIDTH{1'b0}};
            ib_prediction[i] = 1'b0;
        end
        ib_head = 0;
        ib_tail = 0;
        ib_size = 0;
    endfunction

endmodule


`endif
