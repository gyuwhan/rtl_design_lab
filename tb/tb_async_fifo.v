`default_nettype none
`timescale 1ns/1ps

module tb_async_fifo #(
    parameter   DW = 10,
                RCYCLE = 10,        //100MHZ
                WCYCLE = 27.027,    //37MHZ
                DEPTH = 8
);
    localparam AW = $clog2(DEPTH);  
    localparam REAL_DEPTH = (1 << AW);
    localparam MAX_WR = 4096;
    localparam RD_PROB = 25,
                WR_PROB = 60;
    localparam TIMEOUT = 100,
                CYCLE = 1000;

    reg           w_clk;
    reg           w_rst_n;
    reg           wr_en;
    reg  [DW-1:0] wr_data;

    reg           r_clk;
    reg           r_rst_n;
    reg           rd_en;
    wire [DW-1:0] rd_data;

    wire          full;
    wire          empty;

    reg [DW-1:0] exp_mem [0:MAX_WR-1];
    reg [DW-1:0] tmp;

    integer wr_cnt, rd_cnt;

    reg read;

    integer err, k;
    integer r_seed, w_seed;
    integer cnt_full, cnt_empty, cnt_ignore_w, cnt_ignore_r;

function [AW:0] gray2bin (input [AW:0] gray);
    integer i;
    begin
        gray2bin[AW] = gray[AW];
        for(i = (AW-1);i >= 0; i = i - 1) begin
            gray2bin[i] = gray2bin[i + 1] ^ gray[i];
        end
    end
endfunction

function [AW:0] bin2gray (input [AW:0] bin);
    bin2gray = bin ^ (bin >> 1);
endfunction

task write(input [DW-1:0] data_wr);
    begin
       @(negedge w_clk);
       wr_en = 1;
       wr_data = data_wr;
       @(posedge w_clk);
       #1;
       wr_en = 0;
    end
endtask

task check(input exp_full, input exp_empty, input [AW:0] exp_wptr, input [AW:0] exp_rptr);
    begin
        if(exp_full !== full) begin
            err = err + 1;
            $display("[%0t] Error: full=%b exp=%b",$time, full, exp_full);
        end 
        if(exp_empty !== empty) begin
            err = err + 1;
            $display("[%0t] Error: empty=%b exp=%b",$time, empty, exp_empty);
        end
        if(exp_wptr !== u_async_fifo.wptr) begin
            err = err + 1;
            $display("[%0t] Error: wptr=%b exp=%b",$time, u_async_fifo.wptr, exp_wptr);
        end
        if(exp_rptr !== u_async_fifo.rptr) begin
            err = err + 1;
            $display("[%0t] Error: rptr=%b exp=%b",$time, u_async_fifo.rptr, exp_rptr);
        end
    end
endtask

async_fifo #(
    .DEPTH(DEPTH),
    .DW(DW)
) u_async_fifo(
    .w_clk(w_clk),
    .w_rst_n(w_rst_n),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .r_clk(r_clk),
    .r_rst_n(r_rst_n),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
);


