module Mux(data1, data2, Mux_sel, data_out);

input  [23:0] data1;
input  [23:0] data2;
input  Mux_sel;
output [23:0] data_out;

assign data_out = (Mux_sel)? data1 : data2;

endmodule