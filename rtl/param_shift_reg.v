module param_shift_reg #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire en,
    input wire dir,
    input wire s_in,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

always @(posedge clk) begin
    if(!rst_n) begin
        q <= 0;
    end else if(load) begin
        q <= d;
    end else if(en) begin
        if(dir) begin
            q <= {q[WIDTH-2:0],s_in};
        end else begin
            q <= {s_in,q[WIDTH-1:1]};
        end
    end
    else q <= q;
end

endmodule
