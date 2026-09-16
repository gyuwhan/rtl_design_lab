`timescale 1ns / 1ps

module tb_mux2to1;

reg a;
reg b;
reg sel;

wire y;

integer i;

mux2to1 uut(
    .a(a),
    .b(b),
    .sel(sel),
    .y(y)
    );

initial begin
    $dumpfile("sim/mux2to1.vcd");
    $dumpvars(0, tb_mux2to1);
end

initial begin
    a = 0;
    b = 0;
    sel = 0;

    for(i=0;i<8;i=i+1) begin
        {a,b,sel} = i;
        #10;
        $display("t=%0t a=%b b=%b sel=%b -> y=%b", $time, a, b, sel, y);
    end

    #10 $finish;
end

endmodule
