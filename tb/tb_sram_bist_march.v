// tb_sram_bist_march : sram_bist_march 검증 (sram 모델과 연결)
// 사이클 1 = bist_en을 받은 사이클, 정상 완료는 사이클 2563
// 타이밍 : 입력은 posedge 뒤 #1, b_err는 해당 사이클 posedge 뒤 #1에 확인
//
// 실행 1 : 고장 없음 -> 검사 진행 중, DONE 상태에 bist_en 펄스인가, 무시 확인, 2563에 b_done, b_err=0 (정상 완료)
//
// 실행 2 : 1520 사이클에 mem[152] = 10'h123 덮어씀  -> 2001 b_err=0 -> 2002 b_err=1, 이후 IDLE에서 유지
//
// 실행 3 : 2 b_err=0 (시작할 때 지움), 2400 사이클에 mem[0] = 10'h321 덮어씀 -> 2562 b_err=0 -> 2563 b_err=1, 이후 IDLE에서 유지
//
// TB 검증 : 원소 2→3 시작 주소를 0으로 바꾸면 실행 1의 wait_done에서 FAIL (b_done 2053)
//          원소 5 첫 주소 비교 제외를 지우면 실행 3의 2562에서 FAIL (고장을 2306에 넣었을 때만)

`default_nettype none
`timescale 1ns/1ps

module tb_sram_bist_march;

reg clk;
reg rst_n;
reg bist_en;

wire [9:0] rd_data;
wire csn;
wire wen;
wire [9:0] wr_data;
wire [7:0] wr_addr;
wire b_done;
wire b_err;

integer cycles, err;

localparam DONE_CYCLE = 2563;

task reset_dut;
    begin
        rst_n = 0;
        bist_en = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
    end
endtask

task start_bist;
    begin
        @(posedge clk);
        #1;
        bist_en = 1;
        cycles = 1;
        @(posedge clk);
        #1;
        bist_en = 0;
    end
endtask

task wait_done(input exp_err);
    integer n;
    begin
        for(n=0; n<6000 && b_done !== 1'b1; n=n+1) begin
            @(negedge clk);
        end
        if(n >= 6000) begin
           $display("FAIL : timeout");
           err = err + 1; 
        end
        if(cycles !== DONE_CYCLE || b_err !== exp_err) begin
            $display("FAIL : error=%d expected=%d cycles=%0d done_cycle=%0d", b_err, exp_err, cycles, DONE_CYCLE);
            err = err + 1;
        end
    end
endtask

task wait_cycle(input integer c);
    begin
        while(cycles != c) begin
            @(posedge clk);
            #1;
        end
    end
endtask

task pulse_bist_en(input integer c);
    begin
        wait_cycle(c);
        #1;
        bist_en = 1;
        wait_cycle(c+1);
        #1;
        bist_en = 0;
    end
endtask

task check_err(input integer c, input exp_err);
    begin
        wait_cycle(c);
        if(b_err !== exp_err) begin
            err = err + 1;
            $display("FAIL : cycles = %0d  error=%d expected=%d",cycles,b_err, exp_err);
        end
        else begin
            $display("PASS : cycles = %0d  error=%d expected=%d",cycles,b_err, exp_err);
        end
    end
endtask

always@(posedge clk) begin
    cycles <= cycles + 1;
end

sram_bist_march u_bist(
    .clk(clk),
    .rst_n(rst_n),
    .bist_en(bist_en),
    .rd_data(rd_data),
    .csn(csn),
    .wen(wen),
    .wr_data(wr_data),
    .wr_addr(wr_addr),
    .b_done(b_done),
    .b_err(b_err)
);

sram u_sram(
    .clk(clk),
    .csn(csn),
    .wen(wen),
    .addr(wr_addr),
    .wdata(wr_data),
    .rdata(rd_data)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("sim/sram_bist_march.vcd");
    $dumpvars(0, tb_sram_bist_march);
end

initial begin
  
    cycles = 0;
    err = 0;
    reset_dut;

    start_bist;
    pulse_bist_en(501);
    pulse_bist_en(770);   
    wait_done(1'b0);
    pulse_bist_en(2563);

    repeat (5) @(negedge clk);
    if (csn === 1'b0) begin
        err = err + 1;
        $display("FAIL : bist_en error");
    end

    start_bist;
    wait_cycle(1520);
    u_sram.mem[152] = 10'h123;
    check_err(1521, 1'b0);
    check_err(2001, 1'b0);
    check_err(2002, 1'b1);
    check_err(2563, 1'b1);
    wait_done(1'b1);

    repeat (5) @(negedge clk);
    if (b_err !== 1'b1) begin
        err = err + 1;
        $display("FAIL : b_err clear in IDLE");
    end

    start_bist;
    check_err(2, 1'b0);
    wait_cycle(2400);
    u_sram.mem[0] = 10'h321;
    check_err(2562, 1'b0);
    check_err(2563, 1'b1);   
    wait_done(1'b1);

    if(err == 0) $display("PASS : cycles = %0d",cycles);
    else $display("FAIL  cycles = %0d error = %0d",cycles,err);

    #100;
    $finish;
end



endmodule

`default_nettype wire