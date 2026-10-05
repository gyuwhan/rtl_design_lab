module tb_param_shift_reg #(
    parameter WIDTH = 4
)();

reg clk;
reg rst_n;
reg load;
reg en;
reg dir;
reg s_in;
reg [WIDTH-1:0] d;
wire [WIDTH-1:0] q;

reg [4:0] pass, fail;

param_shift_reg uut (
    .clk(clk),
    .rst_n(rst_n),
    .load(load),
    .en(en),
    .dir(dir),
    .s_in(s_in),
    .d(d),
    .q(q)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

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
    rst_n = 0;
    load = 0;
    en = 0;
    dir = 0;
    s_in = 0;
    d = 0;
    pass = 5'd0;
    fail = 5'd0;

    #15;
    @(negedge clk);
    rst_n = 1;

    @(negedge clk);
    check(4'd0);
    load = 1;
    d    = 4'b1010;

    @(negedge clk);
    check(4'b1010);
    load = 0;
    en   = 1;
    dir  = 1;
    s_in = 1;

    @(negedge clk);
    check(4'b0101);
    s_in = 0;

    @(negedge clk);
    check(4'b1010);
    s_in = 1;

    @(negedge clk);
    check(4'b0101);
    dir  = 0;
    s_in = 1;

    @(negedge clk);
    check(4'b1010);
    s_in = 0;

    @(negedge clk);
    check(4'b0101);
    en   = 0;
    repeat (2) @(negedge clk);
    check(4'b0101);

    @(negedge clk);
    rst_n = 0;

    @(negedge clk);
    check(4'b0000);

    rst_n = 1;
    $display("pass=%d fail=%d", pass, fail);
    #20;
    $finish;

end


initial begin
    $dumpfile("sim/param_shift_reg.vcd");
    $dumpvars(0, tb_param_shift_reg);
end

endmodule

/*

1.   rst_n=0                        0000
2.   load=1, d=1010                 1010
3.   en=1, dir=1, s_in=1            0101
4.   s_in=0                         1010
5.   s_in=1                         0101
6.   dir=0, s_in=1                  1010
7.   s_in=0                         0101
8.   en=0  (2클럭)                   0101
9.   rst_n=0                        0000

*/