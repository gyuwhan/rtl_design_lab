// vr_proc
// in 쪽 valid/ready로 8비트 데이터 1개를 받아, PROC_CYCLES 클럭 처리 후
// out 쪽 valid/ready로 같은 값을 내보낸다. 한 번에 1개만 처리한다.
//
// 포트     : clk, rst_n
//            in_valid, in_data[7:0], in_ready
//            out_valid, out_data[7:0], out_ready
// 파라미터 : PROC_CYCLES (기본 8, 범위 1~256)
// 리셋     : 동기, active low. 리셋 후 in_ready=1, out_valid=0
// 지연     : in 쪽 전송 엣지 이후 PROC_CYCLES+1번째 사이클에 out_valid=1
// 규칙     : - 처리 중(BUSY)에는 in_ready=0
//            - out_valid=1이면 out 쪽 전송까지 out_valid, out_data 유지
//            - out 쪽 전송 사이클에 in_valid=1이면 같은 엣지에 다음 요청을 받음
//
// 상태     : IDLE (in_ready=1,         out_valid=0) --in_fire--------------> BUSY
//            BUSY (in_ready=0,         out_valid=0) --cnt==PROC_CYCLES-1----> RESP
//            RESP (in_ready=out_ready, out_valid=1) --out_ready & in_valid--> BUSY
//                                                   --out_ready & !in_valid-> IDLE


`default_nettype none

module vr_proc#(
    parameter PROC_CYCLES = 8
)(
    input   wire            clk,
    input   wire            rst_n,
    input   wire            in_valid,
    input   wire    [7:0]   in_data,
    output  reg             in_ready,

    input   wire            out_ready,
    output  wire    [7:0]   out_data,
    output  reg             out_valid
);

localparam IDLE = 2'd0,
            BUSY = 2'd1,
            RESP = 2'd2;

reg [1:0]   state, next_state;
reg [7:0]   data_reg;
reg [7:0]   cnt;

wire in_fire = in_valid && in_ready;

assign out_data = data_reg;

always @(posedge clk) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(posedge clk) begin
    if(!rst_n) cnt <= 8'd0;
    else if(state == BUSY) cnt <= cnt + 8'd1;
    else cnt <= 8'd0;
end

always@(posedge clk) begin
    if(!rst_n) data_reg <= 8'd0;
    else if(in_fire) data_reg <= in_data; 
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE : next_state = in_fire ? BUSY : IDLE;
        BUSY : if(cnt == PROC_CYCLES-1) next_state = RESP;
        RESP : begin
            if(out_ready && in_valid) next_state = BUSY;
            else if(out_ready) next_state = IDLE;
        end
        default : next_state = IDLE;
    endcase

end

always @(*) begin
    in_ready = 1'b0;
    out_valid = 1'b0;
    case(state)
        IDLE : in_ready = 1'b1;
        RESP : begin
            out_valid = 1'b1;
            in_ready = out_ready;
        end
        default : begin
            in_ready = 1'b0;
            out_valid = 1'b0;
        end
    endcase
end

endmodule

`default_nettype wire
