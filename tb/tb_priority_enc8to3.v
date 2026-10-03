module tb_priority_enc8to3;

reg [7:0] a;

wire [2:0] y;
wire valid;
reg [2:0] test;
reg test_val;
reg [8:0] pass, fail;

integer i;

priority_enc8to3 uut(
    .a(a),
    .y(y),
    .valid(valid)
);

initial begin
    $dumpfile("sim/priority_enc8to3.vcd");
    $dumpvars(0,tb_priority_enc8to3);
end

initial begin
    a = 0;
    fail = 9'd0;
    pass = 9'd0;
    for(i=0;i<256;i=i+1) begin
        a = i[7:0];
        #10;
        test = a[7] ? 3'd7 : a[6] ? 3'd6 : a[5] ? 3'd5 : a[4] ? 3'd4 : a[3] ? 3'd3 : a[2] ? 3'd2 : a[1] ? 3'd1 : 3'd0;
        test_val = |a;

        if((y !== test) | (valid !== test_val)) begin
            $display("error :a=%b y=%d valid=%b test=%d, test_valid=%b",a, y, valid, test, test_val);
            fail = fail + 9'd1;
        end
        else begin
            pass = pass + 9'd1;
        end
    end
    $display("pass = %d, fail = %d",pass, fail);

    #100;
    $finish;
end
    



endmodule
