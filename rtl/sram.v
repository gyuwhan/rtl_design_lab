`default_nettype none

module sram #( parameter WIDTH = 10,
    parameter DEPTH = 256,
    parameter ADDR = $clog2(DEPTH)
)(
    input wire clk,
    input wire csn,
    input wire wen,
    input wire [ADDR-1:0] addr,
    input wire [WIDTH-1:0] wdata,
    
    output wire [WIDTH-1:0] rdata
);

reg [WIDTH-1:0] mem[0:DEPTH-1];
reg [ADDR-1:0] r_addr;

always@(posedge clk) begin
    if(!csn) begin
        if(!wen) begin
            mem[addr] <= wdata;
        end
        r_addr <= addr;
    end
end

assign rdata = mem[r_addr];

endmodule

`default_nettype wire
