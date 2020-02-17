module uart_tx_path
#(
    parameter CLK_FREQ  = 32'd50_000_000,
    parameter UART_BAUD = 32'd115200
)
(
	input wire          uart_tx_clk,
    input wire          reset_n,
    
	input wire  [7:0]   uart_tx_data,
	input wire          uart_tx_enable,
    output wire         uart_tx_busy,
	
	output reg          uart_tx_path
);

    parameter [31:0] BAUD_RATE_CNT = CLK_FREQ / UART_BAUD;
    
    
    reg uart_tx_enable_delay0;
    reg uart_tx_enable_delay1;
    wire uart_tx_enable_flag = (~uart_tx_enable_delay1) & uart_tx_enable_delay0;    // tx enable posedge
    
    reg [31:0]  baud_rate_counter;      // baud rate counter
    reg         uart_send_flag;         // data send flag
    reg [3:0]   bit_send_status;        // bit send status
    reg [7:0]   send_byte;              // send byte
    
    assign uart_tx_busy = uart_send_flag;
    
    always@(posedge uart_tx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_tx_enable_delay0 <= 1'b0;
            uart_tx_enable_delay1 <= 1'b0;
        end
        else
        begin
            uart_tx_enable_delay0 <= uart_tx_enable;
            uart_tx_enable_delay1 <= uart_tx_enable_delay0;
        end
    end
    
    // generate bit_send_status for sending bit signal
    always@(posedge uart_tx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            bit_send_status <= 4'd0;
            baud_rate_counter <= 32'd0;
        end
        else if(uart_send_flag)
        begin
            if(baud_rate_counter < BAUD_RATE_CNT - 1'd1)    // end and wait for next byte
            begin
                bit_send_status <= bit_send_status;
                baud_rate_counter <= baud_rate_counter + 1'd1;
            end
            else
            begin
                bit_send_status <= bit_send_status + 1'd1;
                baud_rate_counter <= 32'd0;
            end
        end
        else
        begin
            bit_send_status <= 4'd0;
            baud_rate_counter <= 32'd0;
        end
    end
    
    // uart_tx_data to send_byte register
    always@(posedge uart_tx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_send_flag <= 1'b0;
            send_byte <= 8'b0;
        end
        else if(uart_tx_enable_flag)
        begin
            uart_send_flag <= 1'b1;
            send_byte <= uart_tx_data;
        end
        else if((bit_send_status == 4'd9) && (baud_rate_counter == (BAUD_RATE_CNT - 3'd4))) // end and wait for next byte
        begin
            uart_send_flag <= 1'b0;
            send_byte <= 8'b0;
        end
        else
        begin
            uart_send_flag <= uart_send_flag;
            send_byte <= send_byte;
        end
    end
    
    // send bit and move bit_cursor
    always@(posedge uart_tx_clk or negedge reset_n)
    begin
        if(!reset_n)
        begin
            uart_tx_path <= 1'b1;
        end
        else if(uart_send_flag)	// wait for send flag
        begin
            case(bit_send_status)
                4'd0: uart_tx_path <= 1'b0;
                4'd1: uart_tx_path <= send_byte[0];
                4'd2: uart_tx_path <= send_byte[1];
                4'd3: uart_tx_path <= send_byte[2];
                4'd4: uart_tx_path <= send_byte[3];
                4'd5: uart_tx_path <= send_byte[4];
                4'd6: uart_tx_path <= send_byte[5];
                4'd7: uart_tx_path <= send_byte[6];
                4'd8: uart_tx_path <= send_byte[7];
                4'd9: uart_tx_path <= 1'b1;
                default: ;
            endcase
        end
        else
        begin
            uart_tx_path <= 1'b1;	// when available, send high
        end
    end
endmodule
