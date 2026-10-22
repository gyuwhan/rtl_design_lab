`default_nettype none

module sync_fifo #(
    parameter DEPTH = 8, WIDTH = 10
)(
    input   wire                clk,
    input   wire                rst_n,
    input   wire    [WIDTH-1:0] wr_data,
    input   wire                rd_en,
    input   wire                wr_en,

    output  reg     [WIDTH-1:0] rd_data,
    output  wire                empty,
    output  wire                full           
);

localparam PTR = $clog2(DEPTH) + 1;

reg [PTR-1:0] wr_ptr, rd_ptr;
reg [WIDTH-1:0] mem [0:DEPTH-1];

wire wr_accept = (!full) && (wr_en);
wire rd_accept = (!empty) && (rd_en);

assign empty = wr_ptr == rd_ptr;
assign full = (wr_ptr[PTR-1] != rd_ptr[PTR-1]) && (wr_ptr[PTR-2:0] == rd_ptr[PTR-2:0]);

always @(posedge clk) begin
    if(!rst_n) wr_ptr <={PTR{1'd0}};
    else if(wr_accept) wr_ptr <= wr_ptr + {{(PTR-1){1'd0}},1'd1};
end

always @(posedge clk) begin
    if(!rst_n) rd_ptr <= {PTR{1'd0}};
    else if(rd_accept) rd_ptr <= rd_ptr + {{(PTR-1){1'd0}},1'd1};
end


always @(posedge clk) begin
    if(wr_accept) mem[wr_ptr[PTR-2:0]] <= wr_data;
end

always @(posedge clk) begin
    if(!rst_n) rd_data <= {WIDTH{1'd0}};
    else if(rd_accept) rd_data <= mem[rd_ptr[PTR-2:0]];
end


endmodule

`default_nettype wire
