`default_nettype none
`timescale 1ns/1ps

module tb_toggle_sync;

reg         clk_src;
reg         rst_src_n;
reg         pulse_src;

reg         clk_dst;
reg         rst_dst_n;

wire        pulse_dst;

integer err, sent, recv;

toggle_sync u_sync(
    .clk_src(clk_src),
    .rst_src_n(rst_src_n),
    .pulse_src(pulse_src),

    .clk_dst(clk_dst),
    .rst_dst_n(rst_dst_n),

    .pulse_dst(pulse_dst)
);

initial begin
    clk_src = 0;
    forever #5 clk_src = ~clk_src;
end

initial begin
    clk_dst = 0;
    forever #12.5 clk_dst = ~clk_dst;
end

initial begin
    $dumpfile("sim/toggle_sync.vcd");
    $dumpvars(0, tb_toggle_sync);
end

task check_pulse(input exp);
    begin
        if(exp !== pulse_dst) begin
            err = err + 1;
            $display("[%0t] Error: pulse_dst=%d exp=%d", $time, pulse_dst, exp);
        end
    end
endtask

task check_cnt(input integer exp_sent, input integer exp_recv);
    begin
        if(exp_sent !== sent) begin
           err = err + 1;
           $display("[%0t] Error: sent=%0d exp=%0d", $time, sent, exp_sent); 
        end
        if(exp_recv !== recv) begin
           err = err + 1;
           $display("[%0t] Error: recv=%0d exp=%0d", $time, recv, exp_recv); 
        end
    end 
endtask

always @(posedge clk_src) begin
    if(pulse_src) sent <= sent + 1;
end
//    if(!rst_src_n) sent <= 0; 

always @(posedge clk_dst) begin
//    if(!rst_dst_n) recv <= 0;
    if(pulse_dst) recv <= recv + 1;
end

initial begin
    
    err = 0;
    sent = 0;
    recv = 0;
    rst_src_n = 0;
    rst_dst_n = 0;
    pulse_src = 0;

    #20; //20ns
    rst_src_n = 1;
    rst_dst_n = 1;
    pulse_src = 1;
    check_pulse(0);

    #10; //30ns
    pulse_src = 0;
    check_pulse(0);

    #50; //80ns
    pulse_src = 1;
    check_pulse(1);

    #10; //90ns
    pulse_src = 0;
    check_pulse(0);

    #30; //120ns
    check_pulse(1);

    #20; //140ns
    check_pulse(0);

    #10; //150ns
    pulse_src = 1;

    #10; //160ns
    pulse_src = 0;
    check_pulse(0);

    #30; //190ns
    check_pulse(1);
    pulse_src = 1;

    #20; //210ns
    pulse_src = 0;

    #10; //220ns
    check_pulse(0);

    #30; //250ns
    check_pulse(0);
    check_cnt(5,3);
    rst_dst_n = 0;

    #20; //270ns
    check_pulse(0);
    rst_dst_n = 1;

    #50; //320ns
    check_pulse(1);

    #30; //350ns
    check_pulse(0);
    pulse_src = 1;

    #10; //360ns
    pulse_src = 0;

    #10; //370ns
    rst_src_n = 0;
    rst_dst_n = 0;

    #30; //400ns
    check_pulse(0);
    rst_src_n = 1;
    rst_dst_n = 1;

    #50; //450ns
    check_pulse(0);
    check_cnt(6,4);

    if(err !== 0) $display("[%0t] FAIL: err=%0d",$time, err);
    else $display("[%0t] PASS: err=%0d",$time, err);

    $finish;
end

endmodule

`default_nettype wire

