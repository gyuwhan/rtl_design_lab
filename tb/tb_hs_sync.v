`default_nettype none
`timescale 1ns/1ps

module tb_hs_sync #(
    parameter WIDTH = 8,
    T_SRC = 10,
    T_DST = 25
);

reg               clk_src;
reg               rst_src_n;
reg [WIDTH-1:0]   data_in;
reg               send;

reg               clk_dst;
reg               rst_dst_n;

wire [WIDTH-1:0]  data_out;
wire              busy;
wire              valid_dst;

integer err, sent, recv;

reg valid_dly;
reg [WIDTH-1:0] mem [0:15];

hs_sync #(
    .WIDTH(8)
) u_hs_sync(
        .clk_src(clk_src),
        .rst_src_n(rst_src_n),
        .data_in(data_in),
        .send(send),
        .clk_dst(clk_dst),
        .rst_dst_n(rst_dst_n),
        .data_out(data_out),
        .busy(busy),
        .valid_dst(valid_dst)
);

initial begin
    clk_src = 0;
    forever #(T_SRC/2.0) clk_src = ~clk_src;
end

initial begin
    clk_dst = 0;
    forever #(T_DST/2.0) clk_dst = ~clk_dst;
end

initial begin
    $dumpfile("sim/hs_sync.vcd");
    $dumpvars(0, tb_hs_sync);
end


initial begin
    err = 0;
    sent = 0;
    recv = 0;
    rst_dst_n = 1;
    rst_src_n = 1;
    
    reset;
    send_data(8'hA);

    send = 1;   data_in = 8'hB;
    @(negedge clk_src);

    if(!busy) begin
        err = err + 1;
        $display("[%0t]Error: busy don't rise", $time);
    end

    send = 0;   data_in = 8'hC;
    @(negedge clk_src);
    
    send_data(8'hD);
    send_data(8'hE);
    
    while(busy) begin
        @(negedge clk_src);
    end

    if(recv !== sent) begin
        err = err + 1;
        $display("[%0t]Error: sent=%0d recv=%0d", $time, sent, recv);
    end

    if(err !== 0) $display("[%0t]FAIL: error=%0d",$time,err);
    else $display("[%0t]PASS: error=%0d",$time,err);

    $finish;
end

task reset;
    begin
        rst_dst_n = 0;
        rst_src_n = 0;
        data_in = {WIDTH{1'b0}};
        send = 0;
        repeat (2) begin
            @(negedge clk_dst);
            @(negedge clk_src);
        end
        rst_dst_n = 1;
        rst_src_n = 1;
    end
endtask

task send_data(input [WIDTH-1:0] in_data);
    begin
        @(negedge clk_src);
        while(busy) begin
            @(negedge clk_src);
        end
        data_in = in_data;
        send = 1;
        @(negedge clk_src);
        send = 0;
        mem[sent] = in_data;
        sent = sent + 1;
    end
endtask

always @(posedge clk_dst) begin
    if(!rst_dst_n) begin
        recv = 0;
        valid_dly = 0;
    end
    else if(valid_dst) begin
        if(data_out === mem[recv]) begin
            recv = recv + 1;
        end
        else begin
            err = err + 1;
            $display("[%0t]Error: no.%0d sent data=%0h recv data=%0h", $time, recv, mem[recv], data_out);
            recv = recv + 1;
        end
        if(valid_dly) begin
            err = err  + 1;
            $display("[%0t]Error: valid high 2 clock", $time);
        end
        valid_dly = 1;
    end
    else valid_dly = 0;

end


endmodule

`default_nettype wire
