// register_2r1w : 16개 x 16비트 register file (읽기 2, 쓰기 1)
// 쓰기 : w_en = 1이면 clk 상승 엣지에 mem[w_addr] <= w_data
// 읽기 : 조합 출력. r_addrN이 바뀌면 같은 클럭 안에 r_dataN이 나온다
// 동시 읽기/쓰기 (write-first) :
// w_en = 1이고 w_addr == r_addrN이면 r_dataN = w_data
// (메모리에 써지기 전에 새 값을 출력 : 새 값을 read 해 계산하기 위함)
// 리셋 : rst_n = 0이면 clk 상승 엣지에 전체 0 (동기 리셋)

module register_2r1w(
    input wire clk,
    input wire rst_n,
    input wire [3:0] w_addr,
    input wire [15:0] w_data,
    input wire w_en,

    output wire [15:0] r_data1,
    output wire [15:0] r_data2,
    input wire [3:0] r_addr1,
    input wire [3:0] r_addr2
);

reg [15:0] mem [0:15];

integer i;

always @(posedge clk) begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
            mem[i] <= 16'd0;
        end
    end
    else if(w_en) begin
        mem[w_addr] <= w_data;
    end
end


assign r_data1 = (w_en && (w_addr == r_addr1)) ? w_data : mem[r_addr1];
assign r_data2 = (w_en && (w_addr == r_addr2)) ? w_data : mem[r_addr2];


endmodule
