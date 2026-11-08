`default_nettype none
`timescale 1ns/1ps

module toggle_sync(
    input wire      clk_src,
    input wire      rst_src_n,
    input wire      pulse_src,

    input wire      clk_dst,
    input wire      rst_dst_n,

    output wire     pulse_dst

);

reg tog_src, tog_dly;
wire tog_sync;

sync_2ff u_sync(
    .clk(clk_dst),
    .rst_n(rst_dst_n),
    .d_async(tog_src),

    .q_sync(tog_sync)
);

always @(posedge clk_src) begin
    if(!rst_src_n) tog_src <= 1'b0;
    else if(pulse_src) tog_src <= ~tog_src;
end

always @(posedge clk_dst) begin
    if(!rst_dst_n) tog_dly <= 1'b0;
    else tog_dly <= tog_sync;
end

assign pulse_dst = tog_dly ^ tog_sync;

endmodule

`default_nettype wire
