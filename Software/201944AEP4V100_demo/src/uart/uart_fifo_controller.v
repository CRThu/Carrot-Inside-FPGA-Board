module uart_fifo_controller
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
    input wire          uart_clk,
    input wire          reset_n,
    
    // UART TX FIFO
    input wire          uart_tx_fifo_clk,
	input wire          uart_tx_fifo_req,
	input wire  [7:0]   uart_tx_fifo_data,
    output wire         uart_tx_fifo_full,
    
    // Interface
	output wire         uart_tx_path
    
    //TODO
	//output wire [7:0]   uart_rx_data,
	//output wire         uart_rx_done,
    
	//input wire          uart_rx_path
);
    
    /*  UART_TX  */
    uart_tx_fifo_controller
    #(
        .CLK_FREQ       (CLK_FREQ),
        .UART_BAUD      (UART_BAUD)
    )
    u_uart_tx_fifo_controller(
        .reset_n        (reset_n),
        
        .fifo_tx_clk    (uart_tx_fifo_clk),
        .fifo_tx_req    (uart_tx_fifo_req),
        .fifo_tx_data   (uart_tx_fifo_data),
        .fifo_full      (uart_tx_fifo_full),
        
        .uart_tx_clk    (uart_clk),
        
        .uart_tx_path   (uart_tx_path)
    );
        
    /*  UART_RX  */
    /*
    uart_rx_path
    #(
        .CLK_FREQ       (CLK_FREQ),
        .UART_BAUD      (UART_BAUD)
    )
    u_uart_rx_path
    (
        .uart_rx_clk    (uart_clk_in),
        .reset_n        (reset_n),
        .uart_rx_path   (uart_rx_path),
        .uart_rx_data   (uart_rx_data),
        .uart_rx_done   (uart_rx_done)
    );
    */

endmodule 