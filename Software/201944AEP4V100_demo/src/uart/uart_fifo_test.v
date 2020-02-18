module uart_fifo_test
#(
    parameter CLK_FREQ = 32'd50_000_000
)
(
    input wire          clk_50m,
    input wire          reset_n,
    
    output wire         uart_tx_fifo_clk,
    output reg          uart_tx_fifo_req,
    output reg [7:0]    uart_tx_fifo_data,
    
    output reg  [5:0]   led
);

    /*  Timer  */
    wire    [15:0]  timer_second;
    wire            timer_pps;
    
    /*  UART TX  */
    reg             pps_delay0;
    reg             pps_delay1;
    wire            pps_recv_flag = pps_delay0 & (~pps_delay1);
    reg             fifo_write_flag;
    
    reg     [2:0]   fsm_state;
    
    assign uart_tx_fifo_clk = clk_50m;
    
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
    
    always@(posedge uart_tx_fifo_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            pps_delay0 <= 1'd0;
            pps_delay1 <= 1'd0;
        end
        else
        begin
            pps_delay0 <= timer_pps;
            pps_delay1 <= pps_delay0;
        end
    end
    
    always@(posedge uart_tx_fifo_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            fifo_write_flag <= 1'd0;
        end
        else
        begin
            if(pps_recv_flag)
                fifo_write_flag <= 1'd1;
            else if(fsm_state == 3'd4)
                fifo_write_flag <= 1'd0;
            else
                fifo_write_flag <= fifo_write_flag;
        end
    end
    
    always@(posedge uart_tx_fifo_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_tx_fifo_req <= 1'b0;
            uart_tx_fifo_data <= 8'b0;
            fsm_state <= 3'd0;
        end
        else if(fifo_write_flag)
        begin
            case(fsm_state)
                3'd0:
                begin
                    uart_tx_fifo_req <= 1'b1;
                    uart_tx_fifo_data <= timer_second[15:8];
                    fsm_state <= fsm_state + 1'b1;
                end
                3'd1:
                begin
                    uart_tx_fifo_req <= 1'b0;
                    uart_tx_fifo_data <= uart_tx_fifo_data;
                    fsm_state <= fsm_state + 1'b1;
                end
                3'd2:
                begin
                    uart_tx_fifo_req <= 1'b1;
                    uart_tx_fifo_data <= timer_second[7:0];
                    fsm_state <= fsm_state + 1'b1;
                end
                3'd3:
                begin
                    uart_tx_fifo_req <= 1'b0;
                    uart_tx_fifo_data <= uart_tx_fifo_data;
                    fsm_state <= fsm_state + 1'b1;
                end
                3'd4:
                begin
                    uart_tx_fifo_req <= uart_tx_fifo_req;
                    uart_tx_fifo_data <= uart_tx_fifo_data;
                    fsm_state <= 3'd0;
                end
                
                default:;
            endcase
        end
        else
        begin
            uart_tx_fifo_req <= 1'b0;
            uart_tx_fifo_data <= 8'b0;
            fsm_state <= 3'd0;
        end
    end
    
endmodule 