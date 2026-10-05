module up_down_counter(
    input   wire    rst_n,
    input   wire    clk,
    input   wire [3:0] d,
    input   wire    en,
    input   wire    up,
    input   wire    load,

    output  wire [3:0] q
);

reg [3:0] cnt;

assign q = cnt;

always @(posedge clk) begin
    if(!rst_n) begin
        cnt <= 4'd0;
    end
    else if(load) begin
        cnt <= d;
    end
    else if(en) begin
        if(up) cnt <= cnt + 4'd1;
        else cnt <= cnt - 4'd1;
    end
end

endmodule
