module Psum_Spad(clk, rst, w_en, r_en, write_data, read_address, write_address, read_data);

input clk, rst, w_en, r_en;
input  [23:0] write_data;
input  [4:0]  read_address, write_address;
output [23:0] read_data;

reg [23:0] rf [31:0];

integer i;

assign read_data = (r_en)? rf[read_address] : 24'd0;

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0; i<=31; i=i+1)begin
			rf[i] <= 24'd0;  // Reset register file
		end
	end
	else begin
		if(w_en)begin
			rf[write_address] <= write_data;
		end
	end
end


endmodule