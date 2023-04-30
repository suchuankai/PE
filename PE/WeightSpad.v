module WeightSpad(clk, rst, w_en, r_en, write_data, read_address, write_address, read_data);

input clk, rst, w_en, r_en;
input  [7:0] write_data;
input  [5:0] read_address, write_address;
output [7:0] read_data;

reg [7:0] rf [63:0];

integer i;

assign read_data = (r_en)? rf[read_address] : 8'd0;

always@(posedge clk or posedge rst)begin
	if(rst)begin
		for(i=0; i<=63; i=i+1)begin
			rf[i] <= 8'd0;   // Reset register file
		end
	end
	else begin
		if(w_en)begin
			rf[write_address] <= write_data;
		end
	end
end


endmodule