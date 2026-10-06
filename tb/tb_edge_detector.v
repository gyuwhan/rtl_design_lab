module tb_edge_detector;

reg clk;
reg rst_n;
reg sig;

wire rise;
wire fall;

reg [3:0] fail, pass;

reg [13:0] test, exp_rise, exp_fall;

integer i;

edge_detector uut(
    .clk(clk),
    .rst_n(rst_n),
    .sig(sig),
    .rise(rise),
    .fall(fall)
);

task wait_clk(input integer n);
    begin
        repeat (n) @(negedge clk);
    end
endtask

task check(input [1:0] expected);
    begin
        if(expected !== {rise, fall}) begin
            $display("FAIL : rise=%b fall=%b, expected rise, fall = %b", rise, fall, expected);
            fail = fail + 4'd1;
        end
        else pass = pass + 4'd1;
    end
endtask

initial begin
    $dumpfile("sim/edge_detector.vcd");
    $dumpvars(0, tb_edge_detector);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 0;
    sig = 0;
    pass = 4'd0;
    fail = 4'd0;
    test = 14'b00_0001_0011_1000;
    exp_rise = 14'b00_0001_0000_1000;
    exp_fall = 14'b00_0010_0100_0000;
    wait_clk(3);
    rst_n = 1;
    wait_clk(2);
    for(i=0;i<14;i=i+1) begin
        sig = test[i];
        wait_clk(1);
        check({exp_rise[i],exp_fall[i]});
    end
    wait_clk(3);
    $display("pass=%d fail=%d", pass, fail);
    $finish;
end

endmodule
