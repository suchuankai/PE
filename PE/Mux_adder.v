module Mux_Adder(data1, data2, out);
input [23:0] data1, data2;
output [23:0] out;

assign out = data1 + data2;

endmodule