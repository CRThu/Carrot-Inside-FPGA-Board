//`define __LED_FLOW__

module top(
    /*  clock and reset_n  */
    input   wire        clk_50m,
    input   wire        reset_n,
    /*  LED  */
    output  wire [5:0]  led,
    /*  UART  */
    output  wire        uart_tx_path
);

    /*  Timer  */
    wire [15:0] timer_second;
    wire        timer_pps;
    /*  UART  */
    reg [7:0]   uart_tx_data = 8'b0;
    reg         uart_tx_enable = 1'b0;
    
    
    /*  Instance  */
    /*  LED Flow  */
    `ifdef __LED_FLOW__
        led u_led(
            .clk_50m        (   clk_50m         ),
            .reset_n        (   reset_n         ),
            .led            (   led             )
            );
    `endif
    
    /*  Timer  */
    timer u_timer(
        .clk_50m        (   clk_50m         ),
        .second         (   timer_second    ),
        .pps            (   timer_pps       )
    );
    
    /*  UART_TX  */
    uart_tx_path u_uart_tx_path(
        .clk_in         (   clk_50m         ),
        .uart_tx_data   (   uart_tx_data    ),
        .uart_tx_enable (   uart_tx_enable  ),
        .uart_tx_path   (   uart_tx_path    )
        );
    
    /*  Send second to uart  */
    always@(timer_pps)
    begin
        if(timer_pps)
        begin
            uart_tx_data <= timer_second[7:0];
            uart_tx_enable <= 1'b1;
        end
        else
            uart_tx_enable <= 1'b0;
    end
    
endmodule