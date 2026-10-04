module tb_shift_reg_nb();
    reg    clk;
    reg    d;
    reg    rst;
    wire     q1;
    wire     q2;
    wire     q3;

    reg [11:0] stim = 12'b0000_0100_1101;
    reg [11:0] test = 12'b0010_0110_1000;

    reg [3:0] pass, fail;

    integer i;

    initial begin
        $dumpfile("sim/shift_reg_nb.vcd");
        $dumpvars(0,tb_shift_reg_nb);
    end

    always #5 clk = ~clk;

    shift_reg_nb uut(
        .clk(clk),
        .d(d),
        .rst(rst),
        .q1(q1),
        .q2(q2),
        .q3(q3)
    );

    initial begin
        
        clk = 0;
        d = 0;
        rst = 0;
        pass = 0;
        fail = 0;

        repeat (3) @(negedge clk);
        rst = 1;
        @(negedge clk);

        for(i=0;i<12;i=i+1) begin
            @(negedge clk);
            d = stim[i];
            if(q3 !== test[i]) begin
                fail = fail + 4'd1;
                $display("fail at d=%b,q=%b,test=%b",d,q3,test[i]);
            end
            else begin
                $display("out = %d",q3);
                pass = pass + 4'd1;
            end
        end
       
        @(negedge clk);
        $display("pass=%d,fail=%d",pass,fail);
        
        #100;
        $finish;
    end


endmodule
