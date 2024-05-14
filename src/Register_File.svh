`ifndef REGISTER_FILE_SVH
`define REGISTER_FILE_SVH

`include "Reorder_Buffer.svh"

//***REGISTER FILE***//
// DO NOT WRITE TO THE $zero
parameter NUM_REGS = 34; //0-31 is General Purpose, 31 is both XZR, SP, 32 is NZCV
parameter SP_NUM = 31;
parameter LR_NUM = 30;
parameter XZR_NUM= 32;
parameter NZCV_NUM = 33;
parameter REG_SIZE = 64;


module Register_File();
    static logic rf_valid [NUM_REGS-1:0];
    static logic [REG_SIZE-1:0] rf_value [NUM_REGS-1:0];
    static logic [$clog2(ROB_SIZE)-1:0] rf_robPt [NUM_REGS-1:0];
    // static logic nzcv_valid; 
    // static logic [3:0] nzcv_value;
    // static logic [ROB_SIZE-1:0] nzcv_robPt;


    initial begin
        $dumpfile("out/ooo_cpu.vcd"); 
        $dumpvars(0, Register_File);
        for (int i = 0; i < NUM_REGS; i++) begin
            $dumpvars(0, rf_valid[i], rf_value[i], rf_robPt[i]);
        end
    end

    function logic is_valid(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
        if (reg_idx == XZR_NUM) return 1'b1;
        else return rf_valid[reg_idx];
    endfunction

    function void invalidate(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
        if (reg_idx == XZR_NUM) return;
        rf_valid[reg_idx] = 0;
    endfunction

    function logic [REG_SIZE - 1:0] get_regval(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
        if (reg_idx == XZR_NUM) return {64{1'b0}};
        return rf_value[reg_idx];
    endfunction

    function logic [$clog2(ROB_SIZE) - 1:0] get_rob_ptr(logic [$clog2(NUM_REGS) - 1:0] reg_idx);
        return rf_robPt[reg_idx];
    endfunction

    function void set_rob_ptr(logic [$clog2(NUM_REGS) - 1:0] reg_idx, logic [$clog2(ROB_SIZE) - 1:0] rob_idx);
        rf_robPt[reg_idx] = rob_idx;
    endfunction

    function void set_value(logic [$clog2(NUM_REGS) - 1:0] reg_idx, logic [REG_SIZE - 1:0] reg_val, logic [$clog2(ROB_SIZE)-1:0] rob_idx);
        if (reg_idx == XZR_NUM) return;
        rf_value[reg_idx] = reg_val;
        // From the text book page 216:
        //         /* free up dest register if no one else writing it */
        // if (RegisterStat[d].Reorder==h) {RegisterStat[d].Busy no;};
        if (rf_robPt[reg_idx]==rob_idx)
        rf_valid[reg_idx] = 1'b1;
        else
            $display("WAW hazard. rob idx %d writing to reg %d, which is the dest of %d", rob_idx, reg_idx, rf.get_rob_ptr(reg_idx));
    endfunction

    function void set_inital_valid();
        for (int i = 0; i < NUM_REGS; i++) begin
            rf_valid[i] = 1'b1;
            rf_value[i] = {64{1'b0}};
            rf_value[SP_NUM] = 4096*3;  
        end
    endfunction

    function void set_all_valid();
        for (int i = 0; i < NUM_REGS; i++) begin
            rf_valid[i] = 1'b1;
        end
    endfunction

endmodule

`endif
