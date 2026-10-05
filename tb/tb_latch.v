module tb_latch;
    reg a;
    reg b;
    reg [1:0] c;
    wire [1:0] d;
    wire e;
    wire q;

    latch uut (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .q(q)
    );

    initial begin
        // Initialize inputs
        a = 0;
        b = 0;
        c = 2'b00;

        // Apply test vectors
        #10 a = 1; b = 1; c = 2'b01;
        #10 a = 0; b = 1; c = 2'b10;
        #10 a = 1; b = 0; c = 2'b11;
        #10 a = 0; b = 1; c = 2'b00;

        // Finish simulation
        #10 $finish;
    end

    initial begin
        $dumpfile("sim/latch.vcd");
        $dumpvars(0,tb_latch);
    end

endmodule