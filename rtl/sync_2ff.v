`default_nettype none
`timescale 1ns/1ps

module sync_2ff #(
    parameter WIDTH = 1
)(
    input wire           clk,
    input wire           rst_n,
    input wire  [WIDTH-1:0]  d_async,

    output wire  [WIDTH-1:0]  q_sync
);

(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff1;
(* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] ff2;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ff1 <= {WIDTH{1'b0}};
    else ff1 <= d_async;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ff2 <= {WIDTH{1'b0}};
    else ff2 <= ff1;
end

assign q_sync = ff2;

endmodule

`default_nettype wire
