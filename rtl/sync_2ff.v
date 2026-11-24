`default_nettype none
`timescale 1ns/1ps

module sync_2ff #(
    parameter WIDTH = 1
)(
    input wire           clk,
    input wire           rst_n,
    input wire  [WIDTH-1:0]  d_async,

    output reg  [WIDTH-1:0]  q_sync
);

reg [WIDTH-1:0] ff1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ff1 <= {WIDTH{1'b0}};
    else ff1 <= d_async;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) q_sync <= {WIDTH{1'b0}};
    else q_sync <= ff1;
end

endmodule

`default_nettype wire
