`default_nettype none
`timescale 1ns/1ps

module tb_reset_sync;

reg     clk;
reg     rst_async_n;

wire    rst_sync_n;

integer err;

reset_sync dut(
    .clk(clk),
    .rst_async_n(rst_async_n),
    .rst_sync_n(rst_sync_n)
);

task check(input exp_ff1, input exp_rst_sync_n);
    begin
        if(exp_ff1 !== dut.ff1) begin
            err = err + 1;
            $display("[%0t] Error ff1=%b, expect=%b",$time,dut.ff1, exp_ff1);
        end
        if(exp_rst_sync_n !== rst_sync_n) begin
            err = err + 1;
            $display("[%0t] Error rst_sync_n=%b, expect=%b",$time,rst_sync_n, exp_rst_sync_n);
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
    $dumpfile("sim/reset_sync.vcd");
    $dumpvars(0, tb_reset_sync);
end

initial begin
    err = 0;

    rst_async_n = 1;
    neg(2);
    check(1,1);

    rst_async_n = 0;
    #1; check(0,0);

    neg(2);
    check(0,0);

    rst_async_n = 1;
    #1; check(0,0);

    neg(1);
    check(1,0);

    neg(1);
    check(1,1);

    neg(2);
    check(1,1);

    rst_async_n = 0;
    #1; rst_async_n = 1;
    #1; check(0,0);

    neg(1);
    check(1,0);

    neg(1);
    check(1,1);

    if(err !== 0) $display("[%0t] FAIL : error=%0d", $time, err);
    else $display("[%0t] PASS : error=%0d", $time, err);

    $finish;
    
end

endmodule

`default_nettype wire
