module tb_up_down_counter;

reg rst_n;
reg clk;
reg [3:0] d;
reg en;
reg up;
reg load;

wire [3:0] q;

reg [3:0] pass, fail;

up_down_counter uut(
    .rst_n(rst_n),
    .clk(clk),
    .d(d),
    .en(en),
    .up(up),
    .load(load),
    .q(q)
);

task wait_negclk(input integer n);
    begin
        repeat (n) @(negedge clk);
    end
endtask

task check(input [3:0] expected);
    begin
        if(expected !== q) begin
            $display("FAIL : q=%d expected=%d", q, expected);
            fail = fail + 1;
        end
        else pass = pass + 1;
    end
endtask

initial begin
    $dumpfile("sim/up_down_counter.vcd");
    $dumpvars(0, tb_up_down_counter);
end

initial begin
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1;
    clk = 0;
    pass = 4'd0;
    fail = 4'd0;
    load = 0;
    en = 0;
    up = 0;
    d = 4'd0;
    wait_negclk(1);
    rst_n = 0;
    wait_negclk(2);
    check(4'd0);
    rst_n = 1;
    wait_negclk(1);
    en = 1;
    up = 1;
    wait_negclk(3);
    check(4'd3);
    en = 0;
    wait_negclk(3);
    check(4'd3);
    load = 1;
    d = 4'd14;
    wait_negclk(3);
    check(4'd14);
    en = 1;
    load = 0;
    d = 4'd0;
    wait_negclk(3);
    check(4'd1);
    up = 0;
    load = 1;
    d = 4'd4;
    wait_negclk(3);
    check(4'd4);
    load = 0;
    d = 4'd0;
    wait_negclk(6);
    check(4'd14);
    rst_n = 0;
    load = 1;
    d = 4'd5;
    wait_negclk(3);
    check(4'd0);
    
    $display("pass=%d fail=%d", pass, fail);
    #100;
    $finish;

end

endmodule

/*
기본값 : rst_n = 1, load = 0, en = 0, up = 0, d = 0

1. rst_n = 0 2clk q = 0
2. en = 1, up = 1 3 clk q = 3
3. en = 0, up = 1 3 clk q = 3
4. en = 0, up = 1 load 1, d = 14, 3 clk q = 14
5. en = 1, up = 1 load 0, d = 0, 3 clk q = 1
6. en = 1, up = 0 load 1, d = 4, 3 clk q = 4
7. en = 1, up = 0 load 0, d = 0, 6 clk q = 14
8. en = 1, up = 0 rst_n = 0 load = 1 d = 5 3 clk q = 0
*/