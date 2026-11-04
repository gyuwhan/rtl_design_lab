`default_nettype none
`timescale 1ns/1ps

module sync_2ff(
    input wire           clk,
    input wire           rst_n,
    input wire           d_async,

    output reg           q_sync
);

reg ff1;

always @(posedge clk) begin
    if(!rst_n) ff1 <= 1'd0;
    else ff1 <= d_async;
end

always @(posedge clk) begin
    if(!rst_n) q_sync <= 1'd0;
    else q_sync <= ff1;
end

endmodule

`default_nettype wire
