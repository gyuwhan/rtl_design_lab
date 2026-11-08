`default_nettype none
`timescale 1ns/1ps

module reset_sync(
    input wire      clk,
    input wire      rst_async_n,

    output reg      rst_sync_n
);

reg ff1;

always @(posedge clk or negedge rst_async_n) begin
    if(!rst_async_n) begin
        ff1 <= 0;
        rst_sync_n <= 0;
    end
    else begin
        ff1 <= 1;
        rst_sync_n <= ff1;
    end
end

endmodule

`default_nettype wire
