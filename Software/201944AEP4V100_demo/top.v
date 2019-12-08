//`define __LED_FLOW__

module top(
    /*  clock and reset_n  */
    input   wire        clk_50m,
    input   wire        reset_n,
    /*  LED  */
    output  wire [5:0]  led,
    /*  UART  */
    output  wire        uart_tx_path,   // to CH340 RXD
    input   wire        uart_rx_path    // to CH340 TXD
);

    /*  Timer  */
    wire [15:0] timer_second;
    wire        timer_pps;
    /*  UART  */
    reg [7:0]   uart_tx_data = 8'b0;
    reg         uart_tx_enable = 1'b0;
    wire [7:0]  uart_rx_data;
    wire        uart_rx_done;
    /*  UART Control Bit  */
    reg [5:0]   led_bit_reg = 6'b000000;
    assign led = led_bit_reg;
    
    
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
        .reset_n        (   reset_n         ),
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
        
    /*  UART_RX  */
    uart_rx_path u_uart_rx_path(
        .clk_in         (   clk_50m         ),
        .uart_rx_path   (   uart_rx_path    ),
        .uart_rx_data   (   uart_rx_data    ),
        .uart_rx_done   (   uart_rx_done    )
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
    
    /*  Receive byte to control led  */
    always@(posedge uart_rx_done or negedge reset_n)
    begin
        if(!reset_n)
        begin
            led_bit_reg = 6'b000000;
        end
        else
        begin
            case(uart_rx_data)
                6'h00:  led_bit_reg[0] = ~led_bit_reg[0];
                6'h01:  led_bit_reg[1] = ~led_bit_reg[1];
                6'h02:  led_bit_reg[2] = ~led_bit_reg[2];
                6'h03:  led_bit_reg[3] = ~led_bit_reg[3];
                6'h04:  led_bit_reg[4] = ~led_bit_reg[4];
                6'h05:  led_bit_reg[5] = ~led_bit_reg[5];
                default: ;
            endcase
        end
    end
    
endmodule