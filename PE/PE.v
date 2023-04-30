module PE(
    input clk,
    input rst,
    input [7:0] ifmap_noc,
    input ifmap_enable,
    input [7:0] weight_noc,
    input weight_enable,
    input [23:0] ipsum_noc,
    input ipsum_enable, 
    input [3:0] iw_size,
    input [3:0] c,
    input [3:0] f,
    input [3:0] n,
    input [3:0] o,
    input opsum_ready,
    output ifmap_ready,
    output weight_ready,
    output ipsum_ready,
    output opsum_enable,
    output [23:0] opsum_noc
);

/*
Precautions : 
   1. Each PE just process one row.
   2. If not using pipeline method, need 9 cycle to accumlate 1 row.
      And it can added with other PE at cycle 10.
   3. Tensbench include 2 ifmaps and 2 filter both 3 channel.
   4. Caculate filter first then ifmaps.
*/

// Internal controller for ifmapSpad
wire ifmap_wen, ifmap_ren;
wire [5:0] ifmap_read_addr, ifmap_write_addr;

// Internal controller for weightSpad
wire weight_wen, weight_ren;
wire [5:0] weight_read_addr, weight_write_addr;

// Internal controller for Psum_Spad
wire ipsum_wen, ipsum_ren;
wire [4:0] ipsum_read_addr, ipsum_write_addr;

// Mux controller
wire Mux1_sel, Mux2_sel;

PE_controller PE_controller1(clk, rst, ifmap_enable, weight_enable, ipsum_enable, opsum_ready, iw_size, c, f, n, o,
                             ifmap_ready, weight_ready, ipsum_ready, opsum_enable,
                             ifmap_read_addr, ifmap_write_addr, ifmap_wen, ifmap_ren,
                             weight_read_addr, weight_write_addr, weight_wen, weight_ren,
                             ipsum_read_addr, ipsum_write_addr,, ipsum_wen, ipsum_ren,
                             Mux1_sel, Mux2_sel
                             );

wire [7:0] ifmap_read_data;
IfmapSpad IfmapSpad1(clk, rst, ifmap_wen, ifmap_ren, ifmap_noc, ifmap_read_addr, ifmap_write_addr, ifmap_read_data);

wire [7:0] weight_read_data;
WeightSpad WeightSpad1(clk, rst, weight_wen, weight_ren, weight_noc, weight_read_addr, weight_write_addr, weight_read_data);

wire [23:0] Mulout;
Multiplier Multiplier1(ifmap_read_data, weight_read_data, Mulout);

wire [23:0] mux1_out;
Mux Mux1(Mulout, ipsum_noc, Mux1_sel, mux1_out);

wire [23:0] mux2_out, add_result;
wire [23:0] psumspad_out;
Mux_Adder Mux_Adder0(mux1_out, mux2_out, opsum_noc);
Psum_Spad Psum_Spad1(clk, rst, ipsum_wen, ipsum_ren, opsum_noc, ipsum_read_addr, ipsum_write_addr, psumspad_out);
Mux Mux2(psumspad_out, 24'd0, Mux2_sel, mux2_out);



endmodule