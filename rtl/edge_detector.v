//sig는 동기 신호라고 가정
//rise, fall registered output

module edge_detector(
    input wire clk,
    input wire rst_n,
    input wire sig,
    
    output reg rise,
    output reg fall
);

reg dly;

always@(posedge clk) begin
    if(!rst_n) dly <= 1'd0;
    else dly <= sig;
end

always @(posedge clk) begin
    if(!rst_n) begin
        rise <= 1'd0;
        fall <= 1'd0;
    end
    else begin
        rise <= sig & ~dly;
        fall <= ~sig & dly;
    end
end

endmodule
