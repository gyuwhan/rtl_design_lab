`default_nettype none
`timescale 1ns/1ps

module reset_sync(
    input wire      clk,
    input wire      rst_async_n,

    output wire     rst_sync_n
);

(* ASYNC_REG = "TRUE" *) reg ff1;
(* ASYNC_REG = "TRUE" *) reg ff2;

always @(posedge clk or negedge rst_async_n) begin
    if(!rst_async_n) begin
        ff1 <= 0;
        ff2 <= 0;
    end
    else begin
        ff1 <= 1;
        ff2 <= ff1;
    end
end

assign rst_sync_n = ff2;

endmodule

`default_nettype wire
