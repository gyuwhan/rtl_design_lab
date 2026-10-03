module dec3to8(
    input wire [2:0] a,

    output reg [7:0] y
);

    always@(*) begin
        case(a)
            3'd0 : y = 8'b0000_0001;
            3'd1 : y = 8'b0000_0010;
            3'd2 : y = 8'b0000_0100;
            3'd3 : y = 8'b0000_1000;
            3'd4 : y = 8'b0001_0000;
            3'd5 : y = 8'b0010_0000;
            3'd6 : y = 8'b0100_0000;
            3'd7 : y = 8'b1000_0000;
            default : y = 8'd0;
        endcase
    end 

endmodule
