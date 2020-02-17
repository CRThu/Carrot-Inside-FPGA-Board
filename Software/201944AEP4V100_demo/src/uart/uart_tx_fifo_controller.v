module uart_tx_fifo_controller
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
    input wire          reset_n,
    
    // FIFO TX
    input wire          fifo_tx_clk,
    input wire          fifo_tx_req,
    input wire [7:0]    fifo_tx_data,
    output wire         fifo_full,
    
    input wire          uart_tx_clk,
    
    // UART interface
	output wire         uart_tx_path
);

	wire [7:0]      uart_tx_data;
    
    reg             fifo_rd_req;
    wire            fifo_empty;
    
	reg             uart_tx_enable;
    wire            uart_tx_busy;
    
    reg [1:0]       fsm_state;
    
    uart_tx_path
    #(
        .CLK_FREQ       (CLK_FREQ),
        .UART_BAUD      (UART_BAUD)
    )
    u_uart_tx_path
    (
        .uart_tx_clk    (uart_tx_clk),
        .reset_n        (reset_n),
        .uart_tx_data   (uart_tx_data),
        .uart_tx_enable (uart_tx_enable),
        .uart_tx_busy   (uart_tx_busy),
        .uart_tx_path   (uart_tx_path)
    );
    
    uart_tx_fifo u_uart_tx_fifo(
        .aclr       (~reset_n),
        
        .wrclk      (fifo_tx_clk),
        .wrreq      (fifo_tx_req),
        .data       (fifo_tx_data),
        .wrfull     (fifo_full),
        
        .rdclk      (uart_tx_clk),
        .rdreq      (fifo_rd_req),
        .q          (uart_tx_data),
        .rdempty    (fifo_empty)
	);
    
    always@(posedge uart_tx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            fsm_state = 2'b0;
            fifo_rd_req <= 1'b0;
            uart_tx_enable <= 1'b0;
        end
        else
        begin
            case(fsm_state)
                2'd0:   // IDLE
                begin
                    fifo_rd_req <= 1'b0;
                    uart_tx_enable <= 1'b0;
                    if(fifo_empty == 1'b0 && uart_tx_busy == 1'b0)
                        fsm_state <= fsm_state + 1'b1;
                    else
                        fsm_state <= fsm_state;
                end
                2'd1:   // SEND BYTE TO UART_TX_PATH
                begin
                    fifo_rd_req <= 1'b1;
                    uart_tx_enable <= 1'b1;
                    fsm_state <= fsm_state + 1'b1;
                end
                2'd2:   // HOLD ENABLE
                begin
                    fifo_rd_req <= 1'b0;
                    uart_tx_enable <= 1'b1;
                    fsm_state <= fsm_state + 1'b1;
                end
                2'd3:   // WAIT
                begin
                    fifo_rd_req <= 1'b0;
                    uart_tx_enable <= 1'b0;
                    if(uart_tx_busy == 1'b0)
                        fsm_state <= 2'b0;
                    else
                        fsm_state <= fsm_state;
                end
            endcase
        end
    end
    
endmodule