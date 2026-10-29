`default_nettype none
`timescale 1ns/1ps

module tb_sync_fifo_rand;


localparam WIDTH = 10,
            DEPTH = 4,
            CYCLES = 1000;


reg                         clk;
reg                         rst_n;
reg                         rd_en;
reg                         wr_en;
reg     [WIDTH-1:0]         wr_data;

wire                        full_msb;
wire                        empty_msb;
wire    [WIDTH-1:0]         rd_data_msb;  

reg     [WIDTH-1:0]         ref_q[0:DEPTH-1];
reg     [$clog2(DEPTH):0]   ref_cnt;
reg     [WIDTH-1:0]         rd_data_ref;  

integer i, j, cycle, err, seed, cnt_full, cnt_empty;

wire full_ref = ref_cnt == DEPTH;
wire empty_ref = ref_cnt == 0;

wire wr_accept_ref = (!full_ref) && (wr_en);
wire rd_accept_ref = (!empty_ref) && (rd_en);

task reset_fifo;
    begin
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
    end
endtask

sync_fifo #(
    .DEPTH(DEPTH), .WIDTH(WIDTH)
) fifo_msb(
    .clk(clk),
    .rst_n(rst_n),
    .wr_data(wr_data),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .empty(empty_msb),
    .full(full_msb),           
    .rd_data(rd_data_msb)
);

always @(posedge clk) begin
    if(!rst_n) cycle <= 0;
    else cycle <= cycle + 1;
end

always @(posedge clk) begin
    if(!rst_n)ref_cnt <= 0;
    else if(wr_accept_ref && rd_accept_ref) ref_cnt <= ref_cnt;
    else if(wr_accept_ref) ref_cnt <= ref_cnt + 1;
    else if(rd_accept_ref) ref_cnt <= ref_cnt - 1;
end

always @(posedge clk) begin
    if(!rst_n) rd_data_ref <= 0;
    else if(rd_accept_ref) begin
        rd_data_ref <= ref_q[0];
        for(i=0;i<DEPTH-1;i=i+1) begin
            ref_q[i] <= ref_q[i+1];
        end
        if(wr_accept_ref) begin
            ref_q[ref_cnt-1] <= wr_data;
        end
    end
    else if(wr_accept_ref) ref_q[ref_cnt] <= wr_data;
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("sim/sync_fifo_rand.vcd");
    $dumpvars(0, tb_sync_fifo_rand);
end

initial begin

    seed = 1;

    reset_fifo;
    err = 0;
    cycle = 0;
    cnt_full = 0;
    cnt_empty = 0;

    for(j=0;j<CYCLES;j=j+1) begin
        @(negedge clk);
        if(full_msb !== full_ref) begin
            err = err + 1;
            $display("[%0d] Error: msb full=%b ref full=%b", cycle, full_msb, full_ref);
        end
        if(empty_msb !== empty_ref) begin
            err = err + 1;
            $display("[%0d] Error: msb empty=%b ref empty=%b", cycle, empty_msb, empty_ref);            
        end
        if(rd_data_ref !== rd_data_msb) begin
            err = err + 1;
            $display("[%0d] Error: msb read data=%h ref read data=%h", cycle, rd_data_msb, rd_data_ref);                       
        end
        if(full_ref) cnt_full = cnt_full + 1;
        if(empty_ref) cnt_empty = cnt_empty + 1;

        wr_en = ({$random(seed)} % 100) < 55;
        rd_en = ({$random(seed)} % 100) < 50;
        wr_data = $random(seed); 
        //$display("[%0d] msb full=%b empty=%b ref full=%b empty=%b wr_en=%d rd_en=%d wr_data=%h", cycle, full_msb,empty_msb, full_ref,empty_ref,wr_en,rd_en,wr_data);
        //if(cycle >= 13) $display("[%0d] msb full=%b empty=%b ref full=%b empty=%b wr_en=%d rd_en=%d wr_data=%h", cycle, full_msb,empty_msb, full_ref,empty_ref,wr_en,rd_en,wr_data);
    end
    
    if(err !== 0) $display("FAIL : cycles=%0d, err=%0d",cycle, err);
    else $display("PASS : cycles=%0d, err=%0d",cycle, err);
    if(cnt_full !== 0 && cnt_empty !== 0) begin
        $display("TOTAL : full=%0d empty=%0d", cnt_full, cnt_empty);        
    end
    else $display("Not enough cycle : full=%0d empty=%0d", cnt_full, cnt_empty);

    #100;
    $finish;
end

endmodule

`default_nettype wire
