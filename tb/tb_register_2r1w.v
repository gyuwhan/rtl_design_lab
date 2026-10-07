// 기본값 : rst_n=1, w_en=0,w_addr=0, w_data=0, r_addr1=0, r_addr2=0
//
// 1. 리셋 후 읽기                  -> 0 확인
// 2. 1~4번에 쓰고 다시 읽기         -> 쓴 값 확인
// 3. 쓰면서 같은 번호 읽기 (엣지 전) -> 새 값 확인 (창구 1, 2 각각)
// 4. w_en=0, 번호 같음 (엣지 전)    -> 옛 값 확인
// 5. w_en=0, 1clk 후               -> 안 써지는지 확인
// 6. 안 쓴 번호                    -> 0 확인

module tb_register_2r1w;

reg clk;
reg rst_n;

reg w_en;
reg [3:0] w_addr;
reg [15:0] w_data;

reg [3:0] r_addr1;
reg [3:0] r_addr2;
wire [15:0] r_data1;
wire [15:0] r_data2;

reg [5:0] pass1, pass2, fail1,fail2;

register_2r1w uut(
    .clk(clk),
    .rst_n(rst_n),
    .w_addr(w_addr),
    .w_data(w_data),
    .w_en(w_en),
    .r_data1(r_data1),
    .r_data2(r_data2),
    .r_addr1(r_addr1),
    .r_addr2(r_addr2)
);

task check(input [15:0] expected1, input [15:0] expected2);
    begin
        if(r_data1 !== expected1) begin
            $display("Fail : r_data1=%h expected=%h", r_data1, expected1); 
            fail1 = fail1 + 6'd1;
        end
        else pass1 = pass1 + 6'd1;
        if(r_data2 !== expected2) begin
            $display("Fail : r_data2=%h expected=%h", r_data2, expected2); 
            fail2 = fail2 + 6'd1;
        end
        else pass2 = pass2 + 6'd1;
    end
endtask

task wait_clk(input integer n);
    begin
        repeat (n) @(negedge clk);
    end
endtask

initial begin
    $dumpfile("sim/register_2r1w.vcd");
    $dumpvars(0, tb_register_2r1w);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 0;
    w_en = 0;
    w_addr = 4'd0;
    w_data = 16'd0;
    r_addr1 = 4'd0;
    r_addr2 = 4'd0;
    pass1 = 6'd0;
    pass2 = 6'd0;
    fail1 = 6'd0;
    fail2 = 6'd0;
    wait_clk(3);
    rst_n = 1;
    wait_clk(2);
    r_addr1 = 4'd1;
    r_addr2 = 4'd2;
    #1;
    check(16'h0000, 16'h0000);
    r_addr1 = 4'd0;
    r_addr2 = 4'd0;
    wait_clk(1);
    w_en = 1;
    w_addr = 4'd1;
    w_data = 16'h0101;
    wait_clk(1);
    w_addr = 4'd2;
    w_data = 16'h1010;
    wait_clk(1);
    w_addr = 4'd3;
    w_data = 16'h1111;
    wait_clk(1);
    w_addr = 4'd4;
    w_data = 16'h1000;
    wait_clk(1);
    w_en = 0;
    r_addr1 = 4'd1;
    r_addr2 = 4'd2;
    #1;
    check(16'h0101, 16'h1010);
    r_addr1 = 4'd3;
    r_addr2 = 4'd4;
    #1; 
    check(16'h1111, 16'h1000);
    wait_clk(1);
    w_en = 1;
    w_addr = 4'd5;
    w_data = 16'h0100;
    r_addr1 = 4'd5;
    #1;
    check(16'h0100, 16'h1000);
    wait_clk(1);
    w_addr = 4'd6;
    w_data = 16'h0010;
    r_addr2 = 4'd6;
    #1;
    check(16'h0100, 16'h0010);
    wait_clk(1);
    w_en = 0;
    #1;
    check(16'h0100, 16'h0010);
    w_addr = 4'd7;
    w_data = 16'h1111;
    r_addr1 = 4'd7;
    r_addr2 = 4'd9;
    #1;
    check(16'h0000, 16'h0000);
    wait_clk(1);
    check(16'h0000, 16'h0000);

    


    

    
    $display("pass1 =%d fail1 =%d, pass2 =%d fail2 =%d",pass1,fail1,pass2,fail2);
    #10;
    $finish;

end

endmodule

