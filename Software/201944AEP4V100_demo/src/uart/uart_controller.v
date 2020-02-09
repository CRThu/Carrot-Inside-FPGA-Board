module uart_controller(
    input wire          uart_clk_in,
    
	input wire  [7:0]   uart_tx_data,
	input wire          uart_tx_enable,
    
	output wire [7:0]   uart_rx_data,
	output wire         uart_rx_done,
    
	output wire         uart_tx_path,
	input wire          uart_rx_path
);
    
    /*  UART_TX  */
    uart_tx_path u_uart_tx_path(
        .clk_in         (uart_clk_in),
        .uart_tx_data   (uart_tx_data),
        .uart_tx_enable (uart_tx_enable),
        .uart_tx_path   (uart_tx_path)
    );
        
    /*  UART_RX  */
    uart_rx_path u_uart_rx_path(
        .clk_in         (uart_clk_in),
        .uart_rx_path   (uart_rx_path),
        .uart_rx_data   (uart_rx_data),
        .uart_rx_done   (uart_rx_done)
    );

endmodule 