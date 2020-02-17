module uart_test
#(
    parameter CLK_FREQ = 32'd50_000_000
)
(
    input wire          clk_50m,
    input wire          reset_n,
    
	output reg  [7:0]   uart_tx_data,
	output wire         uart_tx_enable,
    
	input wire  [7:0]   uart_rx_data,
	input wire          uart_rx_done,
    
    output reg  [5:0]   led
);

    /*  Timer  */
    wire    [15:0]  timer_second;
    wire            timer_pps;
    
    /*  Timer  */
    timer
    #(
        .CLK_FREQ       (CLK_FREQ),
        .PPS_WIDTH      (32'd10)
    )
    u_timer
    (
        .clk_50m        (clk_50m),
        .reset_n        (reset_n),
        
        .second         (timer_second),
        .pps            (timer_pps)
    );
    
    /*  Send second to uart  */
    assign uart_tx_enable = timer_pps;
    
    always@(posedge timer_pps or negedge reset_n)
    begin
        if(!reset_n)
            uart_tx_data <= 8'b0;
        else
            uart_tx_data <= timer_second[7:0];
    end
    
    /*  Receive byte to control led  */
    /*  UART Control Bit  */
    always@(posedge clk_50m or negedge reset_n)
    begin
        if(!reset_n)
            led <= 6'b0;
        else if(uart_rx_done)
        begin
            case(uart_rx_data)
                6'h00:  led <= led ^ (6'b1 << 0);
                6'h01:  led <= led ^ (6'b1 << 1);
                6'h02:  led <= led ^ (6'b1 << 2);
                6'h03:  led <= led ^ (6'b1 << 3);
                6'h04:  led <= led ^ (6'b1 << 4);
                6'h05:  led <= led ^ (6'b1 << 5);
                default: led <= led;
            endcase
        end
        else
            led <= led;
    end
endmodule 