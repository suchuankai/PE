module PE_controller(clk, rst, ifmap_enable, weight_enable, ipsum_enable, opsum_ready, iw_size, c, f, n, o,
					 ifmap_ready, weight_ready, ipsum_ready, opsum_enable,
					 ifmap_read_addr, ifmap_write_addr, ifmap_wen, ifmap_ren,
					 weight_read_addr, weight_write_addr, weight_wen, weight_ren,
					 ipsum_read_addr, ipsum_write_addr,, ipsum_wen, ipsum_ren,
					 Mux1_sel, Mux2_sel
					 );


`define CONVTIMES (c+1)*(iw_size+1)-1       // 8   channel * kernelSize
`define CHANNEL_DEPTH (c+1)                 // 3
`define FEATURE_DONE (c+1)*(iw_size+1+o)    // 12  channel * (kernelCol + ofpixelsize) 
`define FILTERSIZE (iw_size+1)*(iw_size+1)  // 9   kernelCol * kernelRow

// from tb input 
input clk, rst, ifmap_enable, weight_enable, ipsum_enable, opsum_ready;
input [3:0] iw_size, c, f, n, o;

// Output to tb
output reg ifmap_ready, weight_ready, ipsum_ready, opsum_enable;

// Internal controller for ifmapSpad
output ifmap_wen;
output reg ifmap_ren;
output reg [5:0] ifmap_read_addr, ifmap_write_addr;

// Internal controller for weightSpad
output weight_wen;
output reg weight_ren;
output reg [5:0] weight_read_addr, weight_write_addr;

// Internal controller for ipsum_Spad
output ipsum_wen;
output reg ipsum_ren;
output reg [4:0] ipsum_read_addr, ipsum_write_addr;

// Mux controller
output reg Mux1_sel, Mux2_sel;


reg [1:0] crState, ntState;
reg [8:0] macCounter;


parameter WAIT    = 2'd0,
		  MAC     = 2'd1,
		  ADDPSUM = 2'd2;

wire ifmapReady = (ifmap_write_addr>ifmap_read_addr) ;
wire weightReady = (weight_write_addr>weight_read_addr) ;

assign ifmap_ren  = ifmapReady;
assign weight_ren = weightReady;
assign ipsum_wen = (ifmapReady && weightReady);

reg [3:0] channel_count;
reg [3:0] filter_count;
reg [3:0] ifmap_count;
reg [3:0] rowOfmap_count;
reg [3:0] iw_size_count;


always@(posedge clk or posedge rst) begin
	if(rst) begin
		 crState <= WAIT;
		 macCounter <= 4'd0;
		 ifmap_read_addr <= 6'd0;
		 weight_read_addr <= 6'd0;

		 ipsum_ren <= 1;
		 ipsum_read_addr <= 0;
		 ipsum_write_addr <= 0;
		 ipsum_ready <= 0;

		 channel_count <= 4'd0;
		 filter_count <= 4'd0;
		 ifmap_count <= 4'd0;
		 rowOfmap_count <= 4'd1;
		 iw_size_count <= 4'd0;

	end 
	else begin
		 crState <= ntState;
		 case(crState)
		 	WAIT:begin
		 		Mux1_sel <= 1;
		 		Mux2_sel <= 0;
		 		opsum_enable <= 0;
		 	end
		 	MAC:begin
		 		if(macCounter == `CONVTIMES && (ifmapReady && weightReady))begin
	 				Mux1_sel <= 0;   // ADD ipsum_noc
	 				ipsum_ready <= 1;
	 				opsum_enable <= 1;
	 				// macCounter <= macCounter + 1;
	 			end
	 			else begin
	 				Mux1_sel <= 1;
	 			end
	 			if( ifmapReady && weightReady )begin
			 		ifmap_read_addr <= ifmap_read_addr + 1;
			 		weight_read_addr <= weight_read_addr + 1;
		 			macCounter <= macCounter + 1;
	 			end
	 			Mux2_sel <= 1;
	 		end
	 		ADDPSUM:begin
	 			opsum_enable <= 0;  // Stop output
	 			ipsum_ready  <= 0;  // Stop input ipsum_noc
	 			ipsum_read_addr  <= ipsum_read_addr + 1;
				ipsum_write_addr <= ipsum_write_addr + 1;
				Mux1_sel <= 1;
				macCounter <= 0;	

	 			// Control ifmap_read_addr & weight_read_addr

	 			// rowOfmap_count==o means change filter
	 			// filter_count==f means change ifmap
	 			// ifmap_count==n means fininsh in this design
	 			if(rowOfmap_count==o)begin  
	 				rowOfmap_count <= 0;
	 				filter_count <= (filter_count==f)? 0 : filter_count + 1;
	 				if(filter_count==f)
	 					ifmap_count <= (ifmap_count==n)? 0 : ifmap_count + 1;
	 				ifmap_read_addr <= (ifmap_count * `FEATURE_DONE) + `CHANNEL_DEPTH; // 0 -> 12
	 				weight_read_addr <= (filter_count * `FILTERSIZE);
	 			end
	 			else begin
	 				rowOfmap_count <= rowOfmap_count + 1;	 				
	 				ifmap_read_addr <= (ifmap_count * `FEATURE_DONE) ; // 3 -> 15
	 				weight_read_addr <= (filter_count * `FILTERSIZE);
	 			end
	 		end
		 endcase
	end
end



// Next state logic
always@(*)begin
	case(crState)
		WAIT:begin
			ntState = (ifmap_write_addr>0 && weight_write_addr>0)? MAC : WAIT;
	 	end
	 	MAC:begin
	 		ntState = (macCounter == `CONVTIMES && (ifmapReady && weightReady))? ADDPSUM : MAC;
	 	end
	 	ADDPSUM:begin
	 		ntState = MAC;
	 	end
	endcase 
end



// Keep reading ifmap and weight

assign ifmap_wen = ifmap_enable;
assign weight_wen = weight_enable;

always@(posedge clk or posedge rst) begin
	if(rst)begin
		ifmap_ready <= 1;
		weight_ready <= 1;;
		ifmap_write_addr <= 6'd0;
		weight_write_addr <= 6'd0;
	end
	else begin

		ifmap_ready <= (ifmap_write_addr>24)? 0 : 1;   // Input feature map only consist of 24 records (0~23). 
		weight_ready <= (weight_write_addr>18)? 0 : 1; // Input weight only consist of 18 records (0~17). 

		if(ifmap_wen && ifmap_ready)begin
			ifmap_write_addr <= ifmap_write_addr + 1;
		end
		if(weight_wen && weight_ready)begin
			weight_write_addr <= weight_write_addr + 1;
		end	
	end	
end

endmodule
