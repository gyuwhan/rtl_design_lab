// 기본값 : rst_n=0, din=0
//
// 1. 리셋                       -> 둘 다 IDLE, det=0 확인
// 2. 1 0 1 1 0 1 1 0           -> overlapping 검출 2번 Moore det 00001001 / Mealy det 00010010
// 3. 리셋 후 1 1 0 0 1 0 1 0 0  -> 검출 없음 (det 전부 0)
// 4. 리셋 후 1 0 1 1 1 0 0 0    -> 검출 1번, Moore S3에서 1 -> S0 확인
// 5. 끝                        -> err, checks 출력 (PASS/FAIL)
`default_nettype none

module tb_seq_det_1011;

reg clk;
reg rst_n;
reg din;

wire det_mo;
wire det_me;

integer err_mo, err_me, check;

localparam IDLE = 0,
            S0 = 1,
            S1 = 2,
            S2 = 3,
            S3 = 4;

task wait_negclk(input integer n);
    begin
        repeat (n) @(negedge clk);
    end
endtask

task send_bit(input sti, input exp_det_mo, input exp_det_me, input [2:0] state_mo, input [1:0] state_me);
    begin
        @(posedge clk);
        #1;
        din = sti;
        @(negedge clk);
        if(exp_det_mo !== det_mo) begin
            $display("[%0t] Error : Moore det=%b expect=%b", $time, det_mo, exp_det_mo);
            err_mo = err_mo + 5'd1;
        end
        if(exp_det_me !== det_me) begin
            $display("[%0t] Error : Mealy det=%b expect=%b", $time,det_me, exp_det_me);
            err_me = err_me + 5'd1;
        end
        if(state_mo !== u_moore.state) begin
            $display("[%0t] Error : Moore state=%d expect=%d", $time,u_moore.state, state_mo);
            err_mo = err_mo + 5'd1;
        end
        if(state_me !== u_mealy.state) begin
            $display("[%0t] Error : Mealy state=%d expect=%d", $time,u_mealy.state, state_me);
            err_me = err_me + 5'd1;
        end
        check = check + 1;
    end
endtask

task reset_det;
    begin
        rst_n = 0;
        din = 0;
        wait_negclk(2);
        rst_n = 1;
    end
endtask

seq_det_1011_mealy u_mealy(
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .det(det_me)
);

seq_det_1011_moore u_moore(
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .det(det_mo)
);

initial begin
    $dumpfile("sim/tb_seq_det.vcd");
    $dumpvars(0, tb_seq_det_1011);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    err_mo = 0;
    err_me = 0;
    check = 0;

    reset_det;

    send_bit(1,0,0,IDLE,IDLE);
    send_bit(0,0,0,S0,S0);
    send_bit(1,0,0,S1,S1);
    send_bit(1,0,1,S2,S2);
    send_bit(0,1,0,S3,S0);
    send_bit(1,0,0,S1,S1);
    send_bit(1,0,1,S2,S2);
    send_bit(0,1,0,S3,S0);

    reset_det;

    send_bit(1,0,0,IDLE,IDLE);
    send_bit(1,0,0,S0,S0);
    send_bit(0,0,0,S0,S0);
    send_bit(0,0,0,S1,S1);
    send_bit(1,0,0,IDLE,IDLE);
    send_bit(0,0,0,S0,S0);
    send_bit(1,0,0,S1,S1);
    send_bit(0,0,0,S2,S2);
    send_bit(0,0,0,S1,S1);

    reset_det;

    send_bit(1,0,0,IDLE,IDLE);
    send_bit(0,0,0,S0,S0);
    send_bit(1,0,0,S1,S1);
    send_bit(1,0,1,S2,S2);
    send_bit(1,1,0,S3,S0);
    send_bit(0,0,0,S0,S0);
    send_bit(0,0,0,S1,S1);
    send_bit(0,0,0,IDLE,IDLE);

    if(err_mo === 0 && err_me === 0 && check === 25) $display("PASS : Mealy error=%0d Moore error=%0d checks=%0d", err_me, err_mo, check);
    else $display("FAIL : Mealy error=%0d Moore error=%0d checks=%0d", err_me, err_mo, check);
    #100;
    $finish;
end

endmodule

`default_nettype wire
