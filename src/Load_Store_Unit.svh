`ifndef LOAD_STORE_UNIT_SVH
`define LOAD_STORE_UNIT_SVH


`include "Register_File.svh"
`include "Reorder_Buffer.svh"
`include "Reservation_Stations.svh"
`include "Memory.svh"


typedef struct packed {
    logic [REG_SIZE-1:0] val_a;
    logic [REG_SIZE-1:0] val_b;
} ls_values_t;

module Load_Store_Unit();
function ls_values_t get_value(ls_dispatch_outputs_t ls_execute_record);
    ls_values_t ls_values;
    // $display("Load Store Unit: Getting values");
    // $display("Load Store Unit: ls_execute_record.ls_res_M_sigs[0]: %b", ls_execute_record.ls_res_M_sigs[0]);
    // $display("Load Store Unit: ls_execute_record.ls_res_M_sigs[1]: %b", ls_execute_record.ls_res_M_sigs[1]);
    // $display("Load Store Unit: src_a_value: %b", ls_execute_record.ls_res_src_a_value);
    // $display("Load Store Unit: src_b_value: %b", ls_execute_record.ls_res_src_b_value);
    // $display("Load Store Unit: addr_value: %b", ls_execute_record.ls_res_addr_value);
    //load
    if (ls_execute_record.ls_res_M_sigs[1]) begin  
        ls_values.val_a = load(ls_execute_record.ls_res_addr_value);
        // $display("Calling load with addr: %h, result: %h", ls_execute_record.ls_res_addr_value, ls_values.val_a);
        if (ls_execute_record.ls_res_M_sigs[2]) begin
            ls_values.val_b = load(ls_execute_record.ls_res_addr_value + 8);
        end
    end
    //store
    else if (ls_execute_record.ls_res_M_sigs[0]) begin
        ls_values.val_a = ls_execute_record.ls_res_src_a_value;
        if (ls_execute_record.ls_res_M_sigs[2]) begin
            ls_values.val_b = ls_execute_record.ls_res_src_b_value;
        end
    end
    
    return ls_values;
endfunction


function automatic logic [REG_SIZE-1:0] load(logic [63:0] addr);
    // check rob for addr
    // if found, return value from rob
    // otherwise, return value from memory 
    logic [$clog2(ROB_SIZE):0] rob_result = rob.get_newest_rob_idx_of_addr(addr);
    logic [$clog2(ROB_SIZE)-1:0] rob_idx = rob_result[$clog2(ROB_SIZE)-1:0];
    // $display("doing a load on addr %h", addr); // TODO removing this line breaks everything
    // $display("Loading from addr %h", addr);
    if (rob_result[$clog2(ROB_SIZE)]) begin
        $display("FOUND STORE DEPENDENCY: %h on index %d", rob.instruction[rob_idx], rob_idx);
    end
    if (rob_result[$clog2(ROB_SIZE)]) begin
       return rob.get_dest_val(rob_idx);
    end else begin
        // read from memory in little endian
       return {
        mem.getMemory(addr+7),
        mem.getMemory(addr+6),
        mem.getMemory(addr+5),
        mem.getMemory(addr+4),    
        mem.getMemory(addr+3), 
        mem.getMemory(addr+2),
        mem.getMemory(addr+1),
        mem.getMemory(addr)
        };   
    end
endfunction

endmodule
`endif // LOAD_STORE_UNIT_SVH
