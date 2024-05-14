`ifndef MEMORY_SVH
`define MEMORY_SVH

parameter ADDR_WIDTH = 64;
parameter ADDR_SIZE = 4096*3;
parameter DATA_WIDTH = 8;

module Memory();

    static logic [ADDR_WIDTH-1:0] text_start_addr;
    static logic [ADDR_WIDTH-1:0] text_size;
    static logic [ADDR_WIDTH-1:0] data_start_addr;
    static logic [ADDR_WIDTH-1:0] data_size;
    static logic [ADDR_WIDTH-1:0] entry;

    static reg [DATA_WIDTH-1:0] mem [ADDR_SIZE]; 


    integer idx;
    initial begin
        $dumpfile("out/ooo_cpu.vcd");
        $dumpvars(0, Memory);
        for (idx = 0; idx < ADDR_SIZE; idx = idx + 1) $dumpvars(0, mem[idx]);
    end
 
    function [DATA_WIDTH-1:0] getMemory([ADDR_WIDTH-1:0] addr);
        return mem[translation(addr)];
    endfunction 

    function void setMemory([ADDR_WIDTH-1:0] addr, [DATA_WIDTH-1:0] data);
        mem[translation(addr)] = data;
    endfunction

    function [ADDR_WIDTH-1:0] translation([ADDR_WIDTH-1:0] addr);
        if (addr >= text_start_addr && addr < text_start_addr + text_size) begin
            return addr - text_start_addr;
        end else if (addr >= data_start_addr && addr < data_start_addr + data_size) begin
            return addr - data_start_addr;
        end
        return addr;
    endfunction
    
endmodule

`endif
