`default_nettype none
`timescale 1ns/1ps

module tb_sync_2ff_pulse;

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

task check(input integer n, input exp_ff1, input exp_q_sync);
    begin
        #n;
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

initial begin
    clk = 0;
    forever #12.5 clk = ~clk;
end

initial begin
    $dumpfile("sim/sync_2ff_pulse.vcd");
    $dumpvars(0, tb_sync_2ff_pulse);
end

initial begin
    
    check(70,0,0);
    check(30,0,0);
    check(25,1,0);
    check(25,0,1);
    check(25,0,0);
    check(50,1,0);
    check(25,0,1);
    check(25,0,0);
    check(25,1,0);
    check(25,1,1);
    check(25,0,1);
    check(25,0,0);

    if(err !== 0) $display("[%0t] FAIL: error=%0d",$time,err);
    else $display("[%0t] PASS: error=%0d",$time,err);

    $finish;
end

initial begin
    err = 0;
    rst_n = 0;
    d_async = 0;
    #50;
    rst_n = 1;

    #15; d_async = 1;
    #10; d_async = 0;

    #35; d_async = 1;
    #10; d_async = 0;

    #70; d_async = 1;
    #30; d_async = 0;

    #65; d_async = 1;
    #30; d_async = 0;

end


endmodule

`default_nettype wire
