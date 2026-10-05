module latch(
    input wire a,
    input wire b,
    input wire [1:0] c,
    output reg [1:0] d,
    output reg e,
    output reg q
);

always @(*) begin
    if(b) q <= a;
end

always @(*) begin
    case(c)
        2'b00: d = 2'b00;
        2'b01: d = 2'b01;
        2'b10: d = 2'b10;
    endcase
end

always @(*) begin
    e = a ? e : b;

end

endmodule
