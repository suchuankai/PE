module Multiplier(ifmap, filter, out);
input [7:0] ifmap, filter;
output [23:0] out;

assign out = $signed(ifmap) * $signed(filter);

endmodule


