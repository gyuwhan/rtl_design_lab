`default_nettype none
`timescale 1ns/1ps

module async_fifo #(
    parameter   DEPTH = 8,
                DW    = 10
)(
    input wire          w_clk,
    input wire          w_rst_n,
    input wire          wr_en,
    input wire [DW-1:0] wr_data,

    input wire          r_clk,
    input wire          r_rst_n,
    input wire          rd_en,

    output reg [DW-1:0] rd_data,
    output reg          full,
    output reg          empty
);

localparam AW = $clog2(DEPTH);          // DEPTH 이상 최소 2의 거듭제곱값(PTR WIDTH)
localparam REAL_DEPTH = (1 << AW);      // 실제 생성되는 MEM의 DEPTH

reg [AW:0] wptr, gray_wptr;
reg [AW:0] rptr, gray_rptr;

wire [AW:0] sync_wptr, sync_rptr;

wire w_rst_n_sync, r_rst_n_sync;        // reset sync 출력 연결

wire wr_accept = wr_en && !full;        // 쓰기 수락
wire rd_accept = rd_en && !empty;       // 읽기 수락

wire [AW:0] sync_wptr_bin = gray2bin(sync_wptr);
wire [AW:0] sync_rptr_bin = gray2bin(sync_rptr);

wire [AW:0] wptr_next = wptr + {{AW{1'b0}},wr_accept};
wire [AW:0] rptr_next = rptr + {{AW{1'b0}},rd_accept};

reg [DW-1:0] mem [0:REAL_DEPTH-1];

reset_sync u_rst_wclk(
    .clk(w_clk),
    .rst_async_n(w_rst_n),
    .rst_sync_n(w_rst_n_sync)
);

reset_sync u_rst_rclk(
    .clk(r_clk),
    .rst_async_n(r_rst_n),
    .rst_sync_n(r_rst_n_sync)
);

always @(posedge w_clk or negedge w_rst_n_sync) begin
    if(!w_rst_n_sync) wptr <= 0;
    else if(wr_accept) begin
        wptr <= wptr + 1;
    end
end

always @(posedge w_clk) begin
    if(wr_accept) begin
        mem[wptr[AW-1:0]] <= wr_data;
    end
end

always @(posedge r_clk or negedge r_rst_n_sync) begin
    if(!r_rst_n_sync) begin 
        rptr <= 0;
        rd_data <= 0;
    end
    else if(rd_accept) begin
        rptr <= rptr + 1;
        rd_data <= mem[rptr[AW-1:0]];
    end
end

always @(posedge w_clk or negedge w_rst_n_sync) begin
    if(!w_rst_n_sync) gray_wptr <= 0;
    else begin
        gray_wptr <= bin2gray(wptr_next);
    end
end

always @(posedge r_clk or negedge r_rst_n_sync) begin
    if(!r_rst_n_sync) gray_rptr <= 0;
    else begin
        gray_rptr <= bin2gray(rptr_next);
    end
end

sync_2ff #(.WIDTH(AW+1)
    ) u_2ff_wclk(
    .clk(w_clk),
    .rst_n(w_rst_n_sync),
    .d_async(gray_rptr),
    .q_sync(sync_rptr)
);

sync_2ff #(.WIDTH(AW+1)
    ) u_2ff_rclk(
    .clk(r_clk),
    .rst_n(r_rst_n_sync),
    .d_async(gray_wptr),
    .q_sync(sync_wptr)
);

always @(posedge w_clk or negedge w_rst_n_sync) begin
    if(!w_rst_n_sync) full <= 0;
    else if(wptr_next[AW] != sync_rptr_bin[AW] && wptr_next[AW-1:0] == sync_rptr_bin[AW-1:0]) full <= 1;
    else full <= 0;
end

always @(posedge r_clk or negedge r_rst_n_sync) begin
    if(!r_rst_n_sync) empty <= 1;
    else if(rptr_next == sync_wptr_bin) empty <= 1;
    else empty <= 0;
end

function [AW:0] gray2bin (input [AW:0] gray);
    integer i;
    begin
        gray2bin[AW] = gray[AW];
        for(i = (AW-1);i >= 0; i = i - 1) begin
            gray2bin[i] = gray2bin[i + 1] ^ gray[i];
        end
    end
endfunction

function [AW:0] bin2gray (input [AW:0] bin);
    bin2gray = bin ^ (bin >> 1);
endfunction

endmodule

`default_nettype wire

