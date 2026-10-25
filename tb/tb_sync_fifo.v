`default_nettype none  
`timescale 1ns/1ps

module tb_sync_fifo;

reg         clk;    
reg         rst_n;
reg  [9:0]  wr_data;
reg         rd_en;
reg         wr_en; 

wire [9:0]  rd_data;
wire        empty;
wire        full; 

localparam [9:0] A = 10'hAA,
                B = 10'hBB,
                C = 10'hCC,
                D = 10'hDD,
                E = 10'hEE,
                F = 10'hFF,
                G = 10'h11,
                H = 10'h22,
                I = 10'h33,
                Y = 10'h99,
                X = 10'bxx;

sync_fifo #(
    .DEPTH(4)
) u_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(wr_data),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .rd_data(rd_data),
    .empty(empty),
    .full(full)           
);

integer cycle;
integer err;

always @(posedge clk) begin
    if(!rst_n) cycle <= 0;
    else cycle <= cycle + 1;
end
task reset_fifo;
    begin
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
    end
endtask

task fifo_in(input write_enable, input read_enable, input [9:0] write_data);
    begin
        @(negedge clk);
        wr_data = write_data;
        wr_en = write_enable;
        rd_en = read_enable;
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 0;
    end
endtask

task check(input exp_full, input exp_empty, input [9:0] exp_data);
    begin
        if(full !== exp_full) begin
            err = err + 1;
            $display("[%0d] Full Error full=%d expect=%d",cycle, full, exp_full);
        end
        if(empty !== exp_empty) begin
            err = err + 1;
            $display("[%0d] Empty Error empty=%d expect=%d", cycle,empty, exp_empty);
        end  
        if(exp_data !== rd_data) begin
            err = err + 1;
            $display("[%0d] Data Error rd_data=%h expect=%h", cycle,rd_data, exp_data);
        end                
    end
endtask

initial begin
    
    err = 0;
    cycle = 0;
    wr_en = 0;
    rd_en = 0;
    wr_data = 0;
    reset_fifo;
    check(0,1,0);

    fifo_in(1,0,A);
    check(0,0,0);

    fifo_in(1,0,B);
    check(0,0,0); 

    fifo_in(0,1,X);
    check(0,0,A);

    fifo_in(1,1,C);
    check(0,0,B);

    fifo_in(1,0,D);
    check(0,0,B);

    fifo_in(1,0,E);
    check(0,0,B);

    fifo_in(1,0,F);
    check(1,0,B);

    fifo_in(1,0,G);
    check(1,0,B);

    fifo_in(1,1,Y);
    check(0,0,C);

    fifo_in(0,1,X);
    check(0,0,D);

    fifo_in(0,1,X);
    check(0,0,E);

    fifo_in(0,1,X);
    check(0,1,F);

    fifo_in(0,1,X);
    check(0,1,F);

    fifo_in(1,1,H);
    check(0,0,F);

    fifo_in(1,1,I);
    check(0,0,H);

    fifo_in(0,1,X);
    check(0,1,I);

    fifo_in(0,0,X);
    check(0,1,I);

    if(err !== 0) begin
        $display("FAIL : Error=%0d",err);
    end
    else begin
        $display("PASS : Error=%0d",err);
    end
    #100;
    $finish;
end


initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("sim/sync_fifo.vcd");
    $dumpvars(0, tb_sync_fifo);
end


endmodule

`default_nettype wire

