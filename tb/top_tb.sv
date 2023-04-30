`timescale 1ns/10ps
`define CYCLE 8.0 // Cycle time
`ifdef SV
`include "../PE/PE.sv"
`endif
`ifdef V
`include "../PE/PE.v"
`endif
//`include "../define.svh"

`include "../PE/IfmapSpad.v"
`include "../PE/WeightSpad.v"
`include "../PE/Multiplier.v"
`include "../PE/Mux.v"
`include "../PE/Mux_adder.v"
`include "../PE/PE_controller.v"
`include "../PE/Psum_Spad.v"

module top_tb;

    logic clk;
    logic rst;
    logic [7:0] ifmap_noc;
    logic [7:0] ifmap_noc_o;
    logic ifmap_enable;
    logic ifmap_enable_o;
    logic [7:0] weight_noc;
    logic [7:0] weight_noc_o;
    logic weight_enable;
    logic weight_enable_o;
    logic [23:0] ipsum_noc;
    logic [23:0] ipsum_noc_o;
    logic ipsum_enable;
    logic ipsum_enable_o;
    logic [3:0] iw_size;
    logic [3:0] c;
    logic [3:0] f;
    logic [3:0] n;
    logic [3:0] o;

    logic opsum_ready;
    logic opsum_ready_o;
    logic weight_ready;
    logic ifmap_ready;
    logic ipsum_ready;
    logic opsum_enable;
    logic [23:0] opsum_noc;
    logic [63:0]total_cycle;

    always #(`CYCLE/2) clk = ~clk;

    always_ff@(posedge clk, posedge rst) begin
        if(rst) begin
            total_cycle <= 64'd0;
        end
        else begin
            total_cycle <= total_cycle+64'd1;
        end
    end
    
    logic signed [7:0] weight[18] = {8'd1, -8'd2, 8'd3, 
                        -8'd1, 8'd4, 8'd3, 
                        8'd2, -8'd3, -8'd4, 
                        
                        8'd2, -8'd2, 8'd1, 
                        8'd1, 8'd3, 8'd2, 
                        -8'd4, 8'd7, 8'd1};

    logic signed [7:0] ifmap[24] = {8'd1, -8'd2, 8'd3, 
                        8'd2, -8'd1, -8'd1, 
                        8'd1, 8'd1, -8'd1,
                        8'd2, 8'd2, 8'd4,
                        
                        8'd4, 8'd5, 8'd6, 
                        8'd2, -8'd4, -8'd6, 
                        8'd5, 8'd3, 8'd1,
                        -8'd6, 8'd2, 8'd3};

    logic signed [23:0] ipsum[8] = {-24'd6, -24'd5, 24'd11, 
                        24'd1, 24'd7, 24'd10, 
                        24'd20, -24'd22};

    logic signed [23:0] opsum[8] = {24'd2, -24'd22, 24'd19, 
                        24'd18, -24'd20, -24'd18, 
                        24'd4, 24'd41};


    logic signed [7:0] weight_print[18] = {8'd1, -8'd1, 8'd2, 
                        -8'd2, 8'd4, -8'd3, 
                        8'd3, 8'd3, -8'd4, 
                        
                        8'd2, 8'd1, -8'd4, 
                        -8'd2, 8'd3, 8'd7, 
                        8'd1, 8'd2, 8'd1};

    logic signed [7:0] ifmap_print[24] = {8'd1, 8'd2, 8'd1, 8'd2, 
                        -8'd2, -8'd1, 8'd1, 8'd2, 
                        8'd3, -8'd1, -8'd1, 8'd4,
                        
                        8'd4, 8'd2, 8'd5, -8'd6, 
                        8'd5, -8'd4, 8'd3, 8'd2, 
                        8'd6, -8'd6, 8'd1, 8'd3};

    int opsum_pe [8];
    always_ff@(posedge clk, posedge rst) begin
        if(rst) begin
            ifmap_enable_o <= 1'd0;
            weight_enable_o <= 1'd0;
            weight_noc_o <= 8'd0;
            ifmap_noc_o <= 8'd0;
            ipsum_enable_o <= 1'd0;
            ipsum_noc_o <= 24'd0;
            opsum_ready_o <= 1'd0;
        end
        else begin
            ifmap_enable_o <= ifmap_enable;
            weight_enable_o <= weight_enable;
            weight_noc_o <= weight_noc;
            ifmap_noc_o <= ifmap_noc;
            ipsum_enable_o <= ipsum_enable;
            ipsum_noc_o <= ipsum_noc;
            opsum_ready_o <= opsum_ready;
        end
    end

    PE pe(
        .clk(clk),
        .rst(rst),
        .ifmap_noc(ifmap_noc_o),
        .ifmap_enable(ifmap_enable_o),
        .weight_noc(weight_noc_o),
        .weight_enable(weight_enable_o),
        .ipsum_noc(ipsum_noc_o),
        .ipsum_enable(ipsum_enable_o), 
        .iw_size(iw_size),
        .c(c),
        .f(f),
        .n(n),
        .o(o),
        .opsum_ready(opsum_ready_o), 
        .ifmap_ready(ifmap_ready),
        .weight_ready(weight_ready),
        .ipsum_ready(ipsum_ready),
        .opsum_enable(opsum_enable),
        .opsum_noc(opsum_noc)
    );
    
    int i = 0;
    int w = 0;
    int k = 0;
    int m = 0;

    int opsum_count = 0;
    int err = 0;
    int cycle_count = 0;

    initial begin
    rst = 1;
    #(`CYCLE); rst = 0;
    end
    
    initial begin
        clk=1; 
        iw_size=2; c=2; f=1; n=1; o=1; 
        ifmap_noc=0; ifmap_enable=0; weight_noc=0; weight_enable=0; ipsum_noc=0; ipsum_enable=0; opsum_ready=0;
    end
    
    //ifmap
    always begin
        if(rst) begin
            wait(rst==0);
        end
        else begin
            if(i%4==3) begin
                ifmap_noc=0; ifmap_enable=0;
                #(`CYCLE*((i%3)+1));
            end
            ifmap_noc=ifmap[i]; ifmap_enable=1;
            if(!ifmap_ready) begin
                wait(ifmap_ready);
                #(`CYCLE); 
            end
            else begin
                #(`CYCLE); 
            end
            ifmap_noc=0; ifmap_enable=0;
            #(`CYCLE);  
            i = i + 1;
        end  
    end

    //weight
    always begin
        if(rst) begin
            wait(rst==0);
        end
        else begin
            if(w%4==2) begin
                weight_noc=0; weight_enable=0;
                #(`CYCLE*((w%3)+1));
            end
            weight_noc=weight[w]; weight_enable=1;
            if(!weight_ready) begin
                wait(weight_ready);
                #(`CYCLE); 
            end
            else begin
                #(`CYCLE); 
            end
            if(w%5!=4) begin
                weight_noc=0; weight_enable=0;
                #(`CYCLE);
            end
            else begin
                weight_noc=0; weight_enable=0;
                #(`CYCLE);
            end
            w = w + 1;
        end   
    end


    //ipsum
    always begin
        if(rst) begin
            wait(rst==0);
            #(`CYCLE); 
        end
        else begin
            if(k%5==3) begin
                ipsum_noc=0; ipsum_enable=0;
                #(`CYCLE*((k%3)+1));
            end
            ipsum_noc=ipsum[k]; ipsum_enable=1;
            if(!ipsum_ready) begin
                wait(ipsum_ready);
                #(`CYCLE); 
            end
            else begin
                #(`CYCLE); 
            end
            if(k%6!=4) begin
                ipsum_noc=0; ipsum_enable=0;
                #(`CYCLE*((k%7)+1));  
            end 
            else begin
                ipsum_noc=0; ipsum_enable=0;
                #(`CYCLE); 
            end
            k = k + 1; 
        end
    end
    
    //opsum
    always begin
        if(rst) begin
            wait(rst==0);
        end
        else begin
            if(m%4==2) begin
                opsum_ready=0;
                #(`CYCLE*((m%3)+1));
                opsum_ready=1;
                #(`CYCLE);
            end
            else begin
                opsum_ready=1;
                #(`CYCLE);
            end
            if(!opsum_enable) begin
                wait(opsum_enable);
                #(`CYCLE); 
            end
            opsum_pe[m] = $signed(opsum_noc);
            opsum_count = opsum_count + 1; 
            if(m%5!=1) begin
                opsum_ready=0;
                #(`CYCLE); 
            end
            m = m + 1;
        end   
    end
    
    initial begin
        wait(opsum_count == 8);

        $display("ifmap:  ");
        for(int x=0;x<24;x=x+4) begin
            if(x==0) begin
                $display("ifmap 0");
            end
            if(x==12) begin
                $display("ifmap 1");
            end
            $display("channel%2d: %4d %4d %4d %d", (x/4)%3, ifmap_print[x], ifmap_print[x+1], ifmap_print[x+2], ifmap_print[x+3]);
        end
        $display("\nweight:  ");
        for(int x=0;x<18;x=x+3) begin
            if(x==0) begin
                $display("filter 0");
            end
            if(x==9) begin
                $display("filter 1");
            end
            $display("channel%2d: %4d %4d %4d", (x/3)%3, weight_print[x], weight_print[x+1], weight_print[x+2]);
        end
        $display("\nipsum:  ");
        for(int x=0;x<8;x=x+3) begin
            if(x == 6) begin
                $display("%4d %4d", ipsum[x], ipsum[x+1]);
            end
            else begin
                $display("%4d %4d %4d", ipsum[x], ipsum[x+1], ipsum[x+2]);
            end
        end
        $display("\n  ");
        for(int x=0;x<8;x++) begin
            if(opsum_pe[x] !== opsum[x]) begin
                $display("result=%4d, answer=%4d, Wrong!", opsum_pe[x], opsum[x]);
                err = err + 1;
            end
            else begin
                $display("result=%4d, answer=%4d, Correct!", opsum_pe[x], opsum[x]);
            end
        end
        if (err === 0)
        begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  Congratulations !!    **      / O.O  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
        end
        else
        begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  OOPS!!                **      / X,X  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("         Totally has %d errors                     ", err); 
        $display("\n");
        end
        $display("total cycle = %d\n", total_cycle);
        $display("\n");
        $finish;
    end

    initial begin
        #(`CYCLE*600);
        $display("ifmap:  ");
        for(int x=0;x<24;x=x+4) begin
            if(x==0) begin
                $display("ifmap 0");
            end
            if(x==12) begin
                $display("ifmap 1");
            end
            $display("channel%2d: %4d %4d %4d %d", (x/4)%3, ifmap_print[x], ifmap_print[x+1], ifmap_print[x+2], ifmap_print[x+3]);
        end
        $display("\nweight:  ");
        for(int x=0;x<18;x=x+3) begin
            if(x==0) begin
                $display("filter 0");
            end
            if(x==9) begin
                $display("filter 1");
            end
            $display("channel%2d: %4d %4d %4d", (x/3)%3, weight_print[x], weight_print[x+1], weight_print[x+2]);
        end
        $display("\nipsum:  ");
        for(int x=0;x<8;x=x+3) begin
            if(x == 6) begin
                $display("%4d %4d", ipsum[x], ipsum[x+1]);
            end
            else begin
                $display("%4d %4d %4d", ipsum[x], ipsum[x+1], ipsum[x+2]);
            end
        end
        $display("\n  ");
        for(int x=0;x<8;x++) begin
            if(opsum_pe[x] !== opsum[x]) begin
                $display("result=%4d, answer=%4d, Wrong!", opsum_pe[x], opsum[x]);
                err = err + 1;
            end
            else begin
                $display("result=%4d, answer=%4d, Correct!", opsum_pe[x], opsum[x]);
            end
        end
        if (err === 0)
        begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  Congratulations !!    **      / O.O  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("\n");
        end
        else
        begin
        $display("\n");
        $display("\n");
        $display("        ****************************               ");
        $display("        **                        **       |\__||  ");
        $display("        **  OOPS!!                **      / X,X  | ");
        $display("        **                        **    /_____   | ");
        $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display("        **                        **  |^ ^ ^ ^ |w| ");
        $display("        ****************************   \\m___m__|_|");
        $display("         Totally has %d errors                     ", err); 
        $display("\n");
        end
        $display("total cycle is more than %d\n", total_cycle);
        $display("\n");
        $finish;
    end
    
    // initial begin
    //     `ifdef FSDB
    //     // $fsdbDumpfile("top.fsdb");
    //     // $fsdbDumpvars;
    //     $fsdbDumpfile("top.fsdb");
    //     $fsdbDumpvars("+struct", "+mda", pe);
    //     `endif
    // end
    initial begin
        $fsdbDumpfile("top.fsdb");
        $fsdbDumpvars();
        $fsdbDumpMDA;
    end
endmodule