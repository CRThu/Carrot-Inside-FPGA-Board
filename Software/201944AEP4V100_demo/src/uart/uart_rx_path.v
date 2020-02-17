module uart_rx_path
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
    input wire          uart_rx_clk,
    input wire          reset_n,
        
    output reg  [7:0]   uart_rx_data,
    output reg          uart_rx_done,
        
    input wire          uart_rx_path
);
    
    parameter [31:0] BAUD_RATE_CNT = CLK_FREQ / UART_BAUD;
    
    reg uart_rx_path_delay0;
    reg uart_rx_path_delay1;
    wire uart_rx_start_flag = uart_rx_path_delay1 & (~uart_rx_path_delay0);
    
    reg [31:0]  baud_rate_counter;      // baud rate counter
    reg         uart_recv_flag;         // data recv flag
    reg [3:0]   bit_recv_status;        // bit recv status
    reg [7:0]   recv_byte;              // recv byte
    
    
    always@(posedge uart_rx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_rx_path_delay0 <= 1'b0;
            uart_rx_path_delay1 <= 1'b0;
        end
        else
        begin
            uart_rx_path_delay0 <= uart_rx_path;
            uart_rx_path_delay1 <= uart_rx_path_delay0;
        end
    end
    
    // generate uart_recv_flag signal
    always@(posedge uart_rx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_recv_flag <= 1'b0;
        end
        else
        begin
            if(uart_rx_start_flag)
            begin
                uart_recv_flag <= 1'b1;
            end
            else if((bit_recv_status == 4'd9) && (baud_rate_counter == BAUD_RATE_CNT/2)) // end and wait for next byte
            begin
                uart_recv_flag <= 1'b0;
            end
            else
            begin
                uart_recv_flag <= uart_recv_flag;
            end
        end
    end
    
    // generate bit_recv_status for receiving bit signal
    always@(posedge uart_rx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            baud_rate_counter <= 32'd0;
            bit_recv_status <= 4'd0;
        end
        else if(uart_recv_flag)
        begin
            if(baud_rate_counter < BAUD_RATE_CNT - 1'd1)
            begin
                baud_rate_counter <= baud_rate_counter + 1'd1;
                bit_recv_status <= bit_recv_status;
            end
            else
            begin
                baud_rate_counter <= 32'd0;
                bit_recv_status <= bit_recv_status + 1'd1;
            end
        end
        else
        begin
            baud_rate_counter <= 32'd0;
            bit_recv_status <= 4'd0;
        end
    end
    
    // recv_byte
    always@(posedge uart_rx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            recv_byte <= 8'b0;
        end
        else if(uart_recv_flag)
        begin
            if(baud_rate_counter == BAUD_RATE_CNT/2)
            begin
                case(bit_recv_status)
                    4'd1:   recv_byte[0] <= uart_rx_path;
                    4'd2:   recv_byte[1] <= uart_rx_path;
                    4'd3:   recv_byte[2] <= uart_rx_path;
                    4'd4:   recv_byte[3] <= uart_rx_path;
                    4'd5:   recv_byte[4] <= uart_rx_path;
                    4'd6:   recv_byte[5] <= uart_rx_path;
                    4'd7:   recv_byte[6] <= uart_rx_path;
                    4'd8:   recv_byte[7] <= uart_rx_path;
                    default:;
                endcase
            end
            else
            begin
                recv_byte <= recv_byte;
            end
        end
        else
            recv_byte <= 8'd0;
    end
    
    // uart_rx_data uart_rx_done
    always@(posedge uart_rx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_rx_data <= 8'b0;
            uart_rx_done <= 1'b0;
        end
        else if(bit_recv_status == 4'd9)
        begin
            uart_rx_data <= recv_byte;
            uart_rx_done <= 1'b1;
        end
        else
        begin
            uart_rx_data <= 8'b0;
            uart_rx_done <= 1'b0;
        end
    end
endmodule
