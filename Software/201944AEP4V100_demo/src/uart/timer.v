module timer
#(
    parameter CLK_FREQ = 32'd50_000_000
)
(
    input wire          clk_50m,
    input wire          reset_n,
        
    output reg [15:0]   second,     // second
    output reg          pps         // PPS
);

    reg [31:0] clk_cnt;
        
    always@(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            clk_cnt <= 32'd0;
            second <= 16'd0;
            pps <= 1'b0;
        end
        else if(clk_cnt >= CLK_FREQ)
        begin
            clk_cnt <= 32'd0;
            second <= second + 16'd1;
            pps <= 1'b1;
        end
        else
        begin
            clk_cnt <= clk_cnt + 32'd1;
            second <= second;
            pps <= 1'b0;
        end
    end
    
endmodule
