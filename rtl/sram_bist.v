// 기능  : bist_en을 받으면 SRAM 0~255번지에 패턴을 전부 쓰고, 전부 읽어 비교한다.
//         패턴 순서 3FF → 000 → 2AA.
// 포트  : 입력 clk, rst_n(active low), bist_en, rd_data[9:0]
//         출력 csn, wen, wr_data[9:0], wr_addr[7:0], b_done, b_err
// SRAM  : 제공 모델 그대로. csn=0일 때 동작, wen=0 쓰기 / 1 읽기
//         주소를 낸 다음 사이클에 그 주소의 값이 rd_data로 나옴 (읽기 지연 1)
// 리셋  : 동기, active low
// 규칙  : - IDLE에서 bist_en=1이면 시작. 동작 중 bist_en은 무시
//         - 시작할 때 b_err를 0으로 지움
//         - READ 첫 사이클(주소 0)은 비교하지 않음. 255번지 값은 LAST_CHECK에서 비교
//         - 틀린 값을 찾으면 b_err=1, 다음 시작까지 유지
//         - 모든 패턴이 끝나면 b_done 1클럭 펄스 (b_err 갱신과 같은 사이클)

`default_nettype none 
 
module sram_bist(
    input wire  clk,
    input wire  rst_n,
    input wire  bist_en,
    input wire  [9:0] rd_data,
    
    output reg csn,
    output reg wen,
    output reg [9:0] wr_data,
    output wire [7:0] wr_addr,
    output reg b_done,
    output reg b_err
);

localparam IDLE = 3'd1,
            WRITE = 3'd2,
            READ = 3'd3,
            LAST_CHECK = 3'd4,
            DONE = 3'd5;

reg [2:0] state, next_state;
reg [7:0] addr_cnt;
reg [1:0] pat_cnt;

wire cmp_en = (state == READ && addr_cnt != 8'd0) || (state == LAST_CHECK);

assign wr_addr = addr_cnt;


always @(posedge clk) begin
    if(!rst_n) addr_cnt <= 8'd0;
    else if(addr_cnt == 8'd255) addr_cnt <= 8'd0;
    else if(state == WRITE || state == READ) addr_cnt <= addr_cnt + 8'd1;
    else addr_cnt <= 8'd0;
end

always @(posedge clk) begin
    if(!rst_n || state == DONE) pat_cnt <= 2'd0;
    else if(state == LAST_CHECK && pat_cnt != 2'd2) pat_cnt <= pat_cnt + 2'd1;
end

always@(posedge clk) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE : if(bist_en) next_state = WRITE;
        WRITE : if(addr_cnt == 255) next_state = READ;
        READ : if(addr_cnt == 255) next_state = LAST_CHECK;
        LAST_CHECK : begin
            if(pat_cnt == 2) next_state = DONE;
            else next_state = WRITE;
        end
        DONE : next_state = IDLE;
        default : next_state = IDLE;
    endcase
end

always @(*) begin
    csn = 1;
    wen = 1;
    b_done = 0;
    case(state)
        WRITE : begin
            csn = 0;
            wen = 0;
        end
        READ : begin
            csn = 0;
            wen = 1;
        end
        LAST_CHECK : begin
            csn = 1;
            wen = 1;
        end
        DONE : begin
            csn = 1;
            wen = 1;
            b_done = 1;
        end
        default : begin
            csn = 1;
            wen = 1;
            b_done = 0;
        end
    endcase
end

always @(*) begin
    wr_data = 10'h3ff;
    case(pat_cnt)
        2'd0 : wr_data = 10'h3ff; 
        2'd1 : wr_data = 10'd0;
        2'd2 : wr_data = 10'h2aa;
        default : wr_data = 10'h3ff;
    endcase
end

always @(posedge clk) begin
    if(!rst_n) b_err <= 1'd0;
    else if (bist_en && state == IDLE) b_err <= 1'd0;
    else if(cmp_en && (rd_data != wr_data)) b_err <= 1'd1;
end

endmodule

`default_nettype wire
