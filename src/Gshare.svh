`ifndef GSHARE_SVH
`define GSHARE_SVH

`include "Memory.svh"

parameter RECENT_BUFF_SIZE=10;
parameter PREDICT_BUFF_SIZE=2 ** RECENT_BUFF_SIZE;

module Gshare();

    static logic [RECENT_BUFF_SIZE-1:0] recent_buff;
    static logic [1:0] predict_buff [PREDICT_BUFF_SIZE-1:0];

    initial begin
        $dumpfile("out/ooo_cpu.vcd");
        $dumpvars(0,Gshare);
    end

    function void init_buffers();
        recent_buff = {RECENT_BUFF_SIZE {1'b0}};
        for (int i =0; i < PREDICT_BUFF_SIZE; i++)
            predict_buff[i] = 2'b00;
    endfunction

    function logic [RECENT_BUFF_SIZE-1:0] get_hash(logic [ADDR_SIZE-1:0] addr);
        return recent_buff ^ addr[RECENT_BUFF_SIZE-1:0];
    endfunction

    function logic get_prediction(logic [ADDR_WIDTH-1:0] addr);
        // hash using xor of addr and recent buff
        logic [1:0] predictor;
        predictor = predict_buff[get_hash(addr)];

        // Predict taken states are 10 and 11
        if (predictor > 1)
            return 1'b1;
        else
            return 1'b0;

    endfunction


    // get_prediction is redundantly called bc creating a local variable of type logic of size 1
    // is giving me errors
    function automatic void update_prediction(logic [ADDR_WIDTH-1:0] addr, logic mistaken);
        // find predictor
        logic [1:0] predictor;
        logic prediction;
        logic [RECENT_BUFF_SIZE-1:0] idx;
        idx = get_hash(addr);
        predictor = predict_buff[idx];
        prediction = get_prediction(addr);
        $display("previous prediction: %b", predictor);
        // compute predictor state
        $display("Prediction: %b", prediction);
        if ((prediction != mistaken) && predictor < 3) begin
            $display("taken branch");
            predictor = predictor + 1;
        end else if ((prediction == mistaken) && predictor > 0) begin
            $display("not taken branch");
            predictor = predictor - 1;
        end else
            $display("no need to update");
        
        // shift recent predictions buffer
        //recent_buff = {recent_buff[RECENT_BUFF_SIZE-2:0], get_prediction(addr)};

        // update
        predict_buff[idx] = predictor;    
        $display("current prediction: %b", predictor);    
    endfunction

endmodule



`endif