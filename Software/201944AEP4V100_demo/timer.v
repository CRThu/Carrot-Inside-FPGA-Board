//`define __SIM_CLK_DIV__

`ifdef __SIM_CLK_DIV__
    `define CLK_DIV 32'd5_000
`else
    `define CLK_DIV 32'd50_000_000
`endif

module timer(
	input clk_50m,
    input reset_n,
	output reg [15:0]   second = 16'd0, // second
    output reg          pps = 1'b0      // PPS
    );
    
    
    reg [31:0] clk_cnt = 32'd0;
        
    always@(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
        begin
            clk_cnt = 32'd0;
            second = 16'd0;
            pps = 1'b0;
        end
        else
        begin
            clk_cnt <= clk_cnt + 32'd1;
            pps <= 1'b0;
            if(clk_cnt == `CLK_DIV)
            begin
                clk_cnt <= 32'd0;
                second <= second + 16'd1;
                pps <= 1'b1;
            end
        end
    end
    
endmodule
