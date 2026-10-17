// tb_sram_bist : sram_bist 검증 (sram 모델과 연결)
// 사이클 1 = bist_en을 받은 사이클, 정상 완료는 사이클 1541
// 타이밍 : 입력은 posedge 뒤 #1, b_err는 해당 사이클 posedge 뒤 #1에 확인
//
// 실행 1 : 고장 없음 -> 1541에 b_done, b_err=0 ( 정상 완료)
//
// 실행 2 : 1284에 mem[255] 덮어씀 (마지막 패턴) -> 1285 b_err=0 (읽기 주소 0 사이클은 비교 안 함)
//          -> 1541 b_err=1 (LAST_CHECK에서 255번지 검출), 이후 IDLE에서 유지
//
// 실행 3 : 258에 mem[0] 덮어씀 (첫 패턴) -> 2 b_err=0 (시작할 때 지움), 260 b_err=1 (첫 비교에서 검출)
//
// TB 검증 : cmp_en에서 주소 0 제외를 지우면 실행 2의 1285에서 FAIL
//           cmp_en에서 LAST_CHECK를 빼면 실행 2의 1541, IDLE 유지에서 FAIL

`default_nettype none
`timescale 1ns/1ps

module tb_sram_bist;

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
        for(n=0; n<3000 && b_done !== 1'b1; n=n+1) begin
            @(negedge clk);
        end
        if(n >= 3000) begin
           $display("FAIL : timeout");
           err = err + 1; 
        end
        if(cycles !== 1541 || b_err !== exp_err) begin
            $display("FAIL : error=%d expected=%d", b_err, exp_err);
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

sram_bist u_bist(
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
    $dumpfile("sim/sram_bist.vcd");
    $dumpvars(0, tb_sram_bist);
end

initial begin
  
    cycles = 0;
    err = 0;
    reset_dut;

    start_bist;
    wait_done(1'b0);
    
    start_bist;
    check_err(2, 1'b0);
    wait_cycle(1284);
    u_sram.mem[255] = 10'h044;
    check_err(1285, 1'b0);
    wait_done(1'b1);

    repeat (5) @(negedge clk);
    if (b_err !== 1'b1) begin
        err = err + 1;
        $display("FAIL : b_err clear in IDLE");
    end

    start_bist;
    check_err(2, 1'b0);
    wait_cycle(258);
    u_sram.mem[0] = 10'h044;
    check_err(260, 1'b1);
    wait_done(1'b1);

    if(err == 0) $display("PASS : cycles = %0d",cycles);
    else $display("FAIL  cycles = %0d error = %0d",cycles,err);

    #100;
    $finish;
end



endmodule

`default_nettype wire