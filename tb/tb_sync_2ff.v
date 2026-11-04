`default_nettype none
`timescale 1ns/1ps

module tb_sync_2ff;

reg         clk;
reg         rst_n;
reg         d_async;

wire        q_sync;

integer err;

sync_2ff dut(
    .clk(clk),
    .rst_n(rst_n),
    .d_async(d_async),
    .q_sync(q_sync)
);

task check(input exp_ff1, input exp_q_sync);
    begin
        if(dut.ff1 !== exp_ff1) begin
            $display("[%0t] Error: ff1=%d exp_ff1=%d",$time,dut.ff1, exp_ff1);
            err = err + 1;
        end
        if(q_sync !== exp_q_sync) begin
            $display("[%0t] Error: q_sync=%d exp_q_sync=%d",$time, q_sync, exp_q_sync);
            err = err + 1;
        end
    end
endtask

task neg(input integer n);
    begin
        repeat (n) @(negedge clk);
    end
endtask


initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("sim/sync_2ff.vcd");
    $dumpvars(0, tb_sync_2ff);
end

initial begin
    err = 0;
    rst_n = 1;
    d_async = 0;

    neg(1);
    rst_n = 0; d_async = 1;
    neg(2);
    check(0,0);

    rst_n = 1;
    neg(1);
    check(1,0);

    neg(1);
    check(1,1);

    d_async = 0;
    neg(1);
    check(0,1);

    neg(1);
    check(0,0);

    neg(2);
    check(0,0);

    d_async =1;
    neg(1);
    check(1,0);

    neg(1);
    check(1,1);

    neg(2);
    check(1,1);

    rst_n = 0;
    #1;
    check(1,1);

    neg(1);
    check(0,0);
    
    if(err !== 0) $display("[%0t] FAIL: error=%0d",$time,err);
    else $display("[%0t] PASS: error=%0d",$time,err);

    #100;
    $finish;
end

endmodule

`default_nettype wire

