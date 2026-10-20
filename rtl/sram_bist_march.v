// 기능  : bist_en을 받으면 SRAM 0~255번지에 March C-를 수행한다.
//         순서: ⇑(w0) → ⇑(r0,w1) → ⇑(r1,w0) → ⇓(r0,w1) → ⇓(r1,w0) → ⇓(r0)
//         "0" = 10'h0, "1" = 10'h3FF
// 포트  : 지난 BIST와 같음 (clk, rst_n, bist_en, rd_data / csn, wen, wr_data, wr_addr, b_done, b_err)
// SRAM  : 직접 만든 모델. single-port, 한 사이클에 접근 1번. 읽기 지연 1사이클
// 리셋  : 동기, active low
// 규칙  : - IDLE에서 bist_en=1이면 시작. 동작 중 bist_en은 무시
//         - 시작할 때 b_err를 0으로 지움
//         - (r, w) 원소: 주소마다 읽기 → 쓰기 2사이클. 쓰는 사이클에 읽은 값을 비교
//         - (r) 원소: 다음 사이클에 비교. 주소 카운터 255 이후 LAST 상태에서 마지막 값 비교
//         - 틀린 값을 찾으면 b_err=1, 다음 시작까지 유지
//         - 모든 원소가 끝나면 b_done 1클럭 펄스 (최종 b_err와 같은 사이클)

`default_nettype none

module sram_bist_march(
    input   wire        clk,
    input   wire        rst_n,
    input   wire        bist_en,
    input   wire [9:0]  rd_data,

    output  reg         b_done,
    output  reg         b_err,
    output  reg         csn,
    output  reg         wen,
    output  reg  [9:0]  wr_data,
    output  wire [7:0]  wr_addr
);

localparam IDLE = 0,
            RD = 1,
            WR = 2,
            LAST = 3,
            DONE = 4;

reg [2:0] state, next_state;
reg [7:0] addr_cnt;
reg [2:0] elem_cnt;
reg [9:0] exp_data;

wire cmp_en;
wire addr_last;

wire up = (elem_cnt <= 2);

assign cmp_en = ((elem_cnt == 3'd5) && (state == RD) && (addr_cnt != 8'd255)) || ((state == WR) && (3'd0 < elem_cnt) && (elem_cnt < 3'd5)) || (state == LAST);

assign wr_addr = addr_cnt;

assign addr_last = (up ? (addr_cnt == 8'd255) : (addr_cnt == 8'd0)) && ((elem_cnt != 5) ? (state == WR) : (state == RD));

always @(posedge clk) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(posedge clk) begin
    if(!rst_n) elem_cnt <= 3'd0;
    else if(state == DONE) elem_cnt <= 3'd0;
    else if(addr_last && elem_cnt != 5) elem_cnt <= elem_cnt + 3'd1;
end

always @(posedge clk) begin
    if(!rst_n) addr_cnt <= 8'd0;
    else if(state == IDLE) addr_cnt <= 8'd0;
    else if((elem_cnt <= 3'd1) && addr_last) addr_cnt <= 8'd0;
    else if((elem_cnt >= 3'd2) && addr_last) addr_cnt <= 8'd255;
    else if(up && (state == WR)) addr_cnt <= addr_cnt + 8'd1;
    else if((state == RD) && (elem_cnt == 3'd5)) addr_cnt <= addr_cnt - 8'd1;
    else if(!up && (state == WR)) addr_cnt <= addr_cnt - 8'd1;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE : if(bist_en) next_state = WR;
        WR : begin 
            if(elem_cnt != 0) next_state = RD;
            else if(elem_cnt == 0 && addr_last) next_state = RD;
        end
        RD : begin
            if(elem_cnt != 5) next_state = WR;
            else if(elem_cnt == 5 && addr_last) next_state = LAST;
        end
        LAST : next_state = DONE;
        DONE : next_state = IDLE;
    endcase
end

always @(*) begin
    csn = 1'b1;
    wen = 1'b1;
    b_done = 1'b0;

    case(state)
        WR : begin
            csn = 1'b0;
            wen = 1'b0;
        end
        RD : begin
            csn = 1'b0;
            wen = 1'b1;
        end
        LAST : begin
            csn = 1'b1;
            wen = 1'b1;
        end
        DONE : begin
            b_done = 1'b1;
        end
    endcase
end

always @(*) begin
    exp_data = 10'h3ff;
    wr_data = 10'h0;
    case(elem_cnt)
        3'd0 : wr_data = 10'h0;
        3'd1 : begin
            wr_data = 10'h3ff;
            exp_data = 10'h0;
        end
        3'd2 : begin
            wr_data = 10'h0;
            exp_data = 10'h3ff;
        end
        3'd3 : begin
            wr_data = 10'h3ff;
            exp_data = 10'h0;
        end
        3'd4 : begin
            wr_data = 10'h0;
            exp_data = 10'h3ff;
        end
        3'd5 : exp_data = 10'h0;
        default : begin
            exp_data = 10'h3ff;
            wr_data = 10'h0;
        end
    endcase
end

always @(posedge clk) begin
    if(!rst_n) b_err <= 1'b0;
    else if(bist_en && (state == IDLE)) b_err <= 1'b0;
    else if(cmp_en && (exp_data != rd_data)) b_err <= 1'b1;
end


endmodule


`default_nettype wire
