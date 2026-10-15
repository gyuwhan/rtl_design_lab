// tb_vr_proc : vr_proc 검증 (PROC_CYCLES=8)
// 타이밍 : posedge 뒤 #1에 입력, negedge에 비교
//          비교 = state, in_ready, out_valid, out_data(out_valid 기대값이 1일 때만)
//
// 시나리오 (A=0A, B=0B)
// 1. 사이클 1~3   : 리셋 후 대기                                       ->    IDLE 유지
// 2. 사이클 4     : in_fire = 1로 다음 클럭에 in_data 입력받아 PROC_CYCLES 처리    
// 3. 사이클 5~12  : PROC_CYCLES(8) 사이클 대기(BUSY)                   ->   in_ready = 0, in_data = 0B
// 4. 사이클 13~14 : 처리 완료 후 out_ready = 1까지 전송 대기(RESP)       ->   out_valid = 1
// 5. 사이클 15    : out_ready = 1, in_ready = 1으로 이전 데이터 전송 후 새 데이터 입력받음(같은 클럭에 가능)
// 6. 사이클 16~23 : PROC_CYCLES(8) 사이클 대기(BUSY)                   ->   in_ready = 0
// 7. 사이클 24    : 처리 완료 후 전송 out_ready = 1 이므로 전송(RESP)    ->   out_valid = 1
// 8. 사이클 25    : 데이터 전송 후 송신 대기                             ->   in_ready = 1, out_valid = 0
//
// 판정    : err=0 이고 cycles=25 이면 PASS
// TB 검증 : RTL RESP의 in_ready=out_ready 제거 시 FAIL (err=3, 사이클 15·24)



`default_nettype none

`timescale 1ns/1ps

module tb_vr_proc;


    reg            clk;
    reg            rst_n;

    reg            in_valid;
    reg    [7:0]   in_data;
    wire           in_ready;

    reg            out_ready;
    wire   [7:0]   out_data;
    wire           out_valid;

localparam IDLE = 0,
            BUSY = 1,
            RESP = 2;

integer err, cycles;


task reset_dut;
    begin
        rst_n = 1'b0;
        in_valid = 0;
        in_data = 8'd0;
        out_ready = 0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
    end
endtask

task step(input integer n, input i_valid, input [7:0] i_data, input o_ready, input [1:0] exp_state, input exp_in_ready, input exp_out_valid, input [7:0] exp_out_data);
    begin
        repeat (n) begin
            @(posedge clk);
            #1;
            in_valid = i_valid;
            in_data = i_data;
            out_ready = o_ready;
            @(negedge clk);
            if(u_dut.state !== exp_state) begin
                $display("[%0t] Error : state=%d, expect=%d", $time, u_dut.state, exp_state);
                err = err + 1;
            end
            if(in_ready !== exp_in_ready) begin
                $display("[%0t] Error : in_ready=%d, expect=%d", $time, in_ready, exp_in_ready);
                err = err + 1;
            end
            if(out_valid !== exp_out_valid) begin
                $display("[%0t] Error : out_valid=%d, expect=%d", $time, out_valid, exp_out_valid);
                err = err + 1;
            end
            if(exp_out_valid && (out_data !== exp_out_data)) begin
                $display("[%0t] Error : out_data=%b, expect=%b", $time, out_data, exp_out_data);
                err = err + 1;
            end
            cycles = cycles + 1;
        end
    end
endtask

vr_proc #(
    .PROC_CYCLES(8)
) u_dut(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_data(in_data),
    .in_ready(in_ready),
    .out_ready(out_ready),
    .out_data(out_data),
    .out_valid(out_valid)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("sim/vr_proc.vcd");
    $dumpvars(0, tb_vr_proc);
end

initial begin

    err = 0;
    cycles = 0;

    reset_dut;

    step(3,1'b0,8'h0,1'b1,IDLE,1'b1,1'b0,8'h0);
    step(1,1'b1,8'h0A,1'b1,IDLE,1'b1,1'b0,8'h0);
    step(8,1'b1,8'h0B,1'b1,BUSY,1'b0,1'b0,8'h0);
    step(2,1'b1,8'h0B,1'b0,RESP,1'b0,1'b1,8'h0A);
    step(1,1'b1,8'h0B,1'b1,RESP,1'b1,1'b1,8'h0A);
    step(8,1'b0,8'h00,1'b1,BUSY,1'b0,1'b0,8'h00);
    step(1,1'b0,8'h00,1'b1,RESP,1'b1,1'b1,8'h0B);
    step(1,1'b0,8'h00,1'b1,IDLE,1'b1,1'b0,8'h00);

    reset_dut;
    
    if((err !== 0) || (cycles !== 25)) $display("FAIL : err=%0d, cycles=%0d",err, cycles);
    else $display("PASS : err=%0d, cycles=%0d",err, cycles);
    #100;
    $finish;
end

endmodule

`default_nettype wire 
