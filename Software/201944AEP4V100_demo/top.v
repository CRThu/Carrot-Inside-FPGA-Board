module top(
    input wire clk_50m,
    input wire reset,
    output wire [5:0] led
);

    /*  LED  */
    led u_led(
        .clk_50m    (   clk_50m ),
        .reset      (   reset   ),
        .led        (   led     )
        );
    
    // TODO
    
    
    
endmodule