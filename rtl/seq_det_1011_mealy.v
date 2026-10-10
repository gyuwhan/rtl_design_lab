module seq_det_1011_mealy(
    input   wire        clk,
    input   wire        rst_n,
    input   wire        din,

    output  reg         det
);

localparam IDLE = 2'd0,
            S0  = 2'd1,
            S1  = 2'd2,
            S2  = 2'd3;

reg [1:0] state, next_state;

always @(posedge clk) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    next_state = state;
    det = 1'b0;
    case(state)
        IDLE : next_state = din ? S0 : IDLE;
        S0 : next_state = din ? S0 : S1;
        S1 : next_state = din ? S2 : IDLE;
        S2 : begin
                if(din) begin
                    next_state = S0;
                    det = 1'b1;
                end
                else next_state = S1;
        end
        default : begin
            next_state = IDLE;
            det = 1'b0;  
        end 
    endcase
end 

endmodule
