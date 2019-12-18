`timescale 100us/100us
// use __SIM_CLK_DIV__ in timer when simulation

module top_tb;

    reg         clk_50m = 1'b0;
    reg         reset_n = 1'b1;
    wire [5:0]  led;
    wire        uart_tx_path;
    wire        uart_rx_path;
    
    assign uart_rx_path = uart_tx_path;
    

    top u_top(
        .clk_in         (   clk_50m         ),
        .reset_n        (   reset_n         ),
        .led            (   led             ),
        .uart_tx_path   (   uart_tx_path    ),
        .uart_rx_path   (   uart_rx_path    )
    );
    
    
    always
        #1 clk_50m = ~clk_50m;
        
    initial
    begin
        #25000 reset_n = 1'b0;
        #5000 reset_n = 1'b1;
        #70000 $stop;
    end

endmodule