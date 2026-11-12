`default_nettype none
`timescale 1ns/1ps

module hs_sync #(
    parameter WIDTH = 8
    )(
        input wire              clk_src,
        input wire              rst_src_n,
        input wire [WIDTH-1:0]  data_in,
        input wire              send,

        input wire              clk_dst,
        input wire              rst_dst_n,

        output reg [WIDTH-1:0]  data_out,
        output reg              busy,
        output reg              valid_dst
);

reg ack, req;
wire ack_sync, req_sync;
reg [WIDTH-1:0] data_hold;

sync_2ff u_req_sync(
    .clk(clk_dst),
    .rst_n(rst_dst_n),
    .d_async(req),
    .q_sync(req_sync)
);

sync_2ff u_ack_sync(
    .clk(clk_src),
    .rst_n(rst_src_n),
    .d_async(ack),
    .q_sync(ack_sync)
);

always @(posedge clk_src) begin
    if(!rst_src_n) begin 
        data_hold <= {WIDTH{1'b0}};
        req <= 1'b0;
        busy <= 1'b0;
    end
    else if(!busy && send) begin
        data_hold <= data_in;
        busy <= 1'b1;
        req <= 1'b1;
    end
    else if(req && ack_sync) begin
        req <= 1'b0;
    end
    else if(busy && !ack_sync && !req) begin
        busy <= 1'b0;
    end
end

always @(posedge clk_dst) begin

    if(!rst_dst_n) begin
        data_out <= {WIDTH{1'b0}};
        valid_dst <= 1'b0;
        ack <= 1'b0;
    end
    else begin
        valid_dst <= 1'b0;
        if(req_sync && !ack) begin
            data_out <= data_hold;
            valid_dst <= 1'b1;
            ack <= 1'b1;
        end
        else if(!req_sync && ack) begin
            ack <= 1'b0;
            valid_dst <= 1'b0;
        end
    end
end

endmodule

`default_nettype wire
