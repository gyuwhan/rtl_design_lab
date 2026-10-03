module mux4to1(
    input wire a,
    input wire b,
    input wire c,
    input wire d,
    input wire [1:0] sel,

    output reg x
);

always @(*) begin
    x = 1'd0;
    case (sel)
        2'd0 : x = a; 
        2'd1 : x = b; 
        2'd2 : x = c; 
        2'd3 : x = d; 
        default: x = 0;
    endcase
end

endmodule
