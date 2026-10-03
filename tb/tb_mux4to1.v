module tb_mux4to1;

reg a;
reg b;
reg c;
reg d;
reg [1:0] sel;
reg test;
reg [6:0] pass, fail;

wire y;

integer i;

mux4to1 uut(
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .sel(sel),
    .x(y)
);


initial begin
    $dumpfile("sim/mux4to1.vcd");
    $dumpvars(0, tb_mux4to1);
end

initial begin
    {a,b,c,d,sel} = 6'd0;
    pass = 6'd0;
    fail = 6'd0;

    for(i=0;i<=63;i=i+1) begin
        {a,b,c,d,sel} = i[5:0];
        #10;
        test = (sel == 2'd0) ? a : (sel == 2'd1) ? b : (sel == 2'd2) ? c : d;
        if(y !== test) begin
            $display("error : a=%b b=%b c=%b d=%b sel=%b y=%b",a, b, c, d, sel, y);
            fail = fail + 6'd1;
        end
        else begin
            pass = pass + 6'd1;
        end

    end 

    $display("pass = %d, fail = %d",pass, fail);
#100 $finish;

end

endmodule