initial begin
//  check(exp_full, exp_empty, exp_wptr, exp_rptr)
//  write(10'data_wr);

    //  1번
    err = 0;
    $display("[%0t] AW=%0d REAL_DEPTH=%0d", $time, AW, REAL_DEPTH);
    #10;
    wr_en = 0;          rd_en = 0;
    w_rst_n = 0;        r_rst_n = 0;
    r_seed = 1;         w_seed = 2;

    #1; check(0,1,0,0);
    @(posedge w_clk); #1;
    w_rst_n = 1;
    r_rst_n = 1;

    @(posedge w_clk);
    @(posedge r_clk);
    repeat (2) @(negedge r_clk);
    repeat (2) @(negedge w_clk); #1;

    //  2번

    @(negedge w_clk);
    wr_en = 1;
    wr_data = 10'ha;
    @(posedge w_clk);

    fork
        begin
            #1;
            $display("[%0t] mem[0]=%h",$time, u_async_fifo.mem[0]);
            check(0,1,1,0);
            wr_en = 0;
        end
        begin
            repeat (2) @(posedge r_clk); #1;
            check(0,1,1,0);

        end
    join

    @(posedge r_clk); #1;
    check(0,0,1,0);
    rd_en = 1;
    
    //  3번
    @(posedge r_clk); #1;
    rd_en = 0;
    $display("[%0t] rd_data=%h",$time, rd_data);
    check(0,1,1,1);

    @(posedge r_clk); #1;
    rd_en = 1;
    $display("[%0t] rd data=%h rd cnt=%0d wr cnt=%0d rptr=%b wptr=%b empty=%b",$time,rd_data, rd_cnt, wr_cnt, u_async_fifo.rptr, u_async_fifo.wptr, empty);
    repeat (2) @(posedge r_clk); #1;
    rd_en = 0;
    check(0,1,1,1);
    $display("[%0t] rd data=%h rd cnt=%0d wr cnt=%0d rptr=%b wptr=%b empty=%b",$time,rd_data, rd_cnt, wr_cnt, u_async_fifo.rptr, u_async_fifo.wptr, empty);

    //  4번
    write(10'hb);
    check(0,empty,2,1);
    write(10'hc);
    check(0,empty,3,1);
    write(10'hd);
    check(0,empty,4,1);
    write(10'he);
    check(0,empty,5,1);
    write(10'hf);
    check(0,empty,6,1);
    write(10'h1);
    check(0,empty,7,1);
    write(10'h2);
    check(0,empty,8,1);
    write(10'h3);
    check(1,empty,9,1);


    //  5번
    repeat (3) begin
        write(10'h4);
        $display("[%0t] wptr msb=%b rptr msb=%b wptr addr=%b rptr addr=%b full=%b",$time,u_async_fifo.wptr[AW],u_async_fifo.rptr[AW],u_async_fifo.wptr[AW-1:0],u_async_fifo.rptr[AW-1:0],full);
    end

    //  6번
    @(negedge r_clk);
    rd_en = 1;
    check(1,0,9,1);

    @(posedge r_clk);
    fork
        begin
            #1;
            rd_en = 0;
            check(full,0,9,2);
        end
        begin
            repeat (2) @(posedge w_clk); #1;
            check(1,0,9,2);
            @(posedge w_clk); #1;
            check(0,0,9,2);
        end
    join

    //  7번
    @(negedge r_clk);
    rd_en = 1;
    repeat (6) @(negedge r_clk);
    check(0,0,9,8);
    @(negedge r_clk);
    check(0,1,9,9);
    @(negedge r_clk);

    //  random

    fork : rand_phase
        begin
            repeat (CYCLE) begin
                @(negedge w_clk);
                wr_en = ({$random(w_seed)} % 100) < WR_PROB;
                wr_data = $random(w_seed);
            end
            disable rand_phase;
        end
        begin
            repeat (CYCLE) begin
                @(negedge r_clk);
                rd_en = ({$random(r_seed)} % 100) < RD_PROB;
            end
            disable rand_phase;
        end
    join

    wr_en = 0;
    rd_en = 0;
    
    k = 0;
    while((wr_cnt - rd_cnt !== 0) && k < TIMEOUT) begin
        rd_en = 1;
        k = k + 1;
        @(negedge r_clk);
    end

    rd_en = 0;
    @(posedge r_clk);
    @(negedge r_clk);

    $display("[%0t] full=%0d empty=%0d",$time, cnt_full, cnt_empty);
    $display("[%0t] ignored write=%0d ignored read=%0d",$time, cnt_ignore_w, cnt_ignore_r);
    if(err !== 0) $display("[%0t] FAIL: error=%0d", $time, err);
    else $display("[%0t] PASS: error=%0d", $time, err);
    $finish;
end

always @(posedge w_clk or negedge w_rst_n) begin
    if(!w_rst_n) wr_cnt <= 0;
    else if(u_async_fifo.w_rst_n_sync) begin
        if(gray2bin(u_async_fifo.gray_wptr) !== u_async_fifo.wptr) begin
            err = err + 1;
            $display("[%0t] Error: gray_bin=%b wptr=%b ",$time, gray2bin(u_async_fifo.gray_wptr), u_async_fifo.wptr); 
        end
        if(wr_en && !full) begin
            if(wr_cnt == MAX_WR) begin
                err = err + 1;
                $display("[%0t] Error: mem full wr_cnt=%0d",$time,wr_cnt);
            end
            if((wr_cnt - rd_cnt) >= (1 << AW)) begin
                err = err + 1;
                $display("[%0t] Error: overflow wr_cnt=%0d depth=%0d",$time, wr_cnt, REAL_DEPTH);
            end
            else begin
                wr_cnt <= wr_cnt + 1;
                exp_mem[wr_cnt] <= wr_data;
            end
        end
    end
end

always @(posedge r_clk or negedge r_rst_n) begin
    if(!r_rst_n) begin
        rd_cnt <= 0;
        read <= 0;
        tmp <= 0;
    end
    else if(u_async_fifo.r_rst_n_sync) begin
        if(gray2bin(u_async_fifo.gray_rptr) !== u_async_fifo.rptr) begin
            err = err + 1;
            $display("[%0t] Error: gray_bin=%b rptr=%b ",$time, gray2bin(u_async_fifo.gray_rptr), u_async_fifo.rptr); 
        end

        if(read) begin
            read <= 0;
            if(tmp !== rd_data) begin
            err = err + 1;
            $display("[%0t] Error: read data rd_data=%h exp=%h",$time, rd_data, tmp);
            end
        end

        if(rd_en && !empty) begin
            if((wr_cnt - rd_cnt) <= 0) begin
                err = err + 1;
                $display("[%0t] Error: underflow rd_cnt=%d depth=%d",$time, rd_cnt, REAL_DEPTH);
            end
            else begin
                rd_cnt <= rd_cnt + 1;
                tmp <= exp_mem[rd_cnt];
                read <= 1;
            end
        end

    end
end

always @(posedge w_clk or negedge w_rst_n) begin
    if(!w_rst_n) begin
        cnt_full <= 0;
        cnt_ignore_w <= 0;
    end
    else if(full) begin
        cnt_full <= cnt_full + 1;
        if(wr_en) cnt_ignore_w <= cnt_ignore_w + 1;
    end
end

always @(posedge r_clk or negedge r_rst_n) begin
    if(!r_rst_n) begin
        cnt_empty <= 0;
        cnt_ignore_r <= 0;
    end
    else if(empty) begin
        cnt_empty <= cnt_empty + 1;
        if(rd_en) cnt_ignore_r <= cnt_ignore_r + 1;
    end
end


initial begin
    $dumpfile("sim/async_fifo.vcd");
    $dumpvars(0, tb_async_fifo);
end

initial begin
    r_clk = 0;
    forever #(RCYCLE/2.0) r_clk = ~r_clk;
end

initial begin
    w_clk = 0;
    forever #(WCYCLE/2.0) w_clk = ~w_clk;
end


endmodule

`default_nettype wire

