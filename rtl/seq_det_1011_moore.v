module seq_det_1011_moore (
    input   wire        clk,
    input   wire        rst_n,
    input   wire        din,

    output  reg         det
);

localparam IDLE = 3'd0,
            S0  = 3'd1,
            S1  = 3'd2,
            S2  = 3'd3,
            S3  = 3'd4;

reg [2:0] state, next_state;

always @(posedge clk) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE : next_state = din ? S0 : IDLE; 
        S0 : next_state = din ? S0 : S1;
        S1 : next_state = din ? S2 : IDLE;
        S2 : next_state = din ? S3 : S1;
        S3 : next_state = din ? S0 : S1;
        default : next_state = IDLE;
    endcase
end

always @(*) begin
    det = 1'd0;
    case(state)
        S3 : det = 1'd1;
        default : det = 1'd0;
    endcase
end


endmodule

