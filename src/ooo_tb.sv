 `timescale 1ns / 1ps
 `default_nettype none


module ooo_tb ();
  logic start_in;
  logic rst_in_N;               // asynchronous active-low reset
  logic clk_in = 1'b0;                 // clock

  logic [63:0] reg_file_out [31:0]; // registers R0-R31
  logic [3:0] nzcv_out;             // nzcv flags
  logic [63:0] pc_out;              // program counter
  logic done_out;
 
  reg init;
  reg [DATA_WIDTH-1:0] mem_in [ADDR_SIZE-1:0];
  reg [31:0] text_start_addr_upper;
  reg [31:0] data_start_addr_upper;
  reg [31:0] text_size_upper;
  reg [31:0] data_size_upper;
  reg [31:0] entry_upper;
  reg [31:0] text_start_addr_lower;
  reg [31:0] data_start_addr_lower;
  reg [31:0] text_size_lower;
  reg [31:0] data_size_lower;
  reg [31:0] entry_lower;

  reg [63:0] text_start_addr;
  reg [63:0] data_start_addr;
  reg [63:0] text_size;
  reg [63:0] data_size;
  reg [63:0] entry;


  ooo_cpu dut(
  .start_in(start_in),  
  .rst_in_N(rst_in_N),
  .clk_in(clk_in),
  .mem_in(mem_in),
  .init(init),
  .text_start_addr_in(text_start_addr),
  .data_start_addr_in(data_start_addr),
  .text_size_in(text_size),
  .data_size_in(data_size),
  .entry_in(entry)
  );

  always #5 clk_in <= ~clk_in;

  initial begin 
    // $dumpfile("ooo_cpu.vcd");
    // $dumpvars(0, ooo_tb);
    $elf("testcases/bubblesort",
        text_start_addr_upper,
        text_start_addr_lower,
        data_start_addr_upper,
        data_start_addr_lower,
        text_size_upper,
        text_size_lower,
        data_size_upper,
        data_size_lower,
        entry_upper,
        entry_lower);

        text_start_addr = {text_start_addr_upper,text_start_addr_lower};
        data_start_addr = {data_start_addr_upper, data_start_addr_lower};
        text_size = {text_size_upper, text_size_lower};
        data_size = {data_size_upper, data_size_lower};
        entry = {entry_upper, entry_lower};

        //  $display("text start addr: %h", text_start_addr);
        //  $display("data start addr: %h", data_start_addr);
        //  $display("text size: %h", text_size);
        //  $display("data size: %h", data_size);
        //  $display("entry: %h", entry);


        $readmemb("elf/elf_sections.txt", mem_in, 0, ADDR_SIZE-1);

        // // print the buffer
        // for(int i = 0; i < ADDR_SIZE; i++) begin
        //   $display("BUFFER: %b", mem_in[i]);
        // end

        init = 1'b1;
    //  #3000000  // required for bubblesort_long
    #10000; 
    $finish;
  end

  always @(posedge clk_in) begin
    init <= 1'b0;

    // if(done_out) begin
    //   $display("PC REGISTER AFTER COMPLETION: %b", pc_out);
    //   for(int j = 0; j < 32; j++)begin
    //     $display("REG FILE: %b", reg_file_out[j]);
    //   end
      
    // end
  end

  initial begin
    $dumpfile("out/ooo_cpu.vcd");
    $dumpvars(0, ooo_tb);
  end

  

  
endmodule: ooo_tb
`default_nettype wire

