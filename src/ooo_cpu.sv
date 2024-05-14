`timescale 1ns / 1ps
`default_nettype none

`include "utils.svh"
`include "opcodes.svh"

`include "Reservation_Stations.svh"
`include "Memory.svh"
`include "Instruction_Buffer.svh"
`include "Register_File.svh"
`include "Reorder_Buffer.svh"
`include "fetch.svh"
`include "decode.svh"
`include "Arithmetic_Logic_Unit.svh"
`include "Gshare.svh"
`include "Load_Store_Unit.svh"

`define DEBUG

module ooo_cpu
  ( input wire rst_in_N,                // asynchronous active-low reset
    input wire clk_in,                  // clock
    input wire start_in,
    input logic [DATA_WIDTH-1:0] mem_in [ADDR_SIZE],
    input logic init,
    input reg [63:0] text_start_addr_in,
    input reg [63:0] data_start_addr_in,
    input reg [63:0] text_size_in,
    input reg [63:0] data_size_in,
    input reg [63:0] entry_in,
    output logic [63:0] reg_file_out [31:0],  // register file
    output logic [3:0] nzcv_out,
    output logic [63:0] pc_out,
    output logic done_out
    );

  //----CONTROL SIGNALS
  reg fetch_ready = 1'b0;
  reg decode_ready = 1'b0;
  reg execute_ready = 1'b0;
  reg writeback_ready = 1'b0;
  logic halt = 1'b0;

  //----STRUCTURES
  Memory mem();
  Instruction_Buffer ib();
  Register_File rf();
  ALU_Reservation_Station alu_rs();
  LS_Reservation_Station ls_rs();
  Reorder_Buffer rob();
  Arithmetic_Logic_Unit alu();
  Gshare gshare();
  Load_Store_Unit lsu();

  //----DEBUG
  `ifdef DEBUG
  int clock_counter = 0;
  // dump clock
  always @(posedge clk_in) begin
    clock_counter = clock_counter + 1;
    //$display("clock = %d", clock_counter);
  end
  always @(fetch_ready) begin
      // $display("text start in cpu = %h", text_start_addr);
      // $display("data start in cpu = %h", data_start_addr);   
      // $display("text size in cpu = %h", text_size);
      // $display("data size in cpu = %h", data_size);
      // $display("entry in cpu = %h", entry);

      //  for(int i = 0; i < 1000; i++) begin
      //      $display("mem in cpu = : %h", mem.mem[i]);
      //  end
  end

  // dump the mem 2d array
  integer idx;
  initial begin
    $dumpfile("out/ooo_cpu.vcd");
    $dumpvars(0, ooo_cpu);
  end
  `endif

  //----INITIALIZATION
  always @(posedge clk_in) begin
    if (init) begin
      mem.text_start_addr <= text_start_addr_in;
      mem.data_start_addr <= data_start_addr_in;
      mem.text_size <= text_size_in;
      mem.data_size <= data_size_in;
      mem.entry <= entry_in;
      pred_pc <= entry_in;
      fetch_ready <= 1'b1;
      for (int i = 0; i < ADDR_SIZE; i++) begin
        mem.mem[i] <= mem_in[i];
      end
      rf.set_inital_valid();
      alu_rs.init_bitmap();
      gshare.init_buffers();
      rob.init_rob();
    end
  end
  
  
  //----FETCH 

  logic [ADDR_WIDTH-1:0] pred_pc;
  logic X_mispredict = 1'b0;
  logic [ADDR_WIDTH-1:0] X_other_pc;
  // Need to hold on to the branch target of an insn in the case 
  // of predicted not taken, actually taken (or just refetch)
  // logic [ADDR_WIDTH-1:0] X_branch_offset;
  logic [27:0] branch_offset = 28'h000000;
  always @(posedge clk_in) begin
    branch_offset = 28'h000000;
    if (ib.is_full() || halt) begin
      fetch_ready <= 1'b0;
    end 
    else begin
      fetch_ready <= 1'b1;
    end
    if (fetch_ready) begin
      // Temporary variables
      logic [31:0] current_insn;
      opcodes_t current_op;      
      logic [ADDR_WIDTH-1:0] correct_pc;
      logic [ADDR_WIDTH-1:0] other_pc;
      logic [ADDR_WIDTH-1:0] branch_target;
      logic prediction;


      // Fix pc if prediction was wrong
      correct_pc = X_mispredict ? X_other_pc : pred_pc;
      if (X_mispredict) begin
        $display("Setting pc to %h", X_other_pc);
        // If link reg is zero, then it's the return from main
        if (X_other_pc==64'd0) halt = 1'b1;
        correct_pc = X_other_pc;
        X_mispredict = 1'b0;
      end else 
        correct_pc = pred_pc;
      // $display("Fetching addr: %d", correct_pc);
      // Fetch the current instruction
        current_insn={mem.getMemory(correct_pc+3), 
                      mem.getMemory(correct_pc+2),
                      mem.getMemory(correct_pc+1),
                      mem.getMemory(correct_pc)};                
      // Extract the opcode and branch offset from the current instruction
      $display("Fetching %h, insn bits: %8h", correct_pc, current_insn);
      current_op = decode_opcode(current_insn);
      // Instruction aliases
      //current_op = decide_alias_op(current_op);
      //$display("curr op = %s\n", current_op.name());

      
      $display("Fetched %s at %8h", current_op.name(), correct_pc);
      // Determine the next predicted PC based on the current instruction
      if (current_op == OP_Bcond || current_op == OP_CBNZ || current_op == OP_CBZ) begin
        branch_offset = current_insn[23:5]*4;
        if (branch_offset > 1<<20) begin
          branch_target = correct_pc - ((~branch_offset[20:0] & {21{1'b1}})+1);
        end else
          branch_target = correct_pc + branch_offset;
        prediction = gshare.get_prediction(correct_pc);
        pred_pc = prediction ? branch_target : correct_pc + 4;
        other_pc = prediction ? correct_pc + 4 : branch_target;
        // $display("Bcond setting pred_pc: %h, branch target: %h", pred_pc, branch_target);
      end 
      else if (current_op == OP_B || current_op == OP_BL) begin
        branch_offset = current_insn[25:0]*4;
        if (branch_offset > 1<<27)
          pred_pc = correct_pc - ((~branch_offset & {28{1'b1}})+1);
        else
          pred_pc = branch_offset + correct_pc;
        other_pc = pred_pc;
      end
      else begin
        pred_pc = correct_pc+4;
        other_pc = pred_pc;
      end
      
      // Update the Instruction_Buffer
      @(negedge clk_in) begin
        ib.enqueue(current_insn, current_op, other_pc, correct_pc, prediction);
      end
    end
  end


  //----DECODE

  always @(posedge clk_in) begin 
    logic [ADDR_WIDTH-1:0] D_pc;
    logic [31:0] D_current_insn;
    logic [ADDR_WIDTH-1:0] D_seq_succ_pc;
    logic [1:0] D_X_sigs;
    logic [2:0] D_M_sigs;
    logic [2:0] D_W_sigs;
    static ib_entry_t dequeued;
    static decode_outputs_t decoded;
    opcodes_t op;
    

    if ((ib.is_empty()) || alu_rs.is_full(ib.get_op()) || ls_rs.is_full(ib.get_op())|| rob.is_full() || halt) begin
      decode_ready = 1'b0;
    end 
    else begin
      decode_ready = 1'b1;
    end
    
    if (decode_ready) begin
      logic [$clog2(NUM_REGS) - 1:0] reg_a_idx;
      logic [$clog2(NUM_REGS) - 1:0] reg_b_idx;
      logic [$clog2(NUM_REGS) - 1:0] reg_c_idx;
      logic [$clog2(NUM_REGS) - 1:0] dest_reg_idx;
      logic [63:0] val_imm;
      logic cond;
      logic goto_alu_rs;
      logic [$clog2(ROB_SIZE) - 1:0] rob_entry_idx;

      dequeued = ib.dequeue();
      
      //op = dequeued.op;
      //$display("Issuing %s", op.name());
      decoded = decode_instruction(dequeued.op, dequeued.insn);
      @(negedge clk_in) begin
        // if any decoded.res_M signals are set, then its a memory instruction (ls_rs)
        // print D_M_sigs
        if (|decoded.D_M_sigs) begin
          //store
          // addr is dest
          // addir in a reg
          // the reg is a src
          // reg is not neccessarily valid
          // need to wait for broadcast if invalid
          // only then do we know the addr
          // and then we can fill the rob entry

          
          if (decoded.D_M_sigs[0]) begin
            // mark a rob spot for the store, need to put addr into rob entry idx later
            rob_entry_idx = rob.enqueue_store(dequeued.insn);
            ls_rs.enqueue(
            decoded,
            dequeued.insn,
            dequeued.op,
            rob_entry_idx
            );
          // store pair (rob_entry_idx, rob_entry_idx+1)
            if (decoded.D_M_sigs[2]) begin
              rob_entry_idx = rob.enqueue_store(dequeued.insn);
            end
          end
          //load
          else if (decoded.D_M_sigs[1]) begin
            rob_entry_idx = rob.enqueue(decoded.dest_reg_idx, dequeued.insn, 0);
            ls_rs.enqueue(
            decoded,
            dequeued.insn,
            dequeued.op,
            rob_entry_idx
            );
            rf.invalidate(decoded.dest_reg_idx);
            rf.set_rob_ptr(decoded.dest_reg_idx, rob_entry_idx);
            // load pair (rob_entry_idx, rob_entry_idx+1)
            if (decoded.D_M_sigs[2]) begin
              rob_entry_idx = rob.enqueue(decoded.dest2_reg_idx, dequeued.insn, 0);
              rf.invalidate(decoded.dest2_reg_idx);
              rf.set_rob_ptr(decoded.dest2_reg_idx, rob_entry_idx);
            end
          end

        end
        else begin
          //ALLOCATE ROB ENTRY
          rob_entry_idx = rob.enqueue(decoded.dest_reg_idx, dequeued.insn, decoded.D_X_sigs[0]);
          //$display("Enqueing %d, rob entry: %d", dequeued.op, rob_entry_idx);
          if (rob_entry_idx == -1) begin
            $display("ERROR ALLOCATING ROB ENTRY!");
          end

          //ADD TO RESERVATION STATION!
          alu_rs.enqueue(
            decoded,
            dequeued.insn,
            dequeued.op,
            rob_entry_idx,
            dequeued.other_pc,
            dequeued.pc,
            dequeued.prediction
          );

          //INVALIDATE REGFILE!
          // if (dequeued.op==OP_ADD) $display("Invalidating reg %d", decoded.dest_reg_idx);
          rf.invalidate(decoded.dest_reg_idx);
          rf.set_rob_ptr(decoded.dest_reg_idx, rob_entry_idx);
          if (decoded.D_X_sigs[0]) begin
            rf.invalidate(NZCV_NUM);
            rf.set_rob_ptr(NZCV_NUM, rob_entry_idx);
          end
          
        end

      end
    end
  end
  //----EXECUTE

  logic use_alu_rs = 1'b1;
  dispatch_outputs_t execute_record;
  ls_dispatch_outputs_t ls_execute_record;
  ls_values_t lsu_ret;
  logic [63:0] alu_ret;
  logic [3:0] nzcv;
  logic [63:0] branch_dest;
  rob_entry_t rob_entry_first;
  rob_entry_t rob_entry_second;
  opcodes_t opcode;
  logic [31:0] insn;
  
  always @(posedge clk_in) begin
    if ((alu_rs.is_empty() && ls_rs.is_empty()) || halt) begin
      execute_ready = 1'b0;
    end 
    else begin
      execute_ready = 1'b1;
    end

    if (execute_ready) begin
     
      if (!alu_rs.is_empty() && (use_alu_rs || ls_rs.is_empty())) begin
        // dispatch from alu_rs to alu
        execute_record = alu_rs.dispatch();
        if (execute_record.valid) begin 
          opcode = execute_record.res_op;
          // if (opcode==OP_Bcond)
          // $display("Execute other pc: %d", execute_record.res_other_pc);

          alu_ret = alu.alu(execute_record);
          // if (opcode==OP_LSL) $display("LSL result value: %d", alu_ret);
          nzcv = alu.set_nzcv(execute_record, alu_ret);
          branch_dest = alu.branch_address(execute_record);
          if (branch_dest==-1)
            $display("Mispredicted branch");
          // Update gshare
          if (execute_record.res_op == OP_Bcond || execute_record.res_op==OP_CBNZ || execute_record.res_op==OP_CBZ)
            gshare.update_prediction(execute_record.res_pc, branch_dest==-1);
          if (execute_record.res_op==OP_Bcond) $display("Bcond other pc: %h", execute_record.res_other_pc);

          rob_entry_first = rob.write_entry(execute_record.res_dest_rob_ptr, alu_ret, nzcv, execute_record.res_X_sigs[0], 
                                            (branch_dest == -1) || (execute_record.res_op==OP_RET) || (execute_record.res_op==OP_BR) || (execute_record.res_op==OP_BLR), 
                                            (execute_record.res_op==OP_RET)? execute_record.res_val_a_value : execute_record.res_other_pc);

          //$display("Broadcasting %s, %d", opcode.name(), execute_record.res_dest_rob_ptr);
          alu_rs.broadcast(rob_entry_first, execute_record.res_dest_rob_ptr);
          ls_rs.broadcast(rob_entry_first, execute_record.res_dest_rob_ptr);
        end
      end
     else begin
      ls_execute_record = ls_rs.dispatch();
      
      if (ls_execute_record.valid) begin
        // if load, then load value from memory and write to rob
        // if store then write value to rob
        lsu_ret = lsu.get_value(ls_execute_record);
        //load
        if (ls_execute_record.ls_res_M_sigs[1]) begin
          // $display("Executing load, load result: %h", lsu_ret.val_a);
          rob_entry_first = rob.write_entry(ls_execute_record.ls_res_dest_rob_ptr, lsu_ret.val_a, 0, 0, 0, 0);
          alu_rs.broadcast(rob_entry_first, ls_execute_record.ls_res_dest_rob_ptr);
          ls_rs.broadcast(rob_entry_first, ls_execute_record.ls_res_dest_rob_ptr);
          if (ls_execute_record.ls_res_M_sigs[2]) begin
            rob_entry_second = rob.write_entry((ls_execute_record.ls_res_dest_rob_ptr + 1) % ROB_SIZE, lsu_ret.val_b, 0, 0,0,0);
            $display("Broadcasting %d", (ls_execute_record.ls_res_dest_rob_ptr + 1) % ROB_SIZE);
            alu_rs.broadcast(rob_entry_second, (ls_execute_record.ls_res_dest_rob_ptr + 1) % ROB_SIZE);
            ls_rs.broadcast(rob_entry_second, (ls_execute_record.ls_res_dest_rob_ptr + 1) % ROB_SIZE);

          end
        end
        //store
        else if (ls_execute_record.ls_res_M_sigs[0]) begin
          rob.write_store_entry(ls_execute_record.ls_res_dest_rob_ptr, lsu_ret.val_a);
          if (ls_execute_record.ls_res_M_sigs[2]) begin
            rob.write_store_entry((ls_execute_record.ls_res_dest_rob_ptr + 1) % ROB_SIZE, lsu_ret.val_b);
          end
        end
        
      end

     end

      use_alu_rs = ~use_alu_rs;
    end 
  end


  //WRITEBACK

  always @(posedge clk_in) begin
    logic [63:0] rob_other_pc;
    if (rob.is_empty() || halt) begin
      writeback_ready = 1'b0;
    end 
    else begin
      writeback_ready = 1'b1;
    end

    if (writeback_ready) begin
      // rob_entry_t rob_entry = rob.read_entry();
      rob_other_pc = rob.get_tail_pc();
      if (rob.commit()) begin
        
        X_mispredict = 1'b1;
        X_other_pc = rob_other_pc;
        
      end
    end

    
  end

endmodule: ooo_cpu

`default_nettype wire
