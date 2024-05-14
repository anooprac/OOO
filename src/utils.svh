`ifndef UTILS_SVH
`define UTILS_SVH

function automatic integer highestSetBit(logic [6:0] in);
  for(integer i = 6; i >= 0; i=i-1) begin
    if(in[i]) begin
      return i;
    end
  end
endfunction

`endif



