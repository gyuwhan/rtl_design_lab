module shift_reg_nb(
    input   wire    clk,
    input   wire    d,
    input   wire    rst,
    output  reg     q3,
    output  reg     q2,
    output  reg     q1
);

always @(posedge clk) begin
    if(!rst) begin
        {q3,q2,q1} <= 3'd0;
    end
    else begin
        q1 <= d;
        q2 <= q1;
        q3 <= q2;
    end
end

endmodule
