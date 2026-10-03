module tb_dec3to8;

reg [2:0] a;
reg [7:0] test;

wire [7:0] y;
reg [4:0] pass, fail;

integer i;


dec3to8 uut(
    .a(a),
    .y(y)
);

initial begin
    
    a = 3'd0;
    test = 8'd0;
    pass = 5'd0;
    fail = 5'd0;

    for(i=0;i<8;i=i+1) begin
        a = i[2:0];
        #10;
        test = (8'd1 << i);
        if(y !== test) begin
            $display("error : a=%d y=%b test = %b",a, y, test);
            fail = fail + 5'd1;
        end
        else begin
            pass = pass + 5'd1;
        end
    end
    $display("pass = %d, fail = %d",pass, fail);
    #100;
    
    $finish;
end

initial begin
    $dumpfile("sim/dec3to8.vcd");
    $dumpvars(0,tb_dec3to8);
end

endmodule
